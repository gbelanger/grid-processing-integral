#!/bin/sh

if [[ $# != 1 ]] ; then
  echo "Usage: ibis_ima_mosaic.sh band (20-35)"
  return 1
fi
emin=`echo $1 | cut -d"-" -f1`
emax=`echo $1 | cut -d"-" -f2`

ibis_science_analysis ogDOL="og_ibis.fits[1]" \
  startLevel="CAT_I" endLevel="IMA2" \
  OBS1_ToSearch=50 \
  OBS1_DoPart2=2 \
  IBIS_II_ChanNum=1 \
  IBIS_II_E_band_min="${emin}" \
  IBIS_II_E_band_max="${emax}" \
  CAT_refCat="${ISDC_REF_CAT}[ISGRI_FLAG>0]"
