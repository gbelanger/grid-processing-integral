#!/usr/bin/env bash

#set -o errexit # exit when a command fails
set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)


# Modification history:
#
# G.Belanger (Aug-Sep 2022)
# - created script 


##  Define logging functions
log(){
    local progName="make_timeseries_fullmission.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - ${date} - (${progName}) : "
    echo $log
    unset progName
}

warn(){
    local progName="make_timeseries_fullmission.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[WARN] - ${date} - (${progName}) : "
    echo $log
    unset progName
}

error(){
    local progName="make_timeseries_fullmission.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[ERROR] - ${date} - (${progName}) : "
    echo $log
    unset progName
}


##  Check arguments
progName="make_timeseries_fullmission.sh"
if [[ $# -ne 3 ]]
then
  echo "$(error) Usage: ${progName} srcname band (e.g., 20-35, 46-82) instrument (ISGRI|JMX1|JMX2)"
  exit -1
fi


# Assign args to variables
name=$1
band=$2
instrument=$3


##  Define Java executable
home="/home/int/intportalowner"
JAVA_HOME="${home}/jdk"
JAVA="${JAVA_HOME}/bin/java -Xms500m -Xmx500m"


##  Set HEADAS env
echo "$(log) Setting HEADAS env"
HEADAS="/opt/sw/heasoft6.25/x86_64-pc-linux-gnu-libc2.12"
# HEADAS="/opt/sw/heasoft-6.30.1/x86_64-pc-linux-gnu-libc2.28"
export HEADAS
. $HEADAS/headas-init.sh
export FTOOLS="${HEADAS}/bin"
export HEADASNOQUERY=
export HEADASPROMPT=/dev/null


##  Define INTEGRAL directories
INT_DIR="/home/int/intportalowner/integral"
SKYGRID_DIR="${INT_DIR}/skygrid"
ISOC5="/data/int/isoc5/gbelange/isocArchive"
BIN_DIR="${ISOC5}/bin"

#  Time series root directory
TS_DIR="${ISOC5}/timeseries_cat_0043"


##  Go to TS_DIR
dir=$(echo $name | sed s/" "/"_"/g)
if [[ ! -d ${TS_DIR}/${dir} ]] ; then
  echo "$(warn) Output source time serie directory not found"
  echo "$(log) mkdir -p ${TS_DIR}/${dir}"
  mkdir -p ${TS_DIR}/${dir}
fi
echo "$(log) cd ${TS_DIR}/${dir}"
cd ${TS_DIR}/${dir}


##  Set OSA env
echo "$(log) Setting OSA env"
. ${INT_DIR}/pipeline/osa.setenv.sh


##  Extract row of catalog for source name
echo "$(log) Extracting source information for ..."
echo "$(log) - NAME = ${name}"
infile="cat/hec/gnrl_refr_cat.fits"
outfile=out.fits
echo NAME==\"${name}\" > select.txt
${FTOOLS}/ftselect ${infile}[1] ${outfile} @select.txt clobber=yes


##  Check extraction
nrows=$(${FTOOLS}/fkeyprint ${outfile}[1] NAXIS2 | tail -1 | awk '{print $3}')
if [[ $nrows -eq 0 ]] ; then
  echo "$(error) - $name not found in $infile. Cannot proceed."
  exit 1
fi


##  Get the srcid, ra, dec
srcid=$(${FTOOLS}/ftlist ${outfile}[1] columns="SOURCE_ID" rows=1 T | tail -1 | awk '{print $2}')
ra=$(${FTOOLS}/ftlist ${outfile}[1] columns="RA_OBJ" rows=1 T | tail -1 | awk '{print $2}')
dec=$(${FTOOLS}/ftlist ${outfile}[1] columns="DEC_OBJ" rows=1 T | tail -1 | awk '{print $2}')
/bin/rm ${outfile} select.txt

echo "$(log) - SOURCE_ID = $srcid"
echo "$(log) - RA_OBJ = $ra"
echo "$(log) - DEC_OBJ = $dec"


##  Make new scw list using ra dec
inst=${instrument,,}
if [[ $inst == ibis ]] ; then
  dist=12
else
  dist=4
fi
echo "$(log) Making time series with radius of $dist degrees"

stamp=$(date +%N)
newlist="${inst}_${stamp}.lis"
${JAVA} -jar ${BIN_DIR}/MakeScwList.jar $ra $dec $dist $dist $newlist


##  Make time series
echo "$(log) Calling instrument-specific time series maker script"

case $instrument in

  ISGRI)
    ${SKYGRID_DIR}/ibis_timeseries.sh $name $band $PWD/$newlist
    ;;

  JMX1|JMX2)
    ${SKYGRID_DIR}/jmx_timeseries.sh $name $band $instrument $PWD/$newlist
    ;;

  *)
    echo "$(error) Unknown instrument: $instrument."
    ;;

esac
