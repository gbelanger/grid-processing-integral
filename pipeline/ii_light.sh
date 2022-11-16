#!/bin/sh

# Last modified by 
#
# G.Belanger (Nov 2018)
# - adapted from indiv_science_analysis_archive.sh

##  Define variables scw and rev
dir="${PWD##*/}"
scw="${dir}.001"
rev=$(echo $dir | awk '{print substr($1,0,4)}')

# Units are in seconds; Minimum time bin is 60 micro second
bintime=0.001000  # 1000 micro second
bintime=10

ii_light \
    inSwg="${REP_BASE_PROD}/obs/${dir}/scw/${scw}/swg_ibis.fits" \
    outLC="${REP_BASE_PROD}/obs/${dir}/scw/${scw}/ii_light_results.fits(ISGR-SRC.-LCR-IDX.tpl)" \
    context="$REP_BASE_PROD/scw/${rev}/rev.001/idx/isgri_context_index.fits.gz[1]" \
    idxSwitch="$REP_BASE_PROD/scw/${rev}/rev.001/idx/isgri_pxlswtch_index.fits.gz[1]" \
    idxNoise="$REP_BASE_PROD/scw/${rev}/rev.001/idx/isgri_prp_noise_index.fits.gz[1]" \
    GTIname="MERGED_ISGRI" \
    delta_t=${bintime} \
    num_e=1 e_min="20" e_max="80" \
    onlydet=no \
    pifDOL="${REP_BASE_PROD}/obs/${dir}/scw/${scw}/isgri_model.fits" \
#    corrDol="${OSA_DIR}/rebinned_corr_ima_20-80.fits" \
#    backDol="${OSA_DIR}/rebinned_back_ima_20-80.fits" \
    cleanobt=no
