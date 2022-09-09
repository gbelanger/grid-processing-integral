#!/usr/bin/env bash
#set -o errexit # exit when a command fails
#set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)


# Modification history:
#
# G.Belanger (Aug-Sep 2022)
# - created script from previous version of timeseries_make.sh


##  Define logging functions
log(){
    local progName="ibis_timeseries.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - ${date} - (${progName}) : "
    echo $log
    unset progName
}

warn(){
    local progName="ibis_timeseries.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[WARN] - ${date} - (${progName}) : "
    echo $log
    unset progName
}

error(){
    local progName="ibis_timeseries.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[ERROR] - ${date} - (${progName}) : "
    echo $log
    unset progName
}


##  Check arguments
if [[ $# -ne 3 ]]
then
  echo "$(error) Usage: ibis_timeseries.sh srcname band (20-35|35-60|60-100) /full/path/to/scw.lis"
  exit -1
fi


# Assign args to variables
name=$1
band=$2
list=$3

inst_idx=ibis
inst=isgri


##  Check list
if [[ ! -e $list ]] ; then 
  echo "$(error) $list : File not found" 
  exit -1
elif [[ ! -s $list ]] ; then
  echo "$(error) $list : File is blank"
  exit -1
fi


##  Sort the list and remove duplicate entries
sort -u ${list} > /tmp/tmp.lis
mv /tmp/tmp.lis ${list}


##  Check band and input data directory
ISOC5="/data/int/isoc5/gbelange/isocArchive"
DATA_DIR="${ISOC5}/${inst_idx}/scw_${band}"
if [[ ! -d $DATA_DIR ]] ; then
  echo "$(error) $DATA_DIR : Input data directory not found"
  exit -1
fi
emin=$(echo $band | cut -d"-" -f1)
emax=$(echo $band | cut -d"-" -f2)


##  Begin
START_DIR=${PWD}


##  Define Java executable
home="/home/int/intportalowner"
JAVA_HOME="${home}/jdk"
java="${JAVA_HOME}/bin/java -Xms500m -Xmx500m"


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
TS_DIR="${ISOC5}/timeseries_cat_0043"
INT_DIR="/home/int/intportalowner/integral"
BIN_DIR="${ISOC5}/bin"


##  Check that data dir exists
if [ ! -d ${DATA_DIR} ] ; then
  echo "$(error) Source data directory ${DATA_DIR} not found. Cannot proceed."
  exit -1
fi


##  Go to output directory
dir=$(echo $name | sed s/" "/"_"/g)
if [[ ! -d ${TS_DIR}/${dir} ]] ; then
  echo "$(warn) Output source time serie directory not found"
  echo "$(log) Creating time series directory"
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


##  Check if time series already exists
output="ts_${inst}_${ra}_${dec}_${emin}-${emax}keV.fits"

if [[ -e $output ]] ; then
  echo "$(warn) Detected previous version of file:  $output"
  echo "$(log) Comparing scw list"

  ##  Compare current list with previous
  if [[ -f ${inst}.lis ]] ; then
    mv ${inst}.lis ${inst}_old.lis
  fi
  cp $list ./${inst}.lis

  if [[ -f ${inst}_old.lis ]] && [[ -f ${inst}.lis ]] && [[ -s ${inst}.lis ]] ; then
    diff ${inst}.lis ${inst}_old.lis > ${inst}_diff.lis
    if [[ ! -s ${inst}_diff.lis ]] ; then
      rm ${inst}_old.lis
      echo "$(log) No difference in ${inst}.lis: nothing to update"
      rm ${inst}_diff.lis
      exit 0
    else
      echo "$(log) Updating time series"
      rm $output
    fi
  fi
fi


##  Construct the list of paths to the relevant data
echo "$(log) Contructing list of paths to input data ..."

#  Make list of unique revolutions from scw.lis
revs=`cat ${list} | cut -d / -f2 | sort -u`

#  Build path to data
startRev=26
pathToData=""

set -o noglob
for rev in $revs
do
  # Make sure we are using data beyond $startev
  if [ "${rev}" -ge "${startRev}" ] ; then
    pathToData="${pathToData} ${DATA_DIR}/${rev}/obs"
  fi
done

if [ "${pathToData}" == "" ] ; then
  echo "$(warn) No data beyond rev ${startRev}: No data to make time series"
  exit 0
fi
set +o noglob


##  Make time series
band_no=1
${java} -jar ${BIN_DIR}/MakeIsgriTimeSeries.jar ${ra} ${dec} ${band_no} ${list} ${pathToData}


##  Add the target name in the QDP output file
for file in ${output} ; do
  sed -i s/"Target Name:"/"Target Name: ${name}"/g $file
  sed -i s/"LAB T "/"LAB T ${name}"/g $file
done


## Set correct file permissions
chmod 644 *.*


##  Go back to where we started
cd $START_DIR
