#!/bin/sh

if [[ $# -ne 1 ]]
then
  echo "Usage: . jmx2_analysis_IMA.sh band [46-82|83-153|154-224]"
  return 1
fi

if [[ "$1" != "46-82" && "$1" != "83-153" && "$1" != "154-224" ]]
then
  echo "Error: Band must be 46-82|83-153|154-224"
  return 1
fi

emin=`echo $1 | cut -d"-" -f1`
emax=`echo $1 | cut -d"-" -f2`

COMMONSCRIPT=1
export COMMONSCRIPT

COMMONLOGFILE=+jmx2_analysis_IMA.log
export COMMONLOGFILE

jemx_science_analysis \
  ogDOL="" jemxNum=2 \
  startLevel="COR" \
  endLevel="IMA" \
  skipLevels="SPE,BIN_S,BIN_T" \
  nChanBins=1 \
  chanLow="${emin}" \
  chanHigh="${emax}" \
  IMA_skyImagesOut="RECONSTRUCTED,VARIANCE,SIGNI,PIF" \
  LCR_timeStep=100. \
  LCR_useIROS=yes \
  LCR_doBurstSearch=no \
  IMA2_print_ScWs=yes 

  #nChanBins=3 chanLow="46 83 154" chanHigh="82 153 224"  \
