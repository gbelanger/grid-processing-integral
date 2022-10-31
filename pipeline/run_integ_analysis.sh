#!/usr/bin/env bash

set -o errexit # exit when a command fails
set -o nounset # exit when your script tries to use undeclared variables
#set -o pipefail # don't hide errors within pipes

#set -o xtrace # trace what gets executed (uncomment for debugging)

# Last modified by 
#
# G.Belanger (Oct 2022)
#  - Removed catalog related stuff from IBIS analysis
# G.Belanger (Sep 2022)
#  - added essential HEADAS env variables (their bug)
# G.Belanger (Aug 2022)
#  - added support for SPI binning analysis
# G.Belanger (Mar 2022)
#  - added support for JEMX imaging analysis
#  - improved formatting/syntax
# G.Belanger (Mar 2019)
#  - added condional to run osa 10.2 or 11 
# G.Belanger (Jan 2016)
#  - added properly time-stamped logging
# G.Belanger (Aug 2015)
#  - added conditionals for defining directory paths
#    depending on host (intggw or intggw6)
# G.Belanger (Sept 2014)
#  - combined emin and emax into band (20-35)
#  - removed the storageDir argument
#  - removed all old code for moving data around
# G.Belanger (July 2014) 
#  - process/write directly in storage directory
#  - added emin emax as arguments
# G.Belanger (September 2012)
#  - Wrote script
#

# General script for integral data analysis to be run on the Grid
# This script:
# 1) Parses general index to construct list of science windows per revolution
# 2) Sets the environment variables
# 3) creates the observation group 
# 4) calls the instrument-specific analysis script ${processing}

log(){
    local progName="run_integ_analysis.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - $date - ($progName) : "
    echo $log
    unset progName
}

warn(){
    local progName="run_integ_analysis.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    warn="[WARN] - $date - ($progName) : "
    echo $warn
    unset progName
}

error(){
    local progName="run_integ_analysis.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    error="[ERROR] - $date - ($progName) : "
    echo $error
    unset progName
}


## Check arguments
if [[ $# != 4 ]] ; then
  echo "Usage: . run_integ_analysis.sh processing (e.g., ibis_analysis_IMA.sh) rev (e.g., 0046) instrument (ISGRI|JMX1|JMX2|SPI) band (e.g., 20-35|46-82|25-400)"
  exit 0
fi


## Read arguments
processing=$1
rev=$2
instrument=$3
band=$4
emin=$(echo $band | cut -d"-" -f1)
emax=$(echo $band | cut -d"-" -f2)


## Check processing scripts exists
if [[ ! -f ${processing} ]] ; then
  echo "$(error) Processing script (${processing}) not found"
  return 1
fi


## Check the instrument
case $instrument in
  ISGRI | IBIS)
    inst_idx="IBIS";
    inst_dir="ibis";
    ;;
  JMX1 | JMX2) 
    inst_idx="$instrument";
    inst_dir="jmx";
    if [[ "$4" != "46-82" && "$4" != "83-153" && "$4" != "154-224" ]] ; then
      echo "$(error) ${instrument} band must be 46-82|83-153|154-224"
      return 1
    fi
    ;;
  SPI)
    inst_idx="$instrument";
    inst_dir="spi";
    processing="spi_analysis_BIN.sh";
    ;;
  *)
    echo "$(warn) Unknown instrument : $instrument. Choices are IBIS|JMX1|JMX2|SPI.";
    return 1;
    ;;
esac


##  Define common varibales
source /home/int/intportalowner/integral/config/grid.setenv.sh


## Check/Create output directory
OUTPUT_DIR="${ISOC5}/${inst_dir}/scw_${band}/"
if [ ! -d $OUTPUT_DIR ] ; then mkdir -p $OUTPUT_DIR ; fi


## Start the analysis

echo "$(log) Starting processing of rev $rev"
startTime=$(date +%s)


## Do not overwrite if $rev directory exists
#if [[ -d $OUTPUT_DIR/$rev ]] ; then
#  echo "$(warn) Cannot process rev $rev: Directory $OUTPUT_DIR/$rev exists"
#  echo "$(warn) To run the analysis on this rev, delete existing directory"
#  exit 1
#fi


##  Create and/or go into output directory
if [[ ! -d $OUTPUT_DIR/$rev ]] ; then mkdir -p $OUTPUT_DIR/$rev ; fi
cd $OUTPUT_DIR/$rev


##  Make scw list for the revolution
echo "$(log) Preparing list of swcIDs"

#  Step 1) Use point.lis (updated daily) to create a file called scwIDs.dat
${PIPELINE_DIR}/makeListOfScwIDsForThisRev.sh $rev ${OSA_DIR}/point.lis

####  Testing
  head -20 scwIDs.dat | tail -3 > tmp
  mv tmp scwIDs.dat
####  Testing END

#  Step 2) Generate scw.lis from rev.lis (must specify Java heap size)
$HOME/jdk/bin/java -Xms100m -Xmx100m -jar $HOME/integral/bin/MakeScwlisFromFile.jar scwIDs.dat
cp scw.lis scw-all.lis
echo "$(log) Copied scw.lis to scw-all.lis"


##  Define OSA environment
echo "$(log) Setting OSA environment variables"
. ${PIPELINE_DIR}/osa.setenv.sh


