
FROM broadinstitute/genomes-in-the-cloud:2.2.2-1466113830
USER root

RUN ln /opt/GATK36.jar /opt/GenomeAnalysisTK.jar
ADD indel_realign.py /opt/

RUN curl -sSL -o tmp.tar.gz --retry 10 https://github.com/ICGC-TCGA-PanCancer/pcawg-gatk-cocleaning/archive/0.1.1.tar.gz && \
    mkdir -p /tmp/pcawg-gatk-cocleaning && \
    tar -C /tmp/pcawg-gatk-cocleaning --strip-components 1 -zxf tmp.tar.gz && \
    cp /tmp/pcawg-gatk-cocleaning/indel_realign.py /opt/ && \
    rm -rf /tmp/pcawg-gatk-cocleaning/

WORKDIR /opt
RUN wget https://github.com/broadinstitute/picard/releases/download/1.122/picard-tools-1.122.zip
RUN unzip picard-tools-1.122.zip
RUN ln -s picard-tools-1.122 picard

RUN apt-get update && \
    apt-get install --yes python-pip
RUN pip install python-dateutil pytz

WORKDIR /tmp
VOLUME /tmp
CMD ["bash"]
