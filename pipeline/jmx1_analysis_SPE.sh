#!/bin/sh

COMMONSCRIPT=1
export COMMONSCRIPT

COMMONLOGFILE=+jmx1_analysis_SPE.log
export COMMONLOGFILE

jemx_science_analysis ogDOL="" \
  jemxNum=1 \
  startLevel="COR" endLevel="SPE" \
  nChanBins=-4 \
  timeStart=-1 timeStop=-1 \
  response="jmx1_rebinned16_rmf.fits" \
  arf="" \
  IMA_userImagesOut=no
