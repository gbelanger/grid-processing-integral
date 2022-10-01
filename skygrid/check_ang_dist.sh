#!/bin/bash

if [[ $# -ne 1 ]] ; then
  echo "Usage: ./check_ang_dist.sh fk5.txt"
  exit 0
fi
infile=$1

n=$(wc -l < $infile)
k=2
while [[ $k -le $n ]] ; do
  head -$k $infile | tail -2 > pair
  radec1=$(head -1 pair)
  radec2=$(tail -1 pair)
  ra1=$(echo $radec1 | awk '{print $1}')
  dec1=$(echo $radec1 | awk '{print $2}')
  ra2=$(echo $radec2 | awk '{print $1}')
  dec2=$(echo $radec2 | awk '{print $2}')
  java -jar ~/bin/GetAngularDist.jar $ra1 $dec1 $ra2 $dec2
  k=$((k+2))
done
