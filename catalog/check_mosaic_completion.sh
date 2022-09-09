#!/bin/bash

##  Define logging functions
log(){
    local progName="check_mosaic_completion.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - ${date} - (${progName}) : "
    echo $log
    unset progName
}
warn(){
    local progName="check_mosaic_completion.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[WARN] - ${date} - (${progName}) : "
    echo $log
    unset progName
}
error(){
    local progName="check_mosaic_completion.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[ERROR] - ${date} - (${progName}) : "
    echo $log
    unset progName
}

if [ $# -ne 1 ]
then
  progName="check_mosaic_completion.sh"
  echo "$(error) Usage: . ${progName} band (20-35|35-60|60-100|46-82|83-153|154-224)"
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
    inst="ibis";
    ;;
  46-82|83-153|154-224)
    prefix=jmx;
    executable="j_ima_mosaic"
    inst="jmx";
    ;;
  *)
    echo "$(log) Unknown band"
    return 1
    ;;
esac

##  Define variables
ISOC5="/data/int/isoc5/gbelange/isocArchive"
SKYGRID_MOSA_DIR="${ISOC5}/${inst}/skygrid_${band}/mosaics"

echo "$(log) Executable is ${executable}"
echo "$(log) Checking completion status in ${SKYGRID_MOSA_DIR}"

nFields=$(ls -d -1 ${SKYGRID_MOSA_DIR}/field_* | cat -n | tail -1 | awk '{print $1}')
echo "$(log) There are $nFields directories"

nMosaics=$(ls ${SKYGRID_MOSA_DIR}/field_*/obs/myobs/${prefix}*_mosa_ima.fits* | cat -n | tail -1 | awk '{print $1}')
echo "$(log)   There are $nMosaics ${prefix} mosaic files"

noMosaic=$(ls ${SKYGRID_MOSA_DIR}/field_*/NO_MOSAIC.readme | cat -n | tail -1 | awk '{print $1}')
echo "$(log)   There are $noMosaic directories with a single scw"

## Check for empty files
echo "$(log) Checking file size ..."

good=0
empty=0
emptyFiles=""
goodFiles=""

for file in $(ls ${SKYGRID_MOSA_DIR}/field_*/obs/myobs/${prefix}*_mosa_ima.fits*)
do
  size=$(wc -c <"$file")
  if [[ $size -gt 11520 ]]
  then
    good=$((good+1))
    goodFiles="$goodFiles $file"
  else
    empty=$((empty+1))
    emptyFiles="$emptyFiles $file"
  fi
done

echo "$(log)   $good look good"
echo "$(log)   $empty are (currently) empty."

if [[ $empty -gt 0 ]]
then
  echo "$(log)   Here's the list:"
  for file in $emptyFiles
  do
    echo "$(log)    $file"
  done
fi

## Check for crashed or incomplete
echo "$(log) Checking termination status ..."

finished=0
crashed=0
crashedFiles=""
crashedCodes=""

for file in $goodFiles
do
  dir=$(dirname $file)
  logFile="${dir}/log"
  status=$(egrep "${executable} terminating with status" $logFile | tail -1 | awk '{print $10}')
  if [ "$status" = "0" ]
  then
    finished=$((finished+1))
  else
    crashed=$((crashed+1))
    crashedFiles="$crashedFiles $file"
    crashedCodes="$crashedCodes $status"
  fi
done

completed=$(calc.pl $finished+$crashed)
echo "$(log)   Of the $good good images"
echo "$(log)   $finished were successfully completed"

if [[ -e fields_to_rerun_${band}.txt ]] ; then rm fields_to_rerun_${band}.txt ; fi
if [[ -e scwpt_to_rerun_${band}.txt ]] ; then rm scwpt_to_rerun_${band}.txt ; fi
if [[ -e mosaics_to_rerun_${band}.txt ]] ; then rm mosaics_to_rerun_${band}.txt ; fi

if [[ "$crashed" -gt 0 ]]
then
  echo "$(log)   $crashed crashed (or are still running). Here's the full list:"
  for file in $crashedFiles
  do
    echo "$(log)     $file"
    dir=$(dirname $file)
    echo $dir >> mosaics_to_rerun_${band}.txt
    field=$(echo $file | cut -d"/" -f9)
    echo $field >> fields_to_rerun_${band}.txt
    scwpt=$(echo $field | sed s/"field_"/"scw_pt"/g)
    echo $scwpt >> scwpt_to_rerun_${band}.txt
  done
  echo "$(log) Corrupted mosaic directories written to mosaics_to_rerun_${band}.txt"
  echo "$(log) Corresponding fields written to fields_to_rerun_${band}.txt"
  echo "$(log) Corresponding scw_pt written to scwpt_to_rerun_${band}.txt"
fi
