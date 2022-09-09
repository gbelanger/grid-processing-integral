#!/bin/bash

startdir=$PWD

PIPE_DIR="/home/int/intportalowner/integral/pipeline"
LOG_DIR=${PIPE_DIR}/logs
OUTPUT_DIR=${LOG_DIR}/output

cd $OUTPUT_DIR

instruments="isgri jmx1 jmx2 spi"

for inst in $instruments ; do
  echo "Checking completion status for $inst"
  echo " - Counting successfully completed ..."
  egrep "science_analysis terminating with status 0" *${inst}*.out > good
  echo " - Counting failed ..."
  egrep "science_analysis terminating with status -" *${inst}.out > failed
  nFailed=$(wc -l < failed) 
  nGood=$(wc -l < good)
  nTot=$(expr $nGood + $nFailed)
  echo " - Results:"
  echo " - $nTot scw processed"
  echo " - $nGood scw terminating with status = 0"
  echo " - $nFailed scw terminating with status != 0"
done

rm good failed
cd $startdir
