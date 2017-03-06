
FROM broadinstitute/genomes-in-the-cloud:2.2.2-1466113830
USER root
RUN mv * /opt/
RUN mv /opt/GATK36.jar /opt/GenomeAnalysisTK.jar
ADD indel_realign.py /opt/
WORKDIR /tmp
CMD ["bash"]
