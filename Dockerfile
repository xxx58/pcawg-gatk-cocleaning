
FROM opengenomics/gatk-cocleaning
USER root

RUN curl -sSL -o tmp.tar.gz --retry 10 https://github.com/ICGC-TCGA-PanCancer/pcawg-gatk-cocleaning/archive/0.1.1.tar.gz && \
    mkdir -p /tmp/pcawg-gatk-cocleaning && \
    tar -C /tmp/pcawg-gatk-cocleaning --strip-components 1 -zxf tmp.tar.gz && \
    cp -f /tmp/pcawg-gatk-cocleaning/indel_realign.py /opt/ && \
    rm -rf /tmp/pcawg-gatk-cocleaning/

RUN apt-get update && \
    apt-get install --yes python-pip
RUN pip install python-dateutil pytz

WORKDIR /tmp
VOLUME /tmp
CMD ["bash"]
