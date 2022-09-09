#! /bin/bash

#set -e

CALCFORMAT=%.0f

if [[ $# -ne 6 ]] ; then
  echo "Usage: . getGridPoints.sh from_l to_l from_b to_b dx dy (deg)"
  return 1
fi

# Longitude
from_l=$1
to_l=$2
if [[ $from_l -ge $to_l ]] ; then
  echo "Error: from_l must be less than to_l"
  return 1
fi

# Latitude
from_b=$3
to_b=$4
if [[ $from_b -ge $to_b ]] ; then
  echo "Error: from_b must be less than to_b"
  return 1
fi

# Step
dx=$5
dy=$6

# Define range in l and in b
l_range=`calc.pl $to_l - $from_l`
b_range=`calc.pl $to_b - $from_b`

export CALCFORMAT=%.6g
nX=`calc.pl int\($l_range/$dx\)`
nY=`calc.pl int\($b_range/$dy\)`

xOffset=`calc.pl $dx/2`
yOffset=`calc.pl $dy/2`

#  Start in the lower right corner
xStart=`calc.pl $from_l + $xOffset`
yStart=`calc.pl $from_b + $yOffset`

y=$yStart
yIdx=0
while [[ $yIdx -lt $nY ]] ; do
  x=$xStart
  xIdx=0
  while [[ $xIdx -lt $nX ]] ; do
    echo "$x $y"
    x=`calc.pl $x + $dx`
    xIdx=$((xIdx+1))
  done
  y=`calc.pl $y + $dy`
  yIdx=$((yIdx+1))
done
