#!/bin/sh

# Last modified by 
#
# G.Belanger (Jul 2022)
# - Created script

# Run spectral extraction
ibis_science_analysis \
  ogDOL="og_ibis.fits[1]" \
  startLevel="BIN_S" endLevel="SPE" \
  CAT_refCat="${ISDC_REF_CAT}[ISGRI_FLAG>0]" \
  SCW1_GTI_BTI_Names="IBIS_CONFIGURATION ISGRI_RISE_TIME BELT_CROSSING SOLAR_FLARE VETO_PROBLEM IBIS_BOOT MISCELLANEOUS" \
  SCW2_cat_for_extract="isgri_specat.fits" \
  IBIS_nregions_spe=1 \
  IBIS_nbins_spe="-4" \
  IBIS_energy_boundaries_spe="20 100" 
  #rebinned_corrDol_spe="$HOME/integral/osa_support/rebinned_corr_spe_${emin}-${emax}.fits" \
  #rebinned_backDol_spe="$HOME/integral/osa_support/rebinned_back_spe_${emin}-${emax}.fits" \
  #rebinned_unifDol_spe="$HOME/integral/osa_support/rebinned_unif_spe_${emin}-${emax}.fits" 
