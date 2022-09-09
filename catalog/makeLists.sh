#!/bin/bash

if [ $# -lt 3 ]
then
  echo "Usage: . makeLists.sh xStep yStep dist"
  return 1
fi

# This script:
#
# 1) Creates a list of grid point coordinates distributed 
#    over the whole sky in a grid defined according to the 
#    grid steps, xStep and yStep (arguments 1 and 2), that 
#    are passed to the script getGridPoints.sh
#
# 2) Generates a scw.lis for each grid point coord in using 
#    all the pointings available in the general index of scw
#    and, for IBIS/ISGRI, within the degrees from the pointing 
#    axis, dist (argument 3), that is passed to the script
#    coords2scwLists.sh.
#
# These list of scw will be used to make mosaics centred on
# each of the grid points (in order to maximise sensitivity on 
# each field defined by these grid points and the off-axis
# dist). 
#
# For IBIS/ISGRI, with a FCFOV of 8x8 and PCFOV of 29x29, we 
# can take 11 degrees off-axis distance (dist), and 12 degrees 
# b/w grid points (xStep=yStep=12) that makes for considerable 
# overalp between the scws of adjacent grid points. Nonetheless, 
# this ensures max sensitivity at the centre of each grid point,
# and therefore for every source in the sky, no matter where
# it is located.
#
# In the case for ISGRI, we gain in significance only
# up to 11 degrees from the pointing axis. For JEM-X the 
# grid step and off-axis distance would have to be smaller.

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
xStep=$1
yStep=$2
dist=$3

# Define the points on the grid in Galactic coordinates
echo "`log` Defining grid points in Galactic coordinates"
gridFile="gridPoints_${xStep}_${yStep}_gal.txt"
. getGridPoints.sh $xStep $yStep > $gridFile
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
outputDir="scwLists_${xStep}x${yStep}dist${dist}deg"
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
