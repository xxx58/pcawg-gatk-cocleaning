
FROM opengenomics/gatk-cocleaning
USER root

COPY indel_realign.py /opt/

RUN apt-get update && \
    apt-get install --yes python-pip
RUN pip install python-dateutil pytz

WORKDIR /tmp
VOLUME /tmp
CMD ["bash"]
