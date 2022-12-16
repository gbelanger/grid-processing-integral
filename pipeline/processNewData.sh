#!/usr/bin/env bash
#set -o errexit  # exit when a command fails
#set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)

# Last update
# G.Belanger (Dec 2022)
#  - using common variables config
#  - added spectral bands
#
# G.Belanger (Jan 2019)
# - Updated to OSA 11
# - Changed the bands
# - Updated syntax for executing commands from `cmd` to $(cmd)

#source $HOME/.bash_profile
#/home/int/intportalowner/env.sh 

##  Define program name and logging functions

log(){
    local progName="processNewData.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - $date - ($progName) : "
    echo $log
    unset progName
}
warn(){
    local progName="processNewData.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    warn="[WARN] - $date - ($progName) : "
    echo $warn
    unset progName
}

##  Define common varibales
source /home/int/intportalowner/integral/config/grid.setenv.sh
DATA_PATH="/integral/data/rev_3/scw"

# Determine the most recent rev for which there is data
cd $DATA_PATH
mostRecentDataRev=$(ls -1d [0-9][0-9][0-9][0-9]/rev.001 | tail -1 | cut -d"/" -f1)

# Determine the last rev that was analysed
cd /data/int/isoc5/intportalowner/isocArchive/ibis/scw_20-35
lastRevProcessed=$(ls -1d [0-9][0-9][0-9][0-9] | tail -1)
nImages=$(cat ${lastRevProcessed}/nImages_isgri.txt)
if [[ $nImages -gt 0 ]] ; then
    nEventFiles=$(wc $lastRevProcessed/scw-isgri_events.lis | awk '{print $1}')
    diff=$(calc.pl $nEventFiles - $nImages)
    if [[ $diff -gt 5 ]] ; then
	while [[ $diff -gt 5 ]] ; do
	    lastRevProcessed=$((lastRevProcessed-1))
	    nImages=$(cat $lastRevProcessed/nImages.txt)
	    nEventFiles=$(wc $lastRevProcessed/scw-isgri_events.lis | awk '{print $1}')
	    diff=$(calc.pl $nEventFiles - $nImages)
	done
    fi
fi

# Print revs and launch analysis 
cd $PIPELINE_DIR
if [[ $lastRevProcessed -lt $mostRecentDataRev ]] ; then
  echo "$(log) New data available: Processing ..."
  startRev=$((lastRevProcessed+1))
  lastRev=$mostRecentDataRev
  ./printGoodRevs.sh $startRev $lastRev
  revList="revs-${startRev}-${lastRev}.lis"
  # RGB imaging bands
  ./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 20-35 y
  ./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 35-60 y
  ./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 60-100 y
  # Spectral bands
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 20-30 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 30-40 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 40-50 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 50-60 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 60-80 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 80-100 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 100-150 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 150-200 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 200-300 y
  #./launch_many_revs.sh $revList ibis_analysis_IMA.sh ISGRI 300-500 y
  # cleanup
  /bin/rm $revList
else
    echo "$(log) No new data: Nothing to process"
fi
echo
