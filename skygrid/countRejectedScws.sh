#!/bin/bash

if [ $# -gt 0 ]
then
  logs=$1
else
  logs=logs
fi

skygrid=$HOME/integral/skygrid/
log="[INFO] countRejected.sh -"
echo "$log Counting in $logs ..."
#egrep non-NaN $skygrid/$logs/output/* | egrep rejected 
egrep non-NaN $skygrid/$logs/output/* | egrep rejected | awk '{print $9, $11}' > rejSel
rej=`~/bin/sum.sh rejSel 1`
sel=`~/bin/sum.sh rejSel 2`
tot=`calc.pl $rej+$sel`
percentRej=`calc.pl 100*$rej/$tot`
percentSel=`calc.pl 100*$sel/$tot`
echo "$log Total: $tot"
echo "$log Selected: $sel ($percentSel %)"
echo "$log Rejected: $rej ($percentRej %)"
rm rejSel
