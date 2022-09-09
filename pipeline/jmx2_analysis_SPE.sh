#!/bin/sh

COMMONSCRIPT=1
export COMMONSCRIPT

COMMONLOGFILE=+jmx2_analysis_SPE.log
export COMMONLOGFILE

jemx_science_analysis ogDOL="" \
  jemxNum=2 \
  startLevel="COR" endLevel="SPE" \
  nChanBins=-4 \
  timeStart=-1 timeStop=-1 \
  response="jmx2_rebinned16_rmf.fits" \
  arf="" \
  IMA_userImagesOut=no
