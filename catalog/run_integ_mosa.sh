#!/bin/bash


# Last modified
#
# G.Belanger (Sep 2022)
# - Adapted for catalog production from skygrid/run_integ_mosa.sh
#


log(){
    local progName="run_integ_mosa.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - $date - ($progName) : "
    echo $log
    unset progName
}

warn(){
    local progName="run_integ_mosa.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    warn="[WARN] - $date - ($progName) : "
    echo $warn
    unset progName
}

error(){
    local progName="run_integ_mosa.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    error="[ERROR] - $date - ($progName) : "
    echo $error
    unset progName
}


##  Check args
if [[ $# != 3 ]]
then
  echo "Usage: ./run_integ_mosa.sh scw.lis (field/field_1.lis) instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82|83-153|154-224)"
  exit -1
fi

START_DIR=${PWD}


## Specify java memory: otherwise java crahses
JAVA_HOME="${HOME}/jdk"
JAVA="${JAVA_HOME}/bin/java -Xms200m -Xmx200m"


##  Define FTOOLS
HEADAS="/opt/sw/heasoft6.25/x86_64-pc-linux-gnu-libc2.12"
# HEADAS="/opt/sw/heasoft-6.30.1/x86_64-pc-linux-gnu-libc2.28"
export HEADAS
. $HEADAS/headas-init.sh
export FTOOLS="${HEADAS}/bin"
export HEADASNOQUERY=
export HEADASPROMPT=/dev/null


# Read arguments
list=$1
instrument=$2
band=$3


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


##  Check instrument and define inst_idx
case $instrument in
  ISGRI)
    inst_idx="ibis";
    inst=${inst_idx};
    processing=${inst_idx}_ima_mosaic.sh;
    ;;
  JMX1|JMX2)
    # lower case
    inst_idx=${instrument,,};
    inst="jmx";
    processing=${inst_idx}_ima_mosaic.sh;
    ;;
  *)
    echo "$(error) $instrument : Unknown instrument. Options are ISGRI|JMX1|JMX2.";
    exit -1;
    ;;
esac


##  Check band and input data directory
ISOC5="/data/int/isoc5/gbelange/isocArchive"
DATA_DIR="${ISOC5}/${inst}/scw_${band}"
if [[ ! -d $DATA_DIR ]] ; then
  echo "$(error) $DATA_DIR : Directory not found"
  exit -1
fi


##  Define INTEGRAL directories
BIN_DIR="/home/int/intportalowner/bin"
INT_DIR="/home/int/intportalowner/integral"
PIPELINE_DIR="${INT_DIR}/pipeline"
CAT_DIR="${ISOC5}/${inst}/catalog/mosaics"
MOSAICS_DIR=${CAT_DIR}


##  Define output directory based on name/path of scw.lis

### IMPORTANT : ${list} must contain _one_ directory name above the file name

listname=$(echo $list | cut -d"/" -f2)

### IMPORTANT : ${listname} must have the form:  scw_pt${field}.${sub}_${ra}_${dec}_${dist}deg.lis

field=$(echo ${listname} | cut -d"_" -f2 | sed s/"pt"/"field_"/g)
output_mosa_dir="${MOSAICS_DIR}/${field}"


##  Check/Create parent output directory
if [[ ! -d ${MOSAICS_DIR} ]] ; then mkdir -p ${MOSAICS_DIR} ; fi


##  Move into parent output directory
touch ${MOSAICS_DIR}
cd ${MOSAICS_DIR}


##  Copy the input scw list here temporarily (filenames are unique)
cp ${START_DIR}/${list} ./${listname}


##  Exit if only one scw
n=$(wc -l ${listname} | awk '{print $1}') 
if [[ $n -le 1 ]] ; then
  echo "Only one scw in ${listname}" >> ${MOSAICS_DIR}/NO_MOSAICS.readme
  rm ./${listname}
  exit 0
fi


##  Construct list of input data directories needed for mosaic
pathToData=""
dirs=$(cat ${listname} | cut -d"/" -f2 | sort -nu)
set -o noglob

for rev in ${dirs} ; do
  ##  Make sure we are using data beyond rev 26
  if [ $rev -ge 0026 ] ; then
    path2="${DATA_DIR}/${rev}/obs"
    pathToData="${pathToData} ${path2}"
  fi
done

if [[ "${pathToData}" == "" ]] ; then
  echo "$(error) No data beyond rev 26. Cannot make mosaic"
  echo "No data beyond rev 26 for ${listname}" >> ${MOSAICS_DIR}/NO_MOSAICS.readme
  exit 0
fi
set +o noglob


##  Prepare the Observation Groups

case $instrument in

  ISGRI)

    ##  Delete previous child output directory
    if [[ -d ${output_mosa_dir} ]] ; then
      chmod -fR 755 ${output_mosa_dir}
      /bin/rm -r ${output_mosa_dir}
    fi


    ##  Select images 
