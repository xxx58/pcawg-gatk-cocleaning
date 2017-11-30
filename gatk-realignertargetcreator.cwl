cwlVersion: v1.0
class: CommandLineTool
label: GATK RealignerTargetCreator

hints:
  - class: ResourceRequirement
    coresMin: 8
    ramMin: 32

requirements: 
  - class: DockerRequirement
    dockerPull: "quay.io/junjun_zhang/pcawg-gatk-cocleaning:0.1.1"

baseCommand:
  - "java"
  - "-jar"
  - "/opt/GenomeAnalysisTK.jar"
  - "-T"
  - "RealignerTargetCreator"
  - "--disable_auto_index_creation_and_locking_when_reading_rods"

arguments:
  - valueFrom: forIndelRealigner.intervals
    prefix: -o 

  - valueFrom: $(runtime.cores)
    prefix: -nt

inputs:
  input_bam:
    type:
      - type: array
        items: File
        inputBinding:
          prefix: -I
    inputBinding:
      position: 1
    secondaryFiles:
      - .bai
    doc: one or more coordinate sorted and indexed BAM files

  reference:
    type: File
    inputBinding:
      prefix: -R
    doc: human reference sequence along with the secondary files.
    secondaryFiles:
      - .fai
      - ^.dict

  maxIntervalSize:
    type: int?
    inputBinding:
      prefix: --maxIntervalSize
    doc: maximum interval size; any intervals larger than this value will be dropped.
      optional paramter

  minReadsAtLocus:
    type: int?
    inputBinding:
      prefix: --minReadsAtLocus
      position: 2
    doc: minimum reads at a locus to enable using the entropy calculation

  windowSize:
    type: int?
    inputBinding:
      prefix: --windowSize
    doc: window size for calculating entropy or SNP clusters

  mismatchFraction:
    type: float?
    inputBinding:
      prefix: --mismatchFraction
    doc: fraction of base qualities needing to mismatch for a position to have high
      entropy

  knownIndels:
    type:
    - "null"
    - type: array
      items: File
      inputBinding:
        prefix: --known
    inputBinding:
      position: 1
    secondaryFiles:
      - .tbi
    doc: Any number of VCF files representing known SNPs and/or indels. Could be e.g.
      dbSNP and/or official 1000 Genomes indel calls. SNPs in these files will be
      ignored unless the --mismatchFraction argument is used. optional parameter.

outputs:
  target_intervals:
    type: File
    outputBinding:
      glob: forIndelRealigner.intervals
    secondaryFiles:
      - .bai

