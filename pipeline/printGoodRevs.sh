#!/bin/bash
/home/int/intportalowner/env.sh
if [[ $# -ne 2 ]]
then
  echo "Usage: printGoodRevs.sh first last (outputs to revs-first-last.lis)"
  exit -1
fi

i=$1
while [[ $i -le $2 ]]
do
  if [[ $i -lt 100 ]]
  then
    echo "00$i" >> revs
  elif [[ $i -lt 1000 ]]
  then
    echo "0$i" >> revs
  else
    echo $i >> revs
  fi
  i=$((i+1))
done

for rev in `cat revs_toExclude.dat` ; do 
  egrep -v $rev revs > tmp ; 
  /bin/mv tmp revs ; 
done
sort -g revs > revs-$1-$2.lis
/bin/rm revs