## Loop on all scw in scwIDs.dat
list=tmp.lis

cat scwIDs.dat | while read scwID ; do

  ## Construct scw.lis based on event files
  case $instrument in
    ISGRI)
      ls scw/${rev}/${scwID}.001/isgri_events.fits.gz | sed s/"isgri_events.fits.gz"/"swg.fits\[1\]"/g > $list
      cat $list >> scw-isgri_events.lis
      ;;
    JMX1)
      ls scw/${rev}/${scwID}.001/jmx1_events.fits.gz | sed s/"jmx1_events.fits.gz"/"swg.fits\[1\]"/g > $list
      cat $list >> scw-jmx1_events.lis
      ;;
    JMX2)
      ls scw/${rev}/${scwID}.001/jmx2_events.fits.gz | sed s/"jmx2_events.fits.gz"/"swg.fits\[1\]"/g > $list
      cat $list >> scw-jmx2_events.lis
      ;;
    SPI)
      ls scw/${rev}/${scwID}.001/spi_oper.fits.gz | sed s/"spi_oper.fits.gz"/"swg.fits\[1\]"/g > $list
      cat $list >> scw-spi_events.lis
      ;;
  esac
    
  ## There are event files : proceed
  if [ -s $list ] ; then

    ## Check for previous run of og_create
    myobs=${scwID}
    og_file="${PWD}/obs/${myobs}/og_${inst_idx,,}.fits"

    if [[ ! -f ${og_file} ]] ; then
      echo "$(log) Running og_create for ${inst_idx}"
      og_create idxSwg=${list} ogid=${myobs} baseDir="./" instrument=${inst_idx}

      EXIT_STATUS=$?
      if [ $EXIT_STATUS -ne 0 ] ; then
        echo "$(warn) og_create exited with status != 0. Cannot process (skipping) $scwID"
      else
        echo "$(log) Processing $scwID for ${inst_idx} ..."

        ##  Change to directory for that scwID
        cd ${REP_BASE_PROD}/obs/${myobs}
        scw="${PWD##*/}.001"

        case $instrument in

          ISGRI)

            ##  This hidden option makes a residual map where both sources and ghosts are removed
            #echo "8" > ii_skyimage.hidden

            ##  Run OSA processing
            ${PIPELINE_DIR}/${processing} $band

            ##  Make event lists from PIFs for sources detected above 3 sigma
            #${PIPELINE_DIR}/ii_pif.sh

            ##  Make high resolution time series
            #${PIPELINE_DIR}/ii_light.sh

            ##  Remove the copy of the general catalog and compress the files
            /bin/rm GNRL-*.fits
            #gzip scw/*/*.fits
            ;;

          JMX1|JMX2)

            ${PIPELINE_DIR}/${processing} $band 
            ;;

          SPI)

            ##  Copy the SPI master catalog here
            cp ${OSA_DIR}/spi_cat_all_sources.fits .

            ##  Run the binning
            ${PIPELINE_DIR}/${processing} $band 
            ;;

        esac
        echo "$(log) Done ${instrument} processing of scw ${scwID}"
      fi
    else
      echo "$(log) File ${og_file} exists. Skipping scw $scwID."
    fi

  ## No event files
  else
    echo "$(warn) No ${instrument} event files. Skipping scw $scwID."
    echo $scwID >> ${REP_BASE_PROD}/scw-no_${instrument}_events.lis
    sort -u ${REP_BASE_PROD}/scw-no_${instrument}_events.lis > tmp
    mv tmp ${REP_BASE_PROD}/scw-no_${instrument}_events.lis
  fi
    
  ## Go back to baseDir and continue to the next scw
  cd ${REP_BASE_PROD}

done


##  Merge all of the time series from ii_light
#. ${PIPELINE_DIR}/merge_ii_light.sh


##  Delete links and pfiles in working dir
. ${BIN_DIR}/rmlinks


## Update the image count in nImages.txt
case ${instrument} in
  ISGRI)
    n=$(ls -1 obs/*/scw/*/isgri_sky_ima.fits* | cat -n | tail -1 | awk '{print $1}')
    echo $n > nImages_${instrument,,}.txt
    ;;
  JMX1)
    n=$(ls -1 obs/*/scw/*/jmx1_sky_ima.fits* | cat -n | tail -1 | awk '{print $1}')
    echo $n > nImages_${instrument,,}.txt
    ;;
  JMX2)
    n=$(ls -1 obs/*/scw/*/jmx2_sky_ima.fits* | cat -n | tail -1 | awk '{print $1}')
    echo $n > nImages_${instrument,,}.txt
    ;;
  SPI)
    n=$(ls -1 obs/*/scw/*/evts_det_spec.fits* | cat -n | tail -1 | awk '{print $1}')
    echo $n > nImages_${instrument,,}.txt
    ;;
esac
cd ${PIPELINE_DIR}


##  Conclude
echo "$(log) Finished processing rev $rev"
endTime=$(date +%s)
time=$(${CALC} $endTime - $startTime)
processingTime=$(${CALC} $time/3660)
roundedTime=$(${CALC} int\($processingTime\))

if [[ ${roundedTime} -eq 0 ]] ; then
  processingTime=$(${CALC} $time*60)
  echo "$(log) Processing time was $processingTime minutes"
else
  echo "$(log) Processing time was $processingTime hours"
fi
