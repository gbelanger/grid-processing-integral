#!/bin/bash

#
# This script processes a list of observations on the Grid.
#
# Last modified by 
#
# D.Tapiador (Apr 2007)
# G.Belanger (June 2009)
# G.Belanger (Aug 2012)
# G.Belanger (July 2014) 
#  - added arguments emin emax
#
# G.Belanger (Sept 2014)
#  - modified to follow style of the other scripts
#  - use only the band as argument instead of (emin, emax, storageDir)
#  - make overwrite argument mandatory to have a single call to launch_single_rev.sh
#
# G.Belanger (Jan 2016)
#  - added properly time-stamped logging
#
# G.Belanger (Mar 2019)
#  - Updated the logging functions 
#  - Updated to using $() instead of ` `
#
# G.Belanger (Mar 2022)
#  - added support for JEMX imaging analysis
#  - improved formatting/syntax
#
# G.Belanger (Sep 2022)
#  - Updated script to take argument of processing as required by updated launch_single_rev.sh
#


##  Define logging functions
log(){
    local progName="launch_many_rev.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - $date - ($progName) : "
    echo $log
    unset progName
}
warn(){
    local progName="launch_many_rev.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    warn="[WARN] - $date - ($progName) : "
    echo $warn
    unset progName
}
error(){
    local progName="launch_many_rev.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[ERROR] - ${date} - (${progName}) : "
    echo $log
    unset progName
}


##  Check arguments
if [[ $# -lt 5 ]]
then
  echo "Usage: ./launch_many_revs.sh revList (rev.lis) processing (e.g., ibis_analysis_IMA.sh) instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82) overwrite (y|n)"
  exit -1
fi
revList="$1"
processing="$2"
instrument="$3"
band="$4"
overwrite="$5"


##  Submit
echo "$(log) Submitting jobs..."
command=". $HOME/integral/pipeline/launch_single_rev.sh"

for rev in $(cat $revList) ; do

  ##  Check number of running jobs: must be less than 2000
  nJobs=$(qstat -u intportalowner | cat -n | tail -1 | awk '{print $1}')
  while [[ $nJobs -gt 1999 ]] ; do
    sleep 30
    nJobs=$(qstat -u intportalowner | cat -n | tail -1 | awk '{print $1}')
  done

  ##  Submit job
  echo "$(log) Launching ${processing} of revolution ${rev} and band ${band} (${instrument})"
  bash -c "${command} ${processing} ${rev} ${instrument} ${band} ${overwrite}"

done
echo $(log)


## Clean up empty error log files
launchDir="/home/int/intportalowner/integral/pipeline"
cd ${launchDir}/logs/error/
for file in run_integ_analysis.*.*.err
do
  if [ ! -s $file ]
  then
    rm $file
  fi
done
cd ../../
