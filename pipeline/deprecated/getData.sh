#! /bin/bash

if [[ $# -ne 1 ]] ; then
 echo "Usage: getData.sh scw.lis"
 return -1
fi
list=$1

echo "Getting data from locally mounted disk"
if [[ -d scw ]] ; then chmod -fR 755 scw ; /bin/rm -rf scw ; fi
if [[ -d aux ]] ; then chmod -fR 755 aux ; /bin/rm -rf aux ; fi
mkdir scw
mkdir -p aux/adp

data_path=/isda004/rev_3-temp

rev=""
startTime=`date +%s`
cat $list | while read path ; do
  previousRev=$rev
  rev=`echo $path | awk '{print substr($1,5,4)}'`
  id=`echo $path | awk '{print substr($1,10,12)}'`
  if [[ ! -d scw/${rev} ]] ; then mkdir -p scw/${rev} ; fi
  if [[ "$rev" == "$previousRev" ]] ; then
    echo "Getting scwID $id"
    cp -fr $data_path/scw/${rev}/${id}.001 scw/${rev}/
  else
    echo "Getting aux for rev $rev"
    cp -fr $data_path/scw/${rev}/rev.001 scw/${rev}/
    cp -fr $data_path/aux/adp/${rev}.001 aux/adp/
    cp -fr $data_path/aux/adp/ref aux/adp/

    echo "Getting scwID $id"
    cp -fr $data_path/scw/${rev}/${id}.001 scw/${rev}/
  fi
done
endTime=`date +%s`
downloadTime=$(($endTime-$startTime))
#echo "Download time (cp from /isda) = $downloadTime s" >> downloadTime.txt
