#! /bin/bash

CALCFORMAT=%.0f

if [[ $# -ne 2 ]] ; then
  echo "Usage: . getGridPoints.sh dx dy (deg)"
  return 1
fi

dx=$1
dy=$2

nX=`calc.pl int\(360/$dx\) + 1`
nY=`calc.pl int\(180/$dy\) + 1`

# Only one pass along plane
nY=1

xOffset=`calc.pl $dx/2`
yOffset=`calc.pl $dy/2`

xOffset=0
yOffset=0

#  Start on the plane (-180, 0)
xStart=`calc.pl -180 + $xOffset`
yStart=`calc.pl 0 + $yOffset`

y=$yStart
yIdx=0
while (($yIdx < $nY)) ; do

  # Along the plane
  y=0
  x=$xStart
  xIdx=0
  while (($xIdx < $nX)) ; do
    echo "$x $y"
    x=`calc.pl $x + $dx`
    xIdx=$((xIdx+1))
  done

  # Above and below the plane
  xStart=`calc.pl $xStart + \(\($yIdx + 1\)%2\)*$dx/2`
  nX=$(($nX-1))

  # Above the plane
  x=$xStart
  y=`calc.pl $yStart + \($yIdx+1\)*$dy`
  xIdx=0
  while (($xIdx < $nX)) ; do
    echo "$x $y"
    x=`calc.pl $x + $dx`
    xIdx=$((xIdx+1))
  done

  # Below the plane
  x=$xStart
  y=`calc.pl $yStart - \($yIdx+1\)*$dy`
  xIdx=0
  while (($xIdx < $nX)) ; do
    echo "$x $y"
    x=`calc.pl $x + $dx`
    xIdx=$((xIdx+1))
  done

  yIdx=$((yIdx+1))
done