#    ${JAVA} -jar ${INT_DIR}/bin/SelectSkyIma.jar $listname signif 1 1.9 $pathToData


    ##  Make OG for ibis analysis (this creates $output_mosa_dir here named $field)
    if [[ -f ${listname}.selected ]] ; then
      ${JAVA} -jar ${INT_DIR}/bin/OG_merge.jar ${listname}.selected $field $pathToData
    else
      ${JAVA} -jar ${INT_DIR}/bin/OG_merge.jar ${listname} $field $pathToData
    fi


    ##  Check if OG_merge.jar worked
    if [ ! -d $field/obs/myobs ] ; then
      echo "$(error) OG_merge.jar failed to prepare mosaic directory"
      exit -1
    fi


    ##  Move all the lists into the output mosa dir
    mv ${listname}* $field/


    ##  Copy support files needed for imaging analysis (to not recreate them for each scw)
    cp ${INT_DIR}/osa_support/rebinned_back_ima_${band}.fits ${field}/obs/myobs/rebinned_back_ima.fits
    cp ${INT_DIR}/osa_support/rebinned_corr_ima_${band}.fits ${field}/obs/myobs/rebinned_corr_ima.fits
    cp ${INT_DIR}/osa_support/rebinned_unif_ima_${band}.fits ${field}/obs/myobs/rebinned_unif_ima.fits


    ##  This hidden option makes a residual map where both sources and ghosts are removed
    #echo "8" > ${field}/obs/myobs/ii_skyimage.hidden


    ##  Set OSA environment variables
    touch ${output_mosa_dir}
    cd ${output_mosa_dir}
    . ${PIPELINE_DIR}/osa11.setenv.sh


    ##  Move into final output mosaic dir
    cd obs/myobs
    ;;

  JMX1 | JMX2)

    ##  Check/Create the mosaic directory
    if [[ ! -e ${output_mosa_dir} ]] ; then mkdir -p ${output_mosa_dir} ; fi
    touch ${output_mosa_dir}


    ##  Check/Update the scw list
    if [[ -e ${output_mosa_dir}/${listname} ]] ; then
      diff ./${listname} ${output_mosa_dir}/${listname} > ${output_mosa_dir}/diffs.txt
      if [[ -s diffs.txt ]] 
      then
        mv ${output_mosa_dir}/${listname} ${output_mosa_dir}/previous_${listname}
      fi
    fi
    mv ./${listname} ${output_mosa_dir}/


    ##  Go into the mosaic directory
    cd ${output_mosa_dir}


    ##  Set OSA environment variables
    . ${INT_DIR}/pipeline/osa11.setenv.sh


    ##  Create final mosaic output directory
    if [[ ! -e obs/myobs ]] ; then mkdir -p obs/myobs ; fi


    ##  Go into this directory
    cd obs/myobs/


    ##  Remove files from previous run
    inst_idx="${instrument,,}"
    if [[ -e swg_idx_${inst_idx}.fits ]] ; then /bin/rm swg_idx_${inst_idx}.fits ; fi
    if [[ -e list_swg_${inst_idx}.txt ]] ; then /bin/rm list_swg_${inst_idx}.txt ; fi


    ##  Compile list of images to mosaic
    filetype=${inst_idx}_sky_ima.fits
    idxlist=list_swg_${inst_idx}.txt
    cat ../../${listname} | while read line
    do
      rev=$(echo $line | cut -d"/" -f2)
      scwdir=$(echo $line | cut -d"/" -f3)
      scwid=$(echo $scwdir | cut -d"." -f1)
      ls ${DATA_DIR}/${rev}/obs/${scwid}/scw/${scwdir}/${filetype} | sed s/${filetype}/swg_${inst_idx}.fits/g >> $idxlist
    done


    ##  Convert the text file to a fits file of the swg index for all images
    txt2idx ${idxlist} swg_idx_${inst_idx}.fits


    ##  Remove old observation group file
    if [[ -e og_${inst_idx}.fits ]] ; then /bin/rm og_${inst_idx}.fits ; fi


    ##  Create new observation group file
    dal_create og_${inst_idx}.fits GNRL-OBSG-GRP.tpl
    dal_attach og_${inst_idx}.fits swg_idx_${inst_idx}.fits '' '' '' ''


    ##  Add instrument name in the new observation group file  
    ${FTOOLS}/fparkey ${instrument} og_${inst_idx}.fits INSTRUME
    ;;

esac


##  Make mosaic
case ${instrument} in

  ISGRI|IBIS)

    ##  Make the mosaic
    ${INT_DIR}/catalog/${processing} ${band}
    ;;

  JMX1|JMX2)

    if [[ ! -e ../../diffs.txt || -s ../../diffs.txt ]]
    then
      ${INT_DIR}/catalog/${processing} ${band}
    fi
    ;;

esac


##  Cleanup 
case ${instrument} in
  ISGRI)
    /bin/rm rebinned*;
    gzip *mosa_ima.fits
    ;;
  JMX1|JMX2)
    gzip *mosa_ima.fits
    ;;
esac


##  Move back two levels into $output_mosa_dir
cd ../../


##  Remove the OSA links and pfiles
#/bin/rm -r ic idx cat aux scw pfiles


##  Go back to where we started from
cd $START_DIR
