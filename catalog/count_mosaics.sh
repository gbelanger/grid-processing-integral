#!/bin/bash

##  Define logging functions
log(){
    local progName="count_mosaics.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - ${date} - (${progName}) : "
    echo $log
    unset progName
}
error(){
    local progName="count_mosaics.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[ERROR] - ${date} - (${progName}) : "
    echo $log
    unset progName
}

if [ $# -ne 1 ] ; then
  echo "Usage: . count_mosaics.sh band (20-35|35-60|60-100|46-82|83-153|154-224)"
  return 1
fi
band=$1

if [[ ${band} != 20-35 && ${band} != 35-60 && ${band} != 60-100 && ${band} != 46-82 && ${band} != 83-153 && ${band} != 154-224 ]] 
then
  echo "$(log) Unkown band. Band must be 20-35|35-60|60-100|46-82|83-153|154-224.";
  return 1
fi


echo "$(log) Band is ${band}"

case ${band} in 
  20-35|35-60|60-100)
    prefix=isgri;
    executable="ibis_science_analysis"
    inst_dir="ibis";
    ;;
  46-82|83-153|154-224)
    prefix=jmx;
    executable="j_ima_mosaic"
    inst_dir="jmx";
    ;;
  *)
    echo "$(log) Unknown band"
    return 1
    ;;
esac

echo "$(log) Instrument is ${prefix}"
#echo "$(log) Executable is ${executable}"
echo "$(log) Counting mosaics ..."

##  Define variables
ISOC5="/data/int/isoc5/intportalowner/isocArchive"
SKYGRID_MOSA_DIR="${ISOC5}/${inst_dir}/skygrid_${band}/mosaics"

n=$(ls -1 ${SKYGRID_MOSA_DIR}/field*/obs/myobs/*_mosa_ima.fits* | cat -n | tail -1 | awk '{print $1}')
echo "$(log) There are currently  $n  mosaics in ${SKYGRID_MOSA_DIR}"
