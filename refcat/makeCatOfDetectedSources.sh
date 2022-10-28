#!/bin/bash

if [[ $# != 0 ]] ; then
  echo "Usage: ./makeCatOfDetectedSources.sh"
  exit -1
fi


##  Set the OSA environment variables and paths
source /home/int/intportalowner/integral/pipeline/osa.setenv.sh

##  Define reference cat
filename=$(echo $ISDC_REF_CAT | cut -d"[" -f1)
suffix=$(echo $filename | cut -d"_" -f5)
echo "Working with latest OSA reference catalog: $filename"


##  ISGRI
echo "Extracting ISGRI sources"
outfile1=isgri_cat_$suffix
outfile2=isgri_cat_inMosa_$suffix
outfile3=isgri_cat_inScw_$suffix
outfile4=isgri_cat_bright_$suffix
outfile5=isgri_cat_strong_$suffix

ftcopy "$ISDC_REF_CAT[ISGRI_FLAG2 > 0]" !$outfile1
ftcopy "$ISDC_REF_CAT[ISGRI_FLAG2 == 2]" !$outfile2
ftcopy "$ISDC_REF_CAT[ISGRI_FLAG2 == 1]" !$outfile3
ftcopy "$ISDC_REF_CAT[ISGRI_FLAG2 == 5]" !$outfile4
ftcopy "$ISDC_REF_CAT[ISGR_FLUX_1 > 1 || ISGR_FLUX_2 > 1]" !$outfile5


##  SPI and JEM-X
echo "Extracting SPI and JMX sources"

outfile5=spi_cat_$suffix
ftcopy "$ISDC_REF_CAT[SPI_FLAG == 1]" !$outfile5

outfile6=jmx_cat_$suffix
ftcopy "$ISDC_REF_CAT[JEMX_FLAG == 1]" !$outfile6


##  Make text files from fits
for file in $outfile1 $outfile2 $outfile3 $outfile4 $outfile5 $outfile6 ; do
  ./cat2raDecName.sh $file
  #./makeReg.sh $file
done


## Clean up
$HOME/integral/bin/rmlinks

for dir in ibis jmx spi ; do
  if [[ ! -d $dir ]] ; then mkdir $dir ; fi
done
mv isgri_*.* ibis/
mv jmx_*.* jmx/
mv spi_*.* spi/


## Note on ISGRI_FLAG and ISGRI_FLAG2
# ISGRI_FLAG=1 : source is detected by ISGRI
# ISGIR_FLAG=2 : source is detected by ISGRI AND position is known to < 3"
# ISGRI_FLAG2=1 : source is detected in scw (i.e., strong)
# ISGRI_FLAG2=2 : source is detected in mosaic (i.e., weak+strong+bright)
# ISGRI_FLAG2=5 : source is bright > 600 mCrab (125 sources)
