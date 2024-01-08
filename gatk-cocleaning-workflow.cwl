class: Workflow
cwlVersion: v1.0
label: GATK Co-Cleaning Workflow

requirements:
  - class: MultipleInputFeatureRequirement

inputs:
  tumor_bam:
    type: File
    secondaryFiles:
    - .bai

  normal_bam:
    type: File
    secondaryFiles:
    - .bai

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

doc: |
    PCAWG GATK Co-cleaning workflow is developed by the Broad Institute
    (https://www.broadinstitute.org), it consists of two pre-processing steps for tumor/normal
    BAM files: indel realignment and base quality score recalibration (BQSR). The workflow
    has been dockerized and packaged using CWL workflow language, the source code is available on
    GitHub at: https://github.com/ICGC-TCGA-PanCancer/pcawg-gatk-cocleaning.


    ## Run the workflow with your own data

    ### Prepare compute environment and install software packages
    The workflow has been tested in Ubuntu 16.04 Linux environment with the following hardware and
    software settings.

    #### Hardware requirement (assuming 30X coverage whole genome sequence)
    - CPU core: 16
    - Memory: 64GB
    - Disk space: 1TB

    #### Software installation
    - Docker (1.12.6): follow instructions to install Docker https://docs.docker.com/engine/installation
    - CWL tool
    ```
    pip install cwltool==1.0.20170217172322
    ```

    ### Prepare input data
    #### Input aligned tumor / normal BAM files

    The workflow uses a pair of aligned BAM files as input, one BAM for tumor, the other for normal,
    both from the same donor. Here we assume file names are *tumor_sample.bam* and *normal_sample.bam*,
    and are under *bams* subfolder.

    #### Reference data files

    The workflow also uses the following files as reference, they can be downloaded from the ICGC Data Portal:

    - Under https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-bwa-mem
      - genome.fa.gz
      - genome.dict
    - Under https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-gatk-cocleaning
      - 1000G_phase1.indels.hg19.sites.fixed.vcf.gz
      - Mills_and_1000G_gold_standard.indels.hg19.sites.fixed.vcf.gz
      - dbsnp_132_b37.leftAligned.vcf.gz

    We assume the reference files are under *reference* subfolder.

    #### Job JSON file for CWL

    Finally, we need to prepare a JSON file with input, reference files specified. Please replace
    the *tumor_bam* and *normal_bam* parameters with your real BAM files.

    Name the JSON file: *pcawg-gatk-cocleaning.job.json*
    ```
    {
        "tumor_bam": {
            "class": "File",
            "location": "bams/tumor_sample.bam"
        },
        "normal_bam": {
            "class": "File",
            "location": "bams/normal_sample.bam"
        },
        "reference": {
            "class": "File",
            "location": "reference/genome.fa"
        },
        "knownIndels": [
            {
                "class": "File",
                "location": "reference/1000G_phase1.indels.hg19.sites.fixed.vcf.gz"
            },
            {
                "class": "File",
                "location": "reference/Mills_and_1000G_gold_standard.indels.hg19.sites.fixed.vcf.gz"
            }
        ],
        "knownSites": [
            {
                "class": "File",
                "location": "reference/dbsnp_132_b37.leftAligned.vcf.gz"
            }
        ]
    }
    ```

    ### Run the workflow
    #### Option 1: Run with CWL tool
    - Download CWL workflow definition files
    ```
    wget https://github.com/ICGC-TCGA-PanCancer/pcawg-gatk-cocleaning/archive/0.1.1.tar.gz
    tar xvf pcawg-gatk-cocleaning-0.1.1.tar.gz
    ```

    - Run `cwltool` to execute the workflow
    ```
    nohup cwltool --debug --non-strict pcawg-gatk-cocleaning-0.1.1/gatk-cocleaning-workflow.cwl pcawg-gatk-cocleaning.job.json > pcawg-gatk-cocleaning.log 2>&1 &
    ```

    #### Option 2: Run with the Dockstore CLI
    See the *Launch with* section below for details.
