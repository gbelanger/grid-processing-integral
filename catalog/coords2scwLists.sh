#! /bin/bash


##  Set up loging functions
log(){
  progName="coords2scwLists.sh"
  date=`date +"%d-%m-%Y %H:%M:%S"`
  log="[INFO] - $date - ($progName) : "
  echo $log
}

warn(){
  progName="coords2scwLists.sh"
  date=`date +"%d-%m-%Y %H:%M:%S"`
  warn="[WARN] - $date - ($progName) : "
  echo $warn
}


if [[ $# -ne 3 ]] ; then
  echo "Usage: . coords2scwLists.sh fk5Coords.txt offAxisDist outputDir"
  return 1
fi
coordsFile=$1
dist=$2
outDir=$3


##  Check input file
if [[ ! -s $coordsFile ]] ; then
  echo "$(warn) Input file is empty: $file"
  return 1
fi
cp -f $HOME/integral/osa_support/point.lis .


##  Check output directory
if [[ ! -d $outDir ]] ; then
  mkdir $outDir
fi


##  Define executables and variables
home="/home/int/intportalowner"
BIN_DIR=${home}/bin
CALC=${BIN_DIR}/calc.pl
CALCFORMAT=%.0f
JAVA_HOME="${home}/jdk"
JAVA="${JAVA_HOME}/bin/java -Xms256m -Xmx256m"


##  Make the lists
i=1
cat $coordsFile | while read ra dec ; do

  ##  Make the list of scw
  ${JAVA} -jar $HOME/integral/bin/MakeScwList.jar $ra $dec $dist scw.lis

  ##  If list has size
  if [[ -s scw.lis ]] ; then
   nScw=$(wc -l < scw.lis)
   echo "$(log) scw.lis has $nScw lines"

   ##  Define start group size
   nScwPerGrp=$nScw
   nGrps=1
   nCats=2
   max=$(${CALC} nint\($nScw/$nCats\))

   while [[ $max -ge 4 ]] ; do 

    if [[ $nScw -gt $max ]] ; then
      while [[ $nScwPerGrp -gt $max ]] ; do
	nGrps=$((nGrps+1))
 	nScwPerGrp=$(${CALC} int\($nScw/$nGrps\))
      done
      echo "$(log) Nominal scws per group is $nScwPerGrp:"

      j=1
      n=$(${CALC} $nScwPerGrp*$j)
      head -$n scw.lis > $outDir/scw_pt${i}.${j}_${ra}_${dec}_${dist}deg.lis
      r=$(${CALC} $nScw - $n)
      echo "$(log)  Grp $j: $n (remainder=$r)"

      while [[ $r -ge $nScwPerGrp ]] ; do
        j=$((j+1))
        n=$(${CALC} $nScwPerGrp*$j)
        head -$n scw.lis | tail -$nScwPerGrp > $outDir/scw_pt${i}.${j}_${ra}_${dec}_${dist}deg.lis
        r=$(${CALC} $nScw - $n)
        echo "$(log)  Grp $j: $nScwPerGrp (remainder=$r)"
      done

      if [[ "$r" -gt "0" ]] ; then
        j=$((j+1))
        echo "$(log)  Grp $j: $r (last group)"
        tail -$r scw.lis >> $outDir/scw_pt${i}.${j}_${ra}_${dec}_${dist}deg.lis
      fi

      # Check total number of lines match original scw.lis
      sumOfLines=$(cat -n $outDir/scw_pt${i}.* | tail -1 | awk '{print $1}')
      echo "$(log) scw.lis has $nScw line and the sum of subgroups has $sumOfLines lines"
      if [ $nScw -eq $sumOfLines ] ; then
	 echo "$(log) All scws have been used. Iterative to next level."
      else
	 echo "$(log) There is a discrepency: aborting process"
   	 exit -1
      fi

      # This will happen whenever there are more than $max but less them 2*$max
      if [[ "$j" -eq "1" ]] ; then
          mv $outDir/scw_pt${i}.${j}_${ra}_${dec}_${dist}deg.lis $outDir/scw_pt${i}_${ra}_${dec}_${dist}deg.lis
      fi      

    else
      mv scw.lis $outDir/scw_pt${i}_${ra}_${dec}_${dist}deg.lis
    fi

    ##  Double the number of cats and update max
    nCats=$(${CALC} $nCats*2)
    max=$(${CALC} int\($nScw/$nCats\))
    
   done

  else
    rm scw.lis
    echo "$(log) No scw for grid point at (fk5) $ra, $dec"
  fi

  ##  Continue to next ra dec
  i=$((i+1))

done
/bin/rm point.lis
