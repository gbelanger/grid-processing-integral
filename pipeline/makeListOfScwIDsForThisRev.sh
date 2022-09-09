#!/bin/bash

#
# Last modified by
#
# G.Belanger (Jan 2016)
#

if [ $# != 2 ]
then
    echo "Usage: ./makeListOfScwIDsForThisRev.sh rev path/to/point.lis"
    exit -1
fi
rev=$1
pointlis=$2

#  Set up loging functions
log(){
local progName="makeListOfScwIDsForThisRev.sh"
date=`date +"%d-%m-%Y %H:%M:%S"`
log="[INFO] - $date - ($progName) : "
echo $log
unset progName
}

warn(){
local progName="makeListOfScwIDsForThisRev.sh"
date=`date +"%d-%m-%Y %H:%M:%S"`
warn="[WARN] - $date - ($progName) : "
echo $warn
unset progName
}

# Check existing file is deleted
output=scwIDs.dat
if [ -f $output ]
then
    /bin/rm $output
fi

# Get all scwIDs that contain the rev number
awk '{print $1}' $pointlis > temp1.lis
egrep $rev temp1.lis | sort > temp2.lis

# Refine to take scw IDs of only this rev 
for scwid in `cat temp2.lis`
do
  revNum=`echo $scwid | awk '{print substr($1,0,4)}'`
  if [ "$revNum" == "$rev" ]
  then
      echo $scwid >> $output
  fi
done
sort -gu $output > tmp
mv tmp $output
echo "$(log) File $output is ready"
/bin/rm -f temp?.lis

