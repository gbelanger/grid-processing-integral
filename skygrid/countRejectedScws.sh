#!/bin/bash

if [ $# -gt 0 ]
then
  logs=$1
else
  logs=logs
fi

source /home/int/intportalowner/integral/config/grid.setenv.sh

log="[INFO] countRejected.sh -"
echo "$log Counting in $logs ..."
egrep non-NaN ${SKYGRID_DIR}/$logs/output/* | egrep rejected | awk '{print $9, $11}' > rejSel
rej=`${BIN_DIR}/sum.sh rejSel 1`
sel=`${BIN_DIR}/sum.sh rejSel 2`
tot=`${CALC} $rej+$sel`
percentRej=`${CALC} 100*$rej/$tot`
percentSel=`${CALC} 100*$sel/$tot`
echo "$log Total: $tot"
echo "$log Selected: $sel ($percentSel %)"
echo "$log Rejected: $rej ($percentRej %)"
rm rejSel
