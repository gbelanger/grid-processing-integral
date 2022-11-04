#!/usr/bin/env bash

#set -o errexit # exit when a command fails
#set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)

# Modification History:
#
# D.Tapiador (Apr 2007)
# G.Belanger (June 2009)
# G.Belanger (Aug 2012)
# G.Belanger (July 2014) 
#  - added arguments emin emax
# G.Belanger (Sept 2014)
#  - combined emin and emax into band (20-35)
#  - removed the storageDir argument
# G.Belanger (Aug 2015)
#  - added conditionals for defining directory paths
#    depending on host (intggw or intggw6)
# G.Belanger (Sept 2015)
#  - added checking of arguments
#  - added automatic exclusion of revs in rev_toExclude.txt
# G.Belanger (Jan 2016)
#  - added properly time-stamped logging
# G.Belanger (July 2017)
#  - allowed for more bands: 
#   20-40, 40-60, 60-100; in addition to 20-35, 35-65, 65-100
# G.Belanger (Sep 2018)
#  - added full path to revs_toExclude.dat
#  - added nanosecond-precision time stamp to tmp files to avoid
#    problems between jobs writing to the same file.
# G.Belanger (Jan 2019)
#  - updated accepted energy bands
# G.Belanger (Aug 2020)
#  - minor syntax updates
#  - changed log files to be in each rev dir
# G.Belanger (Mar 2022)
#  - added support for JEMX imaging analysis
#  - improved formatting/syntax
# G.Belanger (Aug 2022)
#  - added support for SPI binning analysis
# G.Belanger (Oct 2022)
#  - using common variables from config/grid.setenv.sh
#  - using USER variable for output directory
#


##  Define logging functions
log(){
    local progName="launch_single_rev.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - $date - ($progName) : "
    echo $log
    unset progName
}
warn(){
    local progName="launch_single_rev.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    warn="[WARN] - $date - ($progName) : "
    echo $warn
    unset progName
}
error(){
    local progName="launch_single_rev.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[ERROR] - ${date} - (${progName}) : "
    echo $log
    unset progName
}


## Check arguments
if [[ $# -ne 5 ]] 
then
  echo "Usage: ./launch_single_rev.sh  processing (ibis_analysis_IMA.sh) rev (e.g., 0053|1630) instrument (ISGRI|JMX1|JMX2|SPI) band (e.g., 20-35|46-82|25-400) overwrite (y|n)"
  exit 1
fi


##  Time stamp
time=$(date +%N)
tmp=/tmp/tmp_${time}


## Read arguments
processing=$1
rev=$2
instrument=$3
band=$4
emin=$(echo $band | cut -d"-" -f1)
emax=$(echo $band | cut -d"-" -f2)
overwrite=$5


##  Define common varibales
source /home/int/intportalowner/integral/config/grid.setenv.sh


##  Check rev exclude list
egrep $rev ${PIPELINE_DIR}/revs_toExclude.dat > $tmp
if [ -s $tmp ] ; then
  echo "$(warn) Revolution $rev is in the excluded list: No processing necessary"
  /bin/rm $tmp
  exit 1
else
  /bin/rm $tmp
fi


##  Check instrument
case $instrument in
  ISGRI | IBIS)
    inst_idx="IBIS";
    inst_dir="ibis";
    ;;
  JMX1 | JMX2) 
    inst_dir="jmx";
    inst_idx="$instrument";
    if [[ "$band" != "46-82" && "$band" != "83-153" && "$band" != "154-224" ]]
    then
      echo "$(error) ${instrument} band must be 46-82|83-153|154-224"
      exit 1
    fi
    ;;
  SPI)
    inst_dir="spi";
    inst_idx="$instrument"
    ;;
  *)
    echo "$(error) Unknown instrument : $instrument. Choices are IBIS|JMX1|JMX2|SPI.";
    exit 1;
    ;;
esac


##  Define root output directory
export OUTPUT_DIR="${ISOC5}/${inst_dir}/scw_${band}"
if [ ! -d $OUTPUT_DIR ] ; then mkdir -p $OUTPUT_DIR ; fi


##  Define the directory for the revolution
export dir="${OUTPUT_DIR}/${rev}"
if [[ "$overwrite" == "y" ]] ; then
  if [ -d $dir ] ; then
    echo "$(warn) Deleting $dir ..."
    chmod -fR 755 $dir
    /bin/rm -fr $dir
  fi
elif [[ "$overwrite" == "n" ]] ; then
  echo "$(log) Dir $dir will not be overwritten"
else
  echo "$(log) Overwrite argument must be y or n"
  exit 1
fi


## Submit job
echo "$(log) Submitting job to process revolution $rev ($instrument)"


#  Define output and error log files
LOG_DIR=${ISOC5}/logs
if [[ ! -d $LOG_DIR ]] ; then 
  mkdir -p $LOG_DIR/error
  mkdir -p $LOG_DIR/output
fi

o="${LOG_DIR}/output/run_integ_analysis.${instrument,,}.${band}.${rev}.out"
e="${LOG_DIR}/error/run_integ_analysis.${instrument,,}.${band}.${rev}.err"


#  Define qsub command
qsub="/opt/univa/ROOT/bin/lx-amd64/qsub -cwd -pe make 5 -l h_vmem=10G -S /bin/bash -q int.q"
#qsub="/opt/univa/ROOT/bin/lx-amd64/qsub -cwd -pe make 5 -l h_vmem=10G -S /bin/bash -q all.q"


#if [[ $USER = "dev01" ]] || [[ $USER = "dev02"]] ; then
#  qsub="${qsub} -wd /data/int/isoc5/$USER/isocArchive"
#fi


#  Submit the job
${qsub} -e ${e} -o ${o} ${PIPELINE_DIR}/run_integ_analysis.sh $processing $rev $instrument $band


#  Run locally (for testing)
#. run_integ_analysis.sh $processing $rev $instrument $band
