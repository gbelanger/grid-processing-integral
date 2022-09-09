#!/usr/bin/env bash
#set -o errexit  # exit when a command fails
#set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)

# Last update
# G.Belanger (Jan 2019)
# - Updated to OSA 11
# - Changed the bands
# - Updated syntax for executing commands from `cmd` to $(cmd)

source $HOME/.bash_profile
/home/int/intportalowner/env.sh 


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

##  Define variables
ISOC5="/data/int/isoc5/gbelange/isocArchive"
dataDir="/data/int/isda004/rev_3/scw"
scwDir="${ISOC5}/ibis/scw_20-35"

# Determine the most recent rev for which there is data
cd $dataDir
mostRecentDataRev=$(ls -1d [0-9][0-9][0-9][0-9]/rev.001 | tail -1 | cut -d"/" -f1)

# Determine the last rev that was analysed
cd $scwDir
lastRevProcessed=$(ls -1d [0-9][0-9][0-9][0-9] | tail -1)
nImages=$(cat $lastRevProcessed/nImages.txt)
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
pipelineDir=$HOME/integral/pipeline
cd $pipelineDir
if [[ $lastRevProcessed -lt $mostRecentDataRev ]] ; then
    echo "$(log) New data available: Processing ..."
    startRev=$((lastRevProcessed+1))
    ./printGoodRevs.sh $startRev $mostRecentDataRev
    ./launch_many_revs.sh revs.lis ISGRI 20-80 y
    ./launch_many_revs.sh revs.lis ISGRI 20-35 y
    ./launch_many_revs.sh revs.lis ISGRI 35-60 y
    ./launch_many_revs.sh revs.lis ISGRI 60-100 y
    /bin/rm revs.lis
else
    echo "$(log) No new data: Nothing to process"
fi
echo
