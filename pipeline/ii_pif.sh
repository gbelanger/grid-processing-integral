#!/usr/bin/env bash

# Last modified by 
#
# G.Belanger (Nov 2018)
# - adapted from indiv_science_analysis_archive.sh
# G.Belanger (Jan 2019)
# - added update to isgri_cat.fits to make sure we use latext catlog

source /home/int/intportalowner/integral/config/grid.setenv.sh

export CALCFORMAT=%.8g

# NOTE: Max of 500 sources in catalog

##  Define catalog to be used
catalog="${INT_DIR}/refcat/ibis/isgri_cat_bright_0043.fits"

ii_pif \
    inOG="" outOG="og_ibis.fits" inCat="$catalog" \
    num_band=1 E_band_min="20" E_band_max="1000" \
    mask="$REP_BASE_PROD/ic/ibis/mod/isgr_mask_mod_0003.fits" \
    tungAtt="$REP_BASE_PROD/ic/ibis/mod/isgr_attn_mod_0010.fits" \
    aluAtt="$REP_BASE_PROD/ic/ibis/mod/isgr_attn_mod_0011.fits" \
    leadAtt="$REP_BASE_PROD/ic/ibis/mod/isgr_attn_mod_0012.fits"

##  Extract event list for each source
list=list_of_detected_sources.txt
scw="${PWD##*/}.001"
cat $list | while read lineNo ra dec sourceid name; do

  ## Make single source catalog
  sourceName=$(echo $name | sed s/" "/_/g); 
  catName="scw/${scw}/cat_${sourceName}.fits"; 
  fcopy infile="${INT_DIR}/refcat/isgri_cat_0043.fits[NAME=='$name']" outfile=!"$catName"; 
  evlistName="scw/${scw}/evlist_${sourceName}.fits"; 

  ## Extract events
  if [ -f $evlistName ]; then /bin/rm $evlistName; fi
  evts_extract \
    group="og_ibis.fits" events="$evlistName" \
    instrument=IBIS sources="$catName" gtiname="MERGED_ISGRI" \
    pif=yes deadc=yes attach=no barycenter=1 timeformat=0 instmod=""; 

  ## Use only pif==1
  fcopy infile="$evlistName[2][PIF_1==1]" outfile=!"scw/${scw}/evlist_${sourceName}_pif.fits";
  /bin/mv scw/${scw}/evlist_${sourceName}_pif.fits $evlistName; 
  #/bin/rm $catName;
done

##  Define Nyquist bintimes for each source in the FOV
rates=list_of_rates_from_cat.txt
bintimes=list_of_nyquist_bintimes.txt
cat $rates | while read lineNo flux name; do 
  if [ $flux != "0.0000000E+00" ]; then 
    nyquistBintime=$(${CALC} 0.5/$flux); 
  else nyquistBintime=100; 
  fi; 
  echo $nyquistBintime $name >> $bintimes; 
done
