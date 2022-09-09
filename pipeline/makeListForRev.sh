#!/bin/bash

#
# Last modified by
#
# G.Belanger (September 2015)
#
# G.Belanger (Jan 2016)
#  - added properly time-stamped logging

log(){
local progName="makeListForRev.sh"
date=`date +"%d-%m-%Y %H:%M:%S"`
log="[INFO] - $date - ($progName) : "
echo $log
}

warn(){
local progName="makeListForRev.sh"
date=`date +"%d-%m-%Y %H:%M:%S"`
warn="[WARN] - $date - ($progName) : "
echo $warn
}

if [ $# != 2 ]
then
    echo "Usage: ./makeListForRev.sh rev path/to/point.lis"
    exit -1
fi
rev=$1
pointlis=$2

output=scwIDs.dat
if [ -f $output ]
then
    echo "`log` rm $output"
    /bin/rm $output
    echo "`log` touch $output"
    touch $output
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
echo "`log` File $output is ready"
/bin/rm -f temp?.lis
