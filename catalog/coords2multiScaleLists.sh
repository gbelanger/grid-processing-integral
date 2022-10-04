#! /bin/bash

set -o errexit # exit when a command fails
set -o nounset # exit when your script tries to use undeclared variables
#set -o pipefail # don't hide errors within pipes


# Last modified by 
#
# G.Belanger (Oct 2022)
# - Adapted for catalog production from skygrid/coords2scwLists.sh
#


##  Set up loging functions
log(){
  local progName="coords2multiScaleLists.sh"
  date=`date +"%d-%m-%Y %H:%M:%S"`
  log="[INFO] - $date - ($progName) : "
  echo $log
  unset progName
}

warn(){
  local progName="coords2multiScaleLists.sh"
  date=`date +"%d-%m-%Y %H:%M:%S"`
  warn="[WARN] - $date - ($progName) : "
  echo $warn
  unset progName
}

error(){
  local progName="coords2multiScaleLists.sh"
  date=$(date +"%d-%m-%Y %H:%M:%S")
  error="[ERROR] - $date - ($progName) : "
  echo $error
  unset progName
}

progName="coords2multiScaleLists.sh"

if [[ $# -ne 3 ]] ; then
  echo "Usage: ./$progName fk5Coords.txt offAxisDist outputDir"
  exit 0
fi
coordsFile=$1
dist=$2
outDir=$3


##  Variables
home="/home/int/intportalowner"
INT_DIR="${home}/integral"
BIN_DIR="${home}/bin"
CALC=${BIN_DIR}/calc.pl
CALCFORMAT=%.0f
JAVA_HOME="${home}/jdk"
JAVA="${JAVA_HOME}/bin/java -Xms256m -Xmx256m"


##  Check input file
if [[ ! -s $coordsFile ]] ; then
  echo "$(warn) Input file is empty: $file"
  return 1
fi
cp -f $INT_DIR/osa_support/point.lis .


##  Create output directory
if [[ -d $outDir ]] ; then rm -r $outDir ; fi
mkdir $outDir



##  Make the lists
i=1
cat $coordsFile | while read ra dec ; do

  ##  Make the list of scw
  ${JAVA} -jar ${INT_DIR}/bin/MakeScwList.jar $ra $dec $dist scw.lis

  ##  If list has size
  if [[ -s scw.lis ]] ; then

   nScw=$(wc -l < scw.lis)
   echo "$(log) scw.lis has $nScw lines"

   ##  Define start group size
   nScwPerGrp=$nScw
   nGrps=1
   nCats=2
   max=$(${CALC} nint\($nScw/$nCats\))

   k=1
   while [[ $max -ge 16 ]] ; do 

    if [[ $nScw -gt $max ]] ; then

      while [[ $nScwPerGrp -gt $max ]] ; do
	nGrps=$((nGrps+1))
 	nScwPerGrp=$(${CALC} int\($nScw/$nGrps\))
      done
      echo "$(log) Nominal scws per group is $nScwPerGrp:"

      j=1
      n=$(${CALC} $nScwPerGrp*$j)
      head -$n scw.lis > $outDir/scw_pt${i}.${k}_${ra}_${dec}_${dist}deg.lis
      k=$((k+1))
      r=$(${CALC} $nScw - $n)
      echo "$(log)  Grp $j: $n scw (remainder $r)"

      while [[ $r -ge $nScwPerGrp ]] ; do
        j=$((j+1))
        n=$(${CALC} $nScwPerGrp*$j)
        head -$n scw.lis | tail -$nScwPerGrp > $outDir/scw_pt${i}.${k}_${ra}_${dec}_${dist}deg.lis
        k=$((k+1))
        r=$(${CALC} $nScw - $n)
        echo "$(log)  Grp $j: $nScwPerGrp scw (remainder $r)"
      done

      if [[ "$r" -gt "0" ]] ; then
        j=$((j+1))
        echo "$(log)  Grp $j: $r scw (last group)"
        tail -$r scw.lis >> $outDir/scw_pt${i}.${k}_${ra}_${dec}_${dist}deg.lis
        k=$((k+1))
      fi

      ##  This will happen whenever there are more than $max but less them 2*$max
      if [[ "$j" -eq "1" ]] ; then
        mv $outDir/scw_pt${i}.${k}_${ra}_${dec}_${dist}deg.lis $outDir/scw_pt${i}_${ra}_${dec}_${dist}deg.lis
        k=$((k+1))
      fi      

    else

      mv scw.lis $outDir/scw_pt${k}_${ra}_${dec}_${dist}deg.lis
      k=$((k+1))

    fi

    ##  Double the number of cats and update max
    nCats=$(${CALC} $nCats*2)
    max=$(${CALC} int\($nScw/$nCats\))
    
   done

  else
    rm scw.lis
    echo "$(log) No scw for grid point at (fk5) $ra, $dec"
  fi

  ##  Move to next ra dec in $coordsFile
  i=$((i+1))

done

echo "$(log) Production completed."


##  Make a list of the scw list filenames
listOfLists=${outDir}.filenames
ls -1 $outDir/* > $listOfLists
echo "$(log) Scw lists files are listed in $listOfLists"
n=$(cat -n $outDir/* | tail -1 | awk '{print $1}')
n2=$(cat $outDir/* |sort -u|cat -n | tail -1 | awk '{print $1}')
echo "$(log) Set of lists contains $n pointings ($n2 are distinct)"


##  Clean up
if [[ -f point.lis ]] ; then /bin/rm point.lis ; fi
if [[ -f scw.lis ]] ; then /bin/rm scw.lis ; fi
