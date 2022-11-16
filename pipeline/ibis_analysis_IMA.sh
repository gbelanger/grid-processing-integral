#!/bin/sh

# Last modified by 
#
# D.Tapiador (Apr 2007)
# G.Belanger (June 2009)
# G.Belanger (Aug 2012)
# G.Belanger (July 2014) 
#  - added arguments emin emax
# G.Belanger (Sep 2014)
#  - changed to band as single arg: 'emin-emax'
#  - changed/added parameters 
# G.Belanger (Mar 2018)
# - added the 'strace' command  to get more logging while debugging 
# G.Belanger (Jul 2022)
# - added parameters for including BTI info (SCW1_GTI_BTI)

if [[ $# != 1 ]]
then
    echo "Usage: . ibis_analysis_IMA.sh band (20-35)"
    return 1
fi

emin=`echo $1 | cut -d"-" -f1`
emax=`echo $1 | cut -d"-" -f2`

# Use this to get the complete log
#strace -f -e open ibis_analysis \

COMMONSCRIPT=1
export COMMONSCRIPT

COMMONLOGFILE=+ibis_analysis_IMA.log
export COMMONLOGFILE

# Run imaging
ibis_science_analysis \
  ogDOL="og_ibis.fits[1]" \
  startLevel="COR" endLevel="IMA" \
  OBS1_DoPart2="0" \
  OBS1_SearchMode=3 \
  OBS1_ToSearch=30 \
  OBS1_MinCatSouSnr="4" \
  OBS1_MinNewSouSnr="5" \
  OBS1_SouFit="1" \
  OBS1_NegModels="1" \
  OBS1_PixSpread="1" \
  CAT_refCat="${ISDC_REF_CAT}[ISGRI_FLAG>0]" \
  SCW1_GTI_BTI_Names="IBIS_CONFIGURATION ISGRI_RISE_TIME BELT_CROSSING SOLAR_FLARE VETO_PROBLEM IBIS_BOOT MISCELLANEOUS" \
  IBIS_II_ChanNum="1" \
  IBIS_II_E_band_min="${emin}" \
  IBIS_II_E_band_max="${emax}" 
#  rebinned_corrDol_ima="$OSA_DIR/rebinned_corr_ima_${emin}-${emax}.fits" \
#  rebinned_unifDol_ima="$OSA_DIR/rebinned_unif_ima_${emin}-${emax}.fits"
