class: CommandLineTool
cwlVersion: v1.0

hints:
  - class: ResourceRequirement
    coresMin: 8

requirements: 
  - class: DockerRequirement
    dockerPull: cuhkhaosun/workflow-pancancer:gatk-cocleaning-latest

baseCommand: 
  - "java"
  - "-jar"
  - "/opt/GenomeAnalysisTK.jar"
  - "-T"
  - "BaseRecalibrator"
  - "--disable_auto_index_creation_and_locking_when_reading_rods"

arguments:
  - valueFrom: $(runtime.cores)
    prefix: -nct

  - valueFrom: recal_data.table
    prefix: -o

inputs:
  input_bam:
    type: File
    inputBinding: 
      prefix: -I
    secondaryFiles:
      - ^.bai
    doc: bam file produced after indelRealigner

  reference:
    type: File
    inputBinding: 
      prefix: -R
    secondaryFiles:
      - .fai
      - ^.dict

  knownSites:
    type:
    - 'null'
    - type: array
      items: File
      inputBinding:
        prefix: --knownSites
    inputBinding:
      position: 1
    secondaryFiles:
      - .tbi
    doc: Any number of VCF files representing known SNPs and/or indels. Could be e.g.
      dbSNP and/or official 1000 Genomes indel calls. SNPs in these files will be
      ignored unless the --mismatchFraction argument is used. optional parameter.

  deletions_default_quality:
    type: int?
    inputBinding:
      prefix: --deletions_default_quality
    doc: default quality for the base deletions covariat

  quantizing_levels:
    type: boolean?
    inputBinding:
      prefix: --quantizing_levels
    doc: Sort the rows in the tables of reports. Whether GATK report tables should
      have rows in sorted order, starting from leftmost column

  bqsrBAQGapOpenPenalty:
    type: double?
    inputBinding:
      prefix: --bqsrBAQGapOpenPenalty
    doc: BQSR BAQ gap open penalty (Phred Scaled). Default value is 40. 30 is perhaps
      better for whole genome call sets

  mismatches_context_size:
    type: int?
    inputBinding:
      prefix: --mismatches_context_size
    doc: Size of the k-mer context to be used for base mismatches

  maximum_cycle_value:
    type: int?
    inputBinding:
      prefix: --maximum_cycle_value
    doc: The maximum cycle value permitted for the Cycle covariate

  run_without_dbsnp_potentially_ruining_quality:
    type: boolean?
    inputBinding:
      prefix: --run_without_dbsnp_potentially_ruining_quality
    doc: If specified, allows the recalibrator to be used without a dbsnp rod. Very
      unsafe and for expert users only.

  lowMemoryMode:
    type: boolean?
    inputBinding:
      prefix: --lowMemoryMode
    doc: Reduce memory usage in multi-threaded code at the expense of threading efficiency

  solid_recal_mode:
    type: string?
    inputBinding:
      prefix: --solid_recal_mode
    doc: How should we recalibrate solid bases in which the reference was inserted?
      Options = DO_NOTHING, SET_Q_ZERO, SET_Q_ZERO_BASE_N, or REMOVE_REF_BIAS

  insertions_default_quality:
    type: int?
    inputBinding:
      prefix: --insertions_default_quality
    doc: default quality for the base insertions covariate

  sort_by_all_columns:
    type: boolean?
    inputBinding:
      prefix: --sort_by_all_columns
    doc: Sort the rows in the tables of reports. Whether GATK report tables should
      have rows in sorted order, starting from leftmost column

  list:
    type: boolean?
    inputBinding:
      prefix: --list
    doc: List the available covariates and exit

  indels_context_size:
    type: int?
    inputBinding:
      prefix: --indels_context_size
    doc: Size of the k-mer context to be used for base insertions and deletions

  mismatches_default_quality:
    type: int?
    inputBinding:
      prefix: --mismatches_default_quality
    doc: default quality for the base mismatches covariate

  covariate:
    type: string?
    inputBinding:
      prefix: --covariate
    doc: One or more covariates to be used in the recalibration. Can be specified
      multiple times

outputs: 
  output_report:
    type: File
    outputBinding: 
      glob: recal_data.table
