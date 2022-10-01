#!/bin/bash

if [ $# -lt 2 ]
then
  echo "Usage: ./makeLists.sh step radius"
  exit 0
fi

# This script:
#
# 1) Creates a list of grid point coordinates distributed 
#    over the whole sky in a grid defined according to the 
#    grid step (same in x and y) passed to get-grid-points.py
#
# 2) Generates a scw.lis for each grid point coord in using 
#    the radius (argument 2) from the pointing axis passed to
#    coords2scwLists.sh
##

#  Set up loging functions
log(){
progName="makeLists.sh"
date=`date +"%d-%m-%Y %H:%M:%S"`
log="[INFO] - $date - ($progName) : "
echo $log
}

warn(){
progName="makeLists.sh"
date=`date +"%d-%m-%Y %H:%M:%S"`
warn="[WARN] - $date - ($progName) : "
echo $warn
}

# Variables
step=$1
dist=$2

# Define the points on the grid in Galactic coordinates
echo "`log` Defining grid points in Galactic coordinates"
gridFile="grid-${step}deg-gal.txt"
python get-grid-points.py $step $gridFile
nPts=`wc $gridFile | awk '{print $1}'`
echo "`log` There are $nPts grid points"

# Transform to fk5

# Uncomment later
echo "`log` Transforming to fk5 coordinates"
java -jar ~/bin/Gal2fk5.jar $gridFile
gridFile_fk5=`echo $gridFile | sed s/"gal"/"fk5"/g`
# Keep only 4 decimals
awk '{printf "%.4f %.4f\n", $1, $2}' fk5Coords.txt > tmp 
mv tmp $gridFile_fk5
rm fk5Coords.txt

# Create output directory
outputDir="scw-lists-step-${step}deg-radius-${dist}deg"
if [[ -d $outputDir ]] ; then /bin/rm -r $outputDir ; fi
mkdir $outputDir
echo "`log` Output directory is $outputDir"

# Make the lists of scw
echo "`log` Making lists of scw ..."
logFilename=${outputDir}.log

### This is the workhorse
. coords2scwLists.sh $gridFile_fk5 $dist $outputDir > $logFilename

# Make a list of the scw list filenames
listOfLists=${outputDir}.filenames
ls -1 $outputDir/* > $listOfLists
echo "`log` Scw lists are ready and listed in $listOfLists"
n=`cat -n $outputDir/* | tail -1 | awk '{print $1}'`
n2=`cat $outputDir/* |sort -u|cat -n | tail -1 | awk '{print $1}'`
echo "`log` Set of lists contains $n pointings ($n2 are distinct)"
