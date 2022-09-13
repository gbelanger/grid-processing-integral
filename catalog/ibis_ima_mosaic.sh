#!/bin/sh


##  Optimised for catalog production


if [[ $# != 1 ]] ; then
  echo "Usage: ibis_ima_mosaic.sh band (20-35)"
  return 1
fi
emin=$(echo $1 | cut -d"-" -f1)
emax=$(echo $1 | cut -d"-" -f2)


ibis_science_analysis ogDOL="og_ibis.fits[1]" \
  startLevel="CAT_I" endLevel="IMA2" \
  OBS1_DoPart2=2 \
  OBS1_PixSpread=0 \
  OBS1_MinCatSouSnr=5 \
  OBS1_MinNewSouSnr=5 \
  OBS1_SearchMode=2 \
  IBIS_II_ChanNum=1 \
  IBIS_II_E_band_min="${emin}" \
  IBIS_II_E_band_max="${emax}" 
