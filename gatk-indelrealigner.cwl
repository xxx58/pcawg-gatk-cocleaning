cwlVersion: v1.0
class: CommandLineTool
label: GATK IndelRealigner

hints:
  - class: ResourceRequirement
    coresMin: 8
    ramMin: 32

requirements: 
  - class: DockerRequirement
    dockerPull: cuhkhaosun/workflow-pancancer:gatk-cocleaning-latest

baseCommand:
  - "java"
  - "-jar"
  - "/opt/GenomeAnalysisTK.jar"
  - "-T"
  - "IndelRealigner"
  - "--disable_auto_index_creation_and_locking_when_reading_rods"

arguments:
  - valueFrom: .realigned.bam
    prefix: -nWayOut

inputs:
  tumor_bam:
    type: File
    inputBinding:
      prefix: -I
    doc: bam file produced after markDups execution
    secondaryFiles:
      - .bai

  normal_bam:
    type: File?
    inputBinding:
      prefix: -I
    doc: bam file produced after markDups execution
    secondaryFiles:
      - .bai

  knownIndels:
    type:
    - "null"
    - type: array
      items: File
      inputBinding:
        prefix: --knownAlleles
    inputBinding:
      position: 1
    secondaryFiles:
      - .tbi
    doc: Any number of VCF files representing known SNPs and/or indels. Could be e.g.
      dbSNP and/or official 1000 Genomes indel calls. SNPs in these files will be
      ignored unless the --mismatchFraction argument is used. optional parameter.

  reference:
    type: File
    inputBinding:
      prefix: -R
    secondaryFiles:
      - .fai
      - ^.dict

  intervals:
    type: File
    inputBinding:
      prefix: --targetIntervals
    doc: list of intervals created by realignerTargetCreataor

  maxReadsForConsensuses:
    type: int?
    inputBinding:
      prefix: --maxReadsForConsensuses
    doc: Max reads used for finding the alternate consensuses (necessary to improve
      performance in deep coverage)

  LODThresholdForCleaning:
    type: double?
    inputBinding:
      prefix: --LODThresholdForCleaning
    doc: LOD threshold above which the cleaner will clean

  maxConsensuses:
    type: int?
    inputBinding:
      prefix: --maxConsensuses
    doc: Max alternate consensuses to try (necessary to improve performance in deep
      coverage)

  maxReadsInMemory:
    type: int?
    inputBinding:
      prefix: --maxReadsInMemory
    doc: max reads allowed to be kept in memory at a time by the SAMFileWriter

  maxIsizeForMovement:
    type: int?
    inputBinding:
      prefix: --maxIsizeForMovement
    doc: maximum insert size of read pairs that we attempt to realign. For expert
      users only!

  maxPositionalMoveAllowed:
    type: int?
    inputBinding:
      prefix: --maxPositionalMoveAllowed
    doc: Maximum positional move in basepairs that a read can be adjusted during realignment.
      For expert users only!

  entropyThreshold:
    type: double?
    inputBinding:
      prefix: --entropyThreshold
    doc: Percentage of mismatches at a locus to be considered having high entropy
      (0.0 < entropy <= 1.0)

  maxReadsForRealignment:
    type: int?
    inputBinding:
      prefix: --maxReadsForRealignment
    doc: Max reads allowed at an interval for realignment

  consensusDeterminationModel:
    type: string?
    inputBinding:
      prefix: --consensusDeterminationModel
    doc: Percentage of mismatches at a locus to be considered having high entropy
      (0.0 < entropy <= 1.0)

  noOriginalAlignmentTags:
    type: boolean?
    inputBinding:
      prefix: --noOriginalAlignmentTags
    doc: Dont output the original cigar or alignment start tags for each realigned
      read in the output bam

outputs:
  tumor_realigned:
    type: File
    outputBinding:
      glob: $(inputs.tumor_bam.nameroot).realigned.bam
    secondaryFiles:
      - ^.bai

  normal_realigned:
    type: File
    outputBinding:
      glob: $(inputs.normal_bam.nameroot).realigned.bam
    secondaryFiles:
      - ^.bai
