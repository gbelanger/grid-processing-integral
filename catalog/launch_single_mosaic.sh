#!/bin/bash

# Last modified
#
# G.Belanger (April 2022)
#  - add support for jemx
# G.Belanger (March 2021)
#  - increase grid memory allocation to 10G
# G.Belanger (September 2015)
#  - added the option -pe make 5 (to run on 5 slots; whatever that means :))
# G.Belanger (July 2014)
#  - removed the 'instrument' argument supplied to run_integ_mosa.sh
#     (this argument is only used to define the 'processing' script)
# G.Belanger (September 2012)
# G.Belanger (June 2009)
# D.Tapiador (April 2007)
#

if [ $# -lt 3 ]; then
   echo "Usage: . launch_single_mosa.sh field/field_1.lis instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82)"
   return 1
fi

list=$1
instrument=$2
band=$3

##  Check list
if [[ ! -s $list ]] ; then
  echo "Error: $list : File not found or empty";
  return 1;
fi

##  Check instrument
if [[ $instrument != ISGRI ]]
then
  inst=ibis;
elif [[ $instrument != JMX* ]]
then
  inst=jmx;
else
  echo "Error: $instrument : Unknown instrument. Options are ISGRI|JMX1|JMX2.";
  return 1;
fi

##  Check band
ISOC5="/data/int/isoc5/gbelange/isocArchive"
DATA_DIR="$ISOC5/${inst}/scw_${band}"
if [[ ! -d $DATA_DIR ]] ; then
  echo "Error: $DATA_DIR : Directory not found.";
  return 1;
fi

## Create directories for output logs
if [[ ! -d logs ]]
then 
    mkdir -p logs/error ; 
    mkdir -p logs/output ; 
fi

## Wait until less than 2000 jobs
nJobs=$(qstat -u intportalowner | cat -n | tail -1 | awk '{print $1}')
while [[ $nJobs -gt 1999 ]] ; do
  sleep 10
  nJobs=$(qstat -u intportalowner | cat -n | tail -1 | awk '{print $1}')
done

## Run on grid IMPORTANT: option -l h_vmem=5G is necessary
qsub="/opt/univa/ROOT/bin/lx-amd64/qsub -cwd -pe make 5 -l h_vmem=10G -S /bin/bash -q int.q"
${qsub} -e logs/error -o logs/output run_integ_mosa.sh $list $instrument $band

## Run locally
#. run_integ_mosa.sh $list $instrument $band
