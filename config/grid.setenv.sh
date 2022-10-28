#!/bin/bash

export BIN_DIR="/home/int/intportalowner/bin"
export INT_DIR="/home/int/intportalowner/integral"
export INTBIN_DIR="${INT_DIR}/bin"
export SKYGRID_DIR="${INT_DIR}/skygrid"
export ISOC5="/data/int/isoc5/intportalowner/isocArchive"

export JAVA_HOME="/home/int/intportalowner/jdk"
export JAVA="${JAVA_HOME}/bin/java -Xms500m -Xmx500m"
export OSA_DIR="${INT_DIR}/osa_support"
export PIPELINE_DIR="${INT_DIR}/pipeline"

export CALC="${BIN_DIR}/calc.pl"

export HEADAS="/opt/sw/heasoft6.25/x86_64-pc-linux-gnu-libc2.12"
. $HEADAS/headas-init.sh
export FTOOLS="${HEADAS}/bin"
export HEADASNOQUERY=
export HEADASPROMPT=/dev/null

