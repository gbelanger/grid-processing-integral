#! /bin/bash


if [[ $# -ne 3 ]] ; then
  echo "Usage: . coords2scwLists.sh fk5Coords.txt offAxisDist outputDir"
  return 1
fi
coordsFile=$1
dist=$2
outDir=$3

#  Set up loging functions
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

# Check input file
if [[ ! -s $coordsFile ]] ; then
  echo "`log` Input file $file is empty"
  return 1
fi
cp -f $HOME/integral/osa_support/point.lis .

# Define calc.pl format
CALCFORMAT=%.0f

# Define Java executable
home="/home/int/intportalowner"
JAVA_HOME="${home}/jdk"
JAVA="${JAVA_HOME}/bin/java -Xms256m -Xmx256m"

# Make the lists
i=1
cat $coordsFile | while read ra dec ; do
  ${JAVA} -jar $HOME/integral/bin/MakeScwList.jar $ra $dec $dist scw.lis
  if [[ -s scw.lis ]] ; then 
    max=250
    max=100000
    nScw=`wc scw.lis | awk '{print $1}'`
    echo "`log` scw.lis has $nScw lines"
    nScwPerGrp=$nScw
    nGrps=1
    if [[ $nScw -gt $max ]] ; then
      while [[ $nScwPerGrp -gt $max ]] ; do
	nGrps=$((nGrps+1))
 	nScwPerGrp=`calc.pl int\($nScw/$nGrps\)+1`
      done
      echo "`log` Nominal scws per group is $nScwPerGrp:"
      j=1
      n=`calc.pl $nScwPerGrp*$j`
      head -$n scw.lis > $outDir/scw_pt${i}.${j}_${ra}_${dec}_${dist}deg.lis
      r=`calc.pl $nScw - $n`
      echo "`log`  Grp $j: $n (remainder=$r)"
      while [[ $r -ge $nScwPerGrp ]] ; do
        j=$((j+1))
        n=`calc.pl $nScwPerGrp*$j`
        head -$n scw.lis | tail -$nScwPerGrp > $outDir/scw_pt${i}.${j}_${ra}_${dec}_${dist}deg.lis
        r=`calc.pl $nScw - $n`
        echo "`log`  Grp $j: $nScwPerGrp (remainder=$r)"
      done
      if [[ "$r" -gt "0" ]] ; then
        j=$((j+1))
        echo "`log`  Grp $j: $r (last group)"
        tail -$r scw.lis >> $outDir/scw_pt${i}.${j}_${ra}_${dec}_${dist}deg.lis
      fi
      # Check total number of lines match original scw.lis
      sumOfLines=`cat -n $outDir/scw_pt${i}.* | tail -1 | awk '{print $1}'`
      echo "`log` scw.lis has $nScw line and the sum of subgroups has $sumOfLines lines"
      if [ $nScw -eq $sumOfLines ] ; then
	 rm scw.lis
      else
	 echo "`log` There is a discrepency: aborting process"
   	 return 1
      fi
      # This will happen whenever there are more than $max but less them 2*$max
      if [[ "$j" -eq "1" ]] ; then
          mv $outDir/scw_pt${i}.${j}_${ra}_${dec}_${dist}deg.lis $outDir/scw_pt${i}_${ra}_${dec}_${dist}deg.lis
      fi      
    else
      mv scw.lis $outDir/scw_pt${i}_${ra}_${dec}_${dist}deg.lis
    fi
  else
    rm scw.lis
    echo "`log` No scw for grid point at (fk5) $ra, $dec"
  fi
  i=$((i+1))
done
/bin/rm point.lis
