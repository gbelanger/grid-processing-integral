#! /bin/csh -f

if( $1 == "") then
  dal_create mosa_grp.fits ""
  dal_attach mosa_grp.fits jmx1_mosa_ima.fits.gz jmx2_mosa_ima.fits.gz ""
  j_ima_mosaic inObsGrp=mosa_grp.fits \
  radiusSelect=-1 diameter=-1 moscomb=y outfile=jmx_1p2_mosa.fits
  gzip jmx_1p2_mosa.fits

else if ($#argv == 2) then
  dal_create mosa_grp.fits ""
  dal_attach mosa_grp.fits $1 $2 ""
  j_ima_mosaic inObsGrp=mosa_grp.fits \
  radiusSelect=-1 diameter=-1 moscomb=y outfile=combi_mosa.fits
  gzip combi_mosa.fits

else if ( $#argv == 1) then
  dal_create mosa_grp.fits ""
  dal_attach mosa_grp.fits jmx1_mosa_ima.fits.gz jmx2_mosa_ima.fits.gz ""
  j_ima_mosaic inObsGrp=mosa_grp.fits \
  AITproj=Y radiusSelect=-1 diameter=-1 moscomb=y outfile=jmx_1p2_mosa.fits
  gzip jmx_1p2_mosa.fits

else echo "Wrong usage!"
 echo "Usage 1: $0  Without arguments combines automatically jmx1_mosa_ima.fits.gz & jmx2_mosa_ima.fits.gz into jmx_1p2_mosa.fits.gz"
 echo "Usage 2: $0 mosa_1 mosa_2 : combines mosa_1 & mosa_2 into combi_mosa.fits.gz"
 echo "Usage 3: $0 AIT Combines automatically large mosaics in AIT projection"
 stop
endif

/bin/rm -f mosa_grp.fits log

