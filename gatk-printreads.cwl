class: CommandLineTool
cwlVersion: v1.0
label: GATK PrintReads
doc: |
  GATK-RealignTargetCreator.cwl is developed for CWL consortium
  Prints all reads that have a mapping quality above zero
    Usage: java -Xmx4g -jar GenomeAnalysisTK.jar -T PrintReads -R reference.fasta -I input.bam -o output.bam --read_filter MappingQualityZero

hints:
  - class: ResourceRequirement
    coresMin: 8

requirements: 
  - class: DockerRequirement
    dockerPull: "quay.io/pancancer/pcawg-gatk-cocleaning:0.1.1"

baseCommand: 
  - "java"
  - "-jar"
  - "/opt/GenomeAnalysisTK.jar"
  - "-T"
  - "PrintReads"
  - "--disable_auto_index_creation_and_locking_when_reading_rods"

arguments: 
  - valueFrom: $(runtime.cores)
    prefix: -nct

  - valueFrom: $(inputs.input_bam.nameroot).cleaned.bam
    prefix: -o

inputs:
  input_bam:
    type: File
    inputBinding: 
      prefix: -I
    secondaryFiles:
      - ^.bai

  reference:
    type: File
    inputBinding: 
      prefix: -R
    secondaryFiles:
      - .fai
      - ^.dict

  bqsr:
    type: File
    inputBinding:
        prefix: -BQSR
    doc: the recalibration table produced by BaseRecalibration

  platform:
    type: string?
    inputBinding:
      prefix: --platform
    doc: Exclude all reads with this platform from the output

  number:
    type: int?
    inputBinding:
      prefix: --number
    doc: Exclude all reads with this platform from the output

  simplify:
    type: boolean?
    inputBinding:
      prefix: --simplify
    doc: Erase all extra attributes in the read but keep the read group information

  readGroup:
    type: string?
    inputBinding:
      prefix: --readGroup
    doc: Exclude all reads with this read group from the output

  emit_oq:
    type: boolean?
    inputBinding: 
      prefix: --emit_original_quals
    doc: Emit the OQ tag with the original base qualities

outputs: 
  output:
    type: File
    outputBinding: 
      glob: $(inputs.input_bam.nameroot).cleaned.bam
    secondaryFiles:
      - ^.bai
