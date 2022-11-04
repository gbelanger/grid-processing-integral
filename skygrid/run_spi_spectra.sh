#!/bin/bash

# Last modified
#
# G.Belanger (Oct 2022)
# - moved common variables to config/grid.setenv.sh
#
# G.Belanger and T.Siegert (Aug 2022)
#  - created script


if [[ $# != 1 ]] ; then
  echo "Usage: ./run_spi_analysis.sh scw.lis (field/field_1.lis)"
  exit -1
fi

##  Check input list
list=$1
if [[ ! -e $list ]] ; then 
  echo "Error: $list : File not found" 
  exit -1
elif [[ ! -s $list ]] ; then
  echo "Error: $list : File is blank"
  exit -1
fi


##  Begin
START_DIR=${PWD}


##  Define common variables
source /home/int/intportalowner/integral/config/grid.setenv.sh


##  Sort the list and remove duplicate entries
sort -u ${list} > /tmp/tmp.lis
mv /tmp/tmp.lis ${list}


##  Define output directory based on name/path of scw.lis
inst_dir="spi"
OUT_DIR="${ISOC5}/${inst_dir}/skygrid/fields"
if [[ ! -d ${OUT_DIR} ]] ; then mkdir -p ${OUT_DIR} ; fi

### IMPORTANT : ${list} must contain _one_ directory name above the file name

listname=$(echo ${list} | cut -d"/" -f2)

### IMPORTANT : ${listname} must have the form:  scw_pt${num}_${ra}_${dec}_${dist}deg.lis


##  Create output directory
field=$(echo ${listname} | cut -d"_" -f2 | sed s/"pt"/"field_"/g)
output_dir="${OUT_DIR}/${field}"
if [[ ! -d ${output_dir} ]] ; then mkdir -p ${output_dir} ; fi


##  Move into output directory
touch ${output_dir}
cd ${output_dir}


##  Copy the input scw list here
cp ${START_DIR}/${list} ./${listname}


##  Exit if only one scw
n=$(wc -l ${listname} | awk '{print $1}') 
if [[ $n -eq 1 ]]
then
  echo "Only one scw in $pwd" > NO_RUN.readme
  exit 0
fi


##  Filter the scw list
in=${listname}
out="selected_${listname}"
. select_spi_scws.sh ${in} ${out}


##  Set OSA environment variables
source ${PIPELINE_DIR}/osa.setenv.sh


##  Create the observation group
og_create idxSwg=selected_${listname} ogid="myobs" baseDir="./" instrument=SPI


##  Go into the analysis dir
cd obs/myobs


##  Copy the SPI master catalog here
cp ${OSA_DIR}/spi_cat_all_sources.fits .


##  Run spi_science_analysis for the  binning
#${SKYGRID_DIR}/spi_analysis_BIN.sh


##  Select sources in the FOV
${SKYGRID_DIR}/select_spi_sources.sh


##  Run spi_science_analysis for the spectral extraction
${SKYGRID_DIR}/spi_analysis_SPE.sh


##  Cleanup OSA links
cd ../../
/bin/rm -r ic idx cat aux scw pfiles


##  Go back to where we started from
cd $START_DIR
