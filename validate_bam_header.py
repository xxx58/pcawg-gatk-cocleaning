#!/usr/bin/env python
"""
Validate BAM header
"""
from __future__ import print_function

import argparse
import dateutil.parser
import pytz
import os
import random
import re
import shutil
import string
import subprocess
import sys


def collect_args():
    descr = 'Validate BAM header'
    parser = argparse.ArgumentParser(
        description=descr
    )
    parser.add_argument("INBAM",
                        help="input BAM file")
    parser.add_argument("OUTBAM",
                        help="BAM file with validated header")
    parser.add_argument("--ID",
                        help="Read group identifier. Each @RG line must have a \
                        unique ID. The value of ID is used in the RG tags of \
                        alignment records. Must be unique among all read \
                        groups in header section. Read group IDs may be \
                        modified when merging SAM files in order to handle \
                        collisions. Ex: <centre_name>:<unique_text>")
    parser.add_argument("--CN",
                        help="Name of sequencing center producing the read")
    parser.add_argument("--DS",
                        help="Description")
    parser.add_argument("--DT",
                        help="Date the run was produced (ISO8601 date or \
                        date/time)")
    parser.add_argument(
        "--FO",
        help="Flow order. The array of nucleotide bases that correspond to the \
        nucleotides used for each flow of each read. Multi-base flows are \
        encoded in IUPAC format, and non-nucleotide flows by various other \
        characters. Format: /\*|[ACMGRSVTWYHKDBN]+/")
    parser.add_argument("--KS",
                        help="The array of nucleotide bases that correspond to \
                        the key sequence of each read.")
    parser.add_argument("--LB",
                        help="Library. Ex: 'WGS:<center_name>:<lib_id>'")
    parser.add_argument("--PG",
                        help="Programs used for processing the read group. \
                        Default: fastqtobam")
    parser.add_argument("--PI",
                        help="Predicted median insert size")
    parser.add_argument("--PL",
                        default="ILLUMINA",
                        choices=["CAPILLARY", "LS454", "ILLUMINA", "SOLID",
                                 "HELICOS", "IONTORRENT", "PACBIO"],
                        help="Platform/technology used to produce the reads")
    parser.add_argument("--PM",
                        help="Platform model Ex: 'Illumina Genome Analyzer II', \
                        'Illumina HiSeq 2000', 'Illumina HiSeq 2500'")
    parser.add_argument("--PU",
                        help="Platform unit. Ex: '<center_name>:<run>_<lane>[#<tag>]'")
    parser.add_argument("--SM",
                        help="Sample id")
    return parser


def id_generator(size=6, chars=string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))


def execute(cmd):
    print("RUNNING...\n", cmd, "\n")
    process = subprocess.Popen(cmd,
                               shell=True,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)

    while True:
        nextline = process.stdout.readline()
        if nextline == '' and process.poll() is not None:
            break
        sys.stdout.write(nextline)
        sys.stdout.flush()

    stderr = process.communicate()[1]
    if stderr is not None:
        sys.stderr.write(stderr)
    if process.returncode != 0:
        sys.stderr.write("[ERROR] command: {0} exited with code: {1}".format(
            cmd, process.returncode
        ))
    return process.returncode


def to_iso8601(time_string):
    parsed_time = dateutil.parser.parse(time_string)
    # add timezone info
    if parsed_time.tzinfo is None:
        # add +00:00 as tzinfo
        parsed_time.replace(tzinfo=pytz.timezone('UTC'))
    # remove microseconds
    if parsed_time.microsecond != 0:
        parsed_time.replace(microsecond=0)
    return parsed_time.isoformat()


def get_header(inbam, tmpdir):
    tmp_header = os.path.join(tmpdir, "header.original.sam")
    cmd = "samtools view -H {0} > {1}".format(inbam, tmp_header)
    execute(cmd)
    return tmp_header


def validate_rg(rg_lines):
    for i, rg in rg_lines.items():
        if all(k in rg.keys() for k in ["ID", "SM", "PL"]):
            return False
    return True


def process_header(args, header, tmpdir):
    with open(header, 'rb') as fh:
        content = fh.readlines()

    header_content = [x.strip() for x in content]

    if args.DT is not None:
        try:
            # try to convert DT to ISO 8061 formatted datetime
            args.DT = to_iso8601(args.DT)
        except Exception:
            sys.stderr.write(
                "[ERROR]  DT field was not able to be expressed as an " +
                "ISO 8061 compliant datetime: 'YYYY-MM-DD\"T\"HH24:MI:SS'")
            raise ValueError

    rg_lines = {}
    i = 0
    for line in header_content:
        if line.startswith("@RG"):
            fields = [f.split(":") for f in line.split("\t") if f != "@RG"]
            d = {}
            for f in fields:
                d[f[0]] = f[1]
                rg_lines[i] = d
        i += 1

    for i in rg_lines.iterkeys():
        for key, value in sorted(vars(args).items()):
            rg_keys = ['ID', 'CN', 'DS', 'DT', 'FO', 'KS', 'LB', 'PG', 'PI',
                       'PL', 'PM', 'PU', 'SM']
            if key in rg_keys and value is not None:
                if key == "DT":
                    rg_lines[i][key] = to_iso8601(value)
                else:
                    rg_lines[i][key] = value

    for line, rg in rg_lines.items():
        rg_line = ["@RG"]
        for k, v in rg.items():
            rg_line.append(k + ":" + v)
        header_content[line] = "\t".join(rg_line)

    if not validate_rg(rg_lines):
        raise RuntimeError(
            "BAM header @RG line missing one or more of: ID, SM, PL"
        )

    # write processed header to tmp file
    tmp_header = os.path.join(tmpdir, "header.new.sam")
    with open(tmp_header, 'w') as f:
        f.write("\n".join(header_content))
        f.close()

    return tmp_header


def samtools_reheader(inbam, new_header, outbam):
    cmd = "samtools reheader {0} {1} > {2}".format(
        new_header,
        inbam,
        outbam
    )
    execute(cmd)


def samtools_index(inbam):
    cmd = "samtools index {0}".format(inbam)
    execute(cmd)


def main():
    parser = collect_args()
    args = parser.parse_args()

    # setup tmp output directory to store intermediate files
    tmp_path = id_generator()
    if not os.path.isdir(tmp_path):
        execute("mkdir {0}".format(tmp_path))

    try:
        original_header = get_header(args.INBAM, tmp_path)
        new_header = process_header(args, original_header, tmp_path)
        samtools_reheader(args.INBAM, new_header, os.path.basename(args.OUTBAM))
        samtools_index(os.path.basename(args.OUTBAM))
    except Exception:
        raise
    finally:
        # cleanup
        shutil.rmtree(tmp_path)


if __name__ == "__main__":
    main()
