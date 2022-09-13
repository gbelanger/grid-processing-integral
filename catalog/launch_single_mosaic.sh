#!/bin/bash

# Last modified
#
# G.Belanger (Sep 2022)
#  - Adapted for catalog production from skygrid/launch_single_mosaic.sh
#


##  Check args
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
if [[ $instrument == ISGRI ]] ; then
  inst=ibis;
elif [[ $instrument == JMX* ]] ; then
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
INT_DIR="/home/int/intportalowner/integral"
CAT_DIR="${INT_DIR}/catalog"
if [[ ! -d ${CAT_DIR}/logs/output ]] || [[ ! -d ${CAT_DIR}/logs/error ]] ; then 
  mkdir -p ${CAT_DIR}/logs/error ; 
  mkdir -p ${CAT_DIR}/logs/output ; 
fi


## Wait until less than 2000 jobs in queue
nJobs=$(qstat -u intportalowner | cat -n | tail -1 | awk '{print $1}')
while [[ $nJobs -gt 1999 ]] ; do
  sleep 30
  nJobs=$(qstat -u intportalowner | cat -n | tail -1 | awk '{print $1}')
done


#  Define output and error log files
listname=$(echo $list | cut -d"/" -f2)
field=$(echo ${listname} | cut -d"_" -f2 | sed s/"pt"/"field_"/g)

o="${CAT_DIR}/logs/output/run_integ_mosa.${instrument,,}.${band}.field_${field}.out"
e="${CAT_DIR}/logs/error/run_integ_mosa.${instrument,,}.${band}.field_${field}.err"


## Run on grid IMPORTANT: option -l h_vmem=5G is necessary
qsub="/opt/univa/ROOT/bin/lx-amd64/qsub -cwd -pe make 5 -l h_vmem=10G -S /bin/bash -q int.q"

${qsub} -e ${e} -o ${o} run_integ_mosa.sh $list $instrument $band


## Run locally
#. run_integ_mosa.sh $list $instrument $band
