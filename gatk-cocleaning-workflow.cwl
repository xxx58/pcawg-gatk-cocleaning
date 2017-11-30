class: Workflow
cwlVersion: v1.0
label: GATK Co-Cleaning Workflow

requirements:
  - class: MultipleInputFeatureRequirement

inputs:
  tumor_bam:
    type: File

  normal_bam:
    type: File

  knownIndels:
    type:
      - type: array
        items: File
    secondaryFiles:
      - .tbi

  knownSites:
    type: 
      - type: array
        items: File
    secondaryFiles:
      - .tbi

  reference:
    type: File
    secondaryFiles:
      - .fai
      - ^.dict

outputs:
  cleaned_tumor_bam:
    type: File
    outputSource: printreads_tumor/output

  cleaned_normal_bam:
    type: File
    outputSource: printreads_normal/output

steps:
  realigner_target_creator:
    run: gatk-realignertargetcreator.cwl
    in:
      input_bam: 
        - tumor_bam
        - normal_bam
      reference: reference
      knownIndels: knownIndels
    out:
      - target_intervals

  indel_realigner:
    run: gatk-indelrealigner.cwl
    in:
      tumor_bam: tumor_bam
      normal_bam: normal_bam
      reference: reference
      intervals: realigner_target_creator/target_intervals
      knownIndels: knownIndels
    out:
      - tumor_realigned
      - normal_realigned

  bqsr_tumor:
    run: gatk-baserecalibrator.cwl
    in:
      input_bam: indel_realigner/tumor_realigned
      reference: reference
      knownSites: knownSites
    out:
      - output_report
          
  printreads_tumor:
    run: gatk-printreads.cwl
    in: 
      input_bam: indel_realigner/tumor_realigned
      reference: reference
      bqsr: bqsr_tumor/output_report
    out:
      - output

  bqsr_normal:
    run: gatk-baserecalibrator.cwl
    in:
      input_bam: indel_realigner/normal_realigned
      reference: reference
      knownSites: knownSites
    out:
      - output_report
          
  printreads_normal:
    run: gatk-printreads.cwl
    in: 
      input_bam: indel_realigner/normal_realigned
      reference: reference
      bqsr: bqsr_normal/output_report
    out:
      - output
