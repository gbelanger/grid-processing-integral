#!/usr/bin/env bash

#set -o errexit # exit when a command fails
set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)


# Modification history:
#
# G.Belanger (Oct 2022)
# - moved common variables to config/grid.setenv.sh
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


##  Check instrument and define inst_dir
case ${instrument} in
  ISGRI)
    inst_dir=ibis
    ;;
  JMX1|JMX2)
    inst_dir=jmx
    ;;
  *)
    echo "$(error) Unknown instrument: $instrument."
    exit -1
    ;;
esac


##  Define common variables
echo "$(log) Setting common variables"
source /home/int/intportalowner/integral/config/grid.setenv.sh


##  Define time series root output directory
TS_DIR="${ISOC5}/${inst_dir}/timeseries_${band}"


##  Go to TS_DIR
dir=$(echo $name | sed s/" "/"_"/g)
if [[ ! -d ${TS_DIR}/${dir} ]] ; then
  echo "$(warn) Output time serie directory not found"
  echo "$(log) mkdir -p ${TS_DIR}/${dir}"
  mkdir -p ${TS_DIR}/${dir}
fi
echo "$(log) cd ${TS_DIR}/${dir}"
cd ${TS_DIR}/${dir}


##  Set OSA env
echo "$(log) Setting OSA env"
source ${INT_DIR}/pipeline/osa.setenv.sh


##  Extract row of catalog for source name
echo "$(log) Extracting source information for ..."
echo "$(log) - NAME = ${name}"
infile="${ISDC_REF_CAT}"
outfile=out.fits
echo NAME==\"${name}\" > select.txt
${FTOOLS}/ftselect ${infile} ${outfile} @select.txt clobber=yes


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
if [[ $inst == isgri ]] ; then
  dist=12
else
  dist=4
fi
echo "$(log) Making time series with radius of $dist degrees"

stamp=$(date +%N)
newlist="${inst}_${stamp}.lis"
${JAVA} -jar ${INTBIN_DIR}/MakeScwList.jar $ra $dec $dist $dist $newlist


### FOR TESTING
  head -200 $newlist > tmp
  mv tmp $newlist
####


##  Make time series
echo "$(log) Calling instrument-specific time series maker script"

case $instrument in

  ISGRI)
    ${SKYGRID_DIR}/ibis_timeseries.sh "$name" $band $PWD/$newlist
    ;;

  JMX1|JMX2)
    ${SKYGRID_DIR}/jmx_timeseries.sh "$name" $band $instrument $PWD/$newlist
    ;;

esac
