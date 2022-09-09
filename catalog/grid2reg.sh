#!/bin/bash

if [ $# -ne 4 ] ; then
  echo "Usage: ./grid2reg.sh gridPts.txt dx dy coordSys (galactic|fk5)"
  exit
fi
file=$1
dx=$2
dy=$3
sys=$4

# Write header
out=`echo $file | sed s/".txt"/".reg"/g`
echo "# Region file format: DS9 version 4.1" > $out
echo "global color=cyan dashlist=8 3 width=1 font=\"helvetica 10 normal roman\" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1" >> $out
echo "$sys" >> $out 

# Calculate sides of the box region
xsize=`calc.pl $dx*3600`
ysize=`calc.pl $dy*3600`

count=1
cat $file | while read x y ; do
#  echo "box($x,$y,$xsize\",$ysize\",0) # text={$count}" >> $out
  echo "box($x,$y,$xsize\",$ysize\",0) # text={}" >> $out
  count=$((count+1))
done
