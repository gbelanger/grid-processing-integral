#! /bin/bash

/bin/rm ao*-all_revs.txt

aoStart="26 143 287 469 591 713 856 1003 1125 1247"
aoStop="142 286 468 590 712 855 1002 1124 1246 1368"

aoNum=1
for startRev in $aoStart ; do
  stopRev=`echo $aoStop | cut -d" " -f$aoNum`
  . printRevs.sh $startRev $stopRev > ao${aoNum}-all_revs.txt
  aoNum=$((aoNum+1))
done
