#!/usr/bin/env bash

set -o errexit  # exit when a command fails
set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)

#   Modification history:
#
# G.Belanger (Aug-Sep 2022)
# - Created from timeseries_launch.sh
#


##  Define program name and logging functions
log(){
    local progName="launch_timeseries_fullmission.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - ${date} - (${progName}) : "
    echo $log
    unset progName
}

warn(){
    local progName="launch_timeseries_fullmission.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[WARN] - ${date} - (${progName}) : "
    echo $log
    unset progName
}

error(){
    local progName="launch_timeseries_fullmission.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[ERROR] - ${date} - (${progName}) : "
    echo $log
    unset progName
}


##  Check arguments
if [[ $# -ne 3 ]]
then
    echo "$(error) Usage: launch_timeseries_fullmission.sh srcname.lst band (e.g.,20-35|46-82) instrument (ISGRI|JMX1|JMX2)"
    exit -1
fi


##  Assign args to variables
names=$1
band=$2
instrument=$3


##  Check instrument and define inst_dir
case ${instrument} in
  ISGRI)
    inst_dir=ibis
    ;;
  JMX1|JMX2)
    inst_dir=jmx
    ;;
  *)
    echo "$(error) Unknown instrument $instrument. Can be ISGRI|JMX1|JMX2"
    exit -1
    ;;
esac


##  Check source names file
if [[ ! -f ${names} ]] ; then
  echo "$(error) ${names} : No such file."
  exit -1
else
  size=$(wc -c < ${names})
  if [[ ${size} -lt 1 ]] ; then
    echo "$(error) $names : File is empty"
    exit -1
  fi
fi


##  Begin
START_DIR="${PWD}"


##  Define INTEGRAL directories
INT_DIR="/home/int/intportalowner/integral"
SKYGRID_DIR="${INT_DIR}/skygrid"
ISOC5="/data/int/isoc5/gbelange/isocArchive"

##  Define time series root output directory
TS_DIR="${ISOC5}/${inst_dir}/timeseries_${band}"


##  Define executable and qsub command
executable="make_timeseries_fullmission.sh"
qsub="qsub -p -1000 -cwd -l h_vmem=5G -S /bin/bash -q int.q"


##  Loop through sources and launch
cat ${names} | while read srcname ; do

  ##  Check number of running jobs: must be less than 2000
  nJobs=$(qstat -u intportalowner | cat -n | tail -1 | awk '{print $1}')
  while [[ $nJobs -gt 1999 ]] ; do
    sleep 15
    nJobs=$(qstat -u intportalowner | cat -n | tail -1 | awk '{print $1}')
  done


  ##  Define the SRC_DIR
  dir=$(echo $srcname | sed s/" "/"_"/g)
  if [[ ! -d ${TS_DIR}/${dir} ]] ; then
    echo "$(warn) Output source time serie directory not found"
    echo "$(log) mkdir -p ${TS_DIR}/${dir}"
    mkdir -p ${TS_DIR}/${dir}
  fi
  SRC_DIR=${TS_DIR}/${dir}


  ##  Submit to grid
  date=$(date +%F)
  inst=${instrument,,}
  o="${SRC_DIR}/log.out.${inst}.${band}.${date}"
  e="${SRC_DIR}/log.err.${inst}.${band}.${date}"
#  ${qsub} -o ${o} -e ${e} ${SKYGRID_DIR}/${executable} "$srcname" $band $instrument


  ## Run locally
  ${SKYGRID_DIR}/${executable} "$srcname" $band $instrument

done


##  Go back to where we started from
cd ${START_DIR}
