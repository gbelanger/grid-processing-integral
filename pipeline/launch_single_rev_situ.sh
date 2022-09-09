#!/usr/bin/env bash

#set -o errexit # exit when a command fails
#set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)

export HOME="/home/int/intportalowner"
export ISOC_DIR="/data/int/isoc5/gbelange/isocArchive"

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

# Define my standard environment variables
#/home/int/intportalowner/env.sh

# Check arguments
if [[ $# -ne 4 ]] 
then
  echo "Usage: ./launch_single_rev.sh revID (e.g., 0053|1630) instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82) overwrite (y|n)"
  exit 1
fi

##  Time stamp
time=$(date +%N)
tmp=$HOME/integral/pipeline/tmp_${time}

## Define revolution number
rev="$1"

##  Check exclude list
egrep $rev $HOME/integral/pipeline/revs_toExclude.dat > $tmp
if [ -s $tmp ] ; then
  echo "$(warn) Revolution $rev is in the excluded list: No processing necessary"
  /bin/rm $tmp
  exit 1
else
  /bin/rm $tmp
fi

##  Define energy band
band="$3"
emin=$(echo $band | cut -d"-" -f1)
emax=$(echo $band | cut -d"-" -f2)

##  Define instrument
instrument="$2"
case $instrument in
  ISGRI | IBIS)
    inst_idx="IBIS";
    inst="ibis";
    #if [[ $band != "20-40" && $band != "20-80" && $band != "40-60" && $band != "20-35" && $band != "35-60" && $band != "60-100" ]]
    #then
    #  echo "$(error) Band can be 20-40, 20-80, 40-60, 20-35, 35-60, 60-100"
    #  exit 1
    #fi
    ;;
  JMX1 | JMX2) 
    inst="jmx";
    inst_idx="$instrument";
    if [[ "$band" != "46-82" && "$band" != "83-153" && "$band" != "154-224" ]]
    then
      echo "$(error) ${instrument} band must be 46-82|83-153|154-224"
      exit 1
    fi
    ;;
  *)
    echo "$(error) Unknown instrument : $instrument. Choices are IBIS|JMX1|JMX2.";
    exit 1;
    ;;
esac

##  Define instrument-specific processing script
processing="${inst_idx,,}_analysis_COR-IMA.sh"

##  Define storage directory based on the band
storageDir="${ISOC_DIR}/${inst}/scw_${band}"
export storageDir
if [ ! -d $storageDir ] ; then mkdir -p $storageDir ; fi

##  Define the directory for the revolution
dir="${storageDir}/${rev}"
export dir
if [[ "$4" == "y" ]]
then
  if [ -d $dir ]
  then
    echo "$(warn) Deleting $dir ..."
    chmod -fR 755 $dir
    /bin/rm -fr $dir
  fi
elif [[ "$4" == "n" ]]
then
  echo "$(log) Dir $dir will not be overwritten"
else
  echo "$(log) Overwrite argument must be y or n"
  exit 1
fi

## Submit job
echo "$(log) Submitting job to process revolution $rev ($instrument)"

## Grid
#qsub="/opt/univa/ROOT/bin/lx-amd64/qsub -cwd -pe make 5 -l h_vmem=10G -S /bin/bash -q int.q"
qsub="/opt/univa/ROOT/bin/lx-amd64/qsub -cwd -pe make 5 -l h_vmem=10G -S /bin/bash -q all.q"

o="${HOME}/integral/pipeline/logs/output/run_integ_analysis.${instrument,,}.${rev}.out"
e="${HOME}/integral/pipeline/logs/error/run_integ_analysis.${instrument,,}.${rev}.err"

#${qsub} -e ${e} -o ${o} ${HOME}/integral/pipeline/run_integ_analysis.sh $processing $rev $instrument $band

## Locally (for testing)
. run_integ_analysis.sh $processing $rev $instrument $band
