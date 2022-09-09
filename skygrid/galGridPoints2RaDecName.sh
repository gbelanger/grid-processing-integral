
if [ $# -ne 1 ] ; then
  echo "Usage: ./galGridPoints2RaDecName.sh gridPoints_gal.txt"
  return 1
fi

export CALCFORMAT=%.4f

rm ra_dec_name.txt ;
java -jar -Xmx1g -Xms1g ~/bin/Gal2fk5.jar $1 ;
i=1 ; 
cat fk5Coords.txt | while read ra dec ; do 
  r=`calc.pl $ra +0` ; 
  d=`calc.pl $dec +0` ; 
  name=galGrid_pt_${i}_radec_${r}_${d}
  echo $r $d $name >> ra_dec_name.txt ; 
  i=$((i+1)) ; 
done
rm fk5Coords.txt
echo "File is ready: ra_dec_name.txt"
