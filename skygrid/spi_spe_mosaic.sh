#!/bin/bash

# Last modified
#
# G.Belanger and T.Siegert (Aug 2022)
#  - created script


COMMONSCRIPT=1
export COMMONSCRIPT

spi_science_analysis \
obs_group="og_spi.fits" \
IC_Group="../../idx/ic/ic_master_file.fits[1]" \
IC_Alias="OSA" \
coeff_DOL="" \
IRF_DOL="" \
RMF_DOL="" \
catalog="" \
clobber=yes \
log_File="spi_sa_fitdata.log" \
run_cat_extract=no \
run_pointing=no \
run_binning=no \
run_background=yes \
run_simulation=no \
run_spiros=yes \
run_phase_analysis=no \
run_gaincorrection=no \
run_fullcheck=no \
detectors="0-18" \
spiros_source-cat-dol="spi_cat_all_sources.fits" \
coordinates="RADEC" \
cat_extract_fluxMin="0.001" \
cat_extract_fluxMax="1000" \
use_pointing_filter=yes \
spibounds_nregions=10 \
spibounds_regions="25.00,35.12,49.33,69.29,97.33,136.71,143.17,194.97,201.77,284.09,400.00" \
spibounds_nbins="1,1,1,1,1,1,1,1,1,1" \
spi_phase_hist_ephemDOL="ephemeris.fits" \
spi_phase_hist_phaseBinNum=20 \
spi_phase_hist_phaseSameWidthBin=yes \
spi_phase_hist_phaseBounds="" \
spi_phase_hist_phaseSubtractOff=no \
spi_phase_hist_phaseOffNum=0 \
spi_phase_hist_orbit=no \
spi_phase_hist_asini=0 \
spi_phase_hist_porb=0 \
spi_phase_hist_T90epoch=0 \
spi_phase_hist_ecc=0 \
spi_phase_hist_omega_d=0 \
spi_phase_hist_pporb=0 \
spi_add_sim_SrcLong=80 \
spi_add_sim_SrcLat=19 \
spi_add_sim_FluxScale=0.01 \
use_background_flatfields=yes \
use_background_templates=no \
use_background_models=no \
spi_flatfield_ptsNbConstBack=5 \
loc_spiflatfield_dol="" \
spi_flatfield_single=no \
spi_templates_type="GEDSAT" \
spi_templates_scaling=1 \
spi_obs_back_nmodel=1 \
spi_obs_back_model01="GEDSAT" \
spi_obs_back_mpar01="" \
spi_obs_back_norm01="NO" \
spi_obs_back_npar01="" \
spi_obs_back_scale01=1 \
spi_obs_back_model02="GEDSAT" \
spi_obs_back_mpar02="" \
spi_obs_back_norm02="NO" \
spi_obs_back_npar02="" \
spi_obs_back_scale02=1 \
spi_obs_back_model03="GEDSAT" \
spi_obs_back_mpar03="" \
spi_obs_back_norm03="NO" \
spi_obs_back_npar03="" \
spi_obs_back_scale03=1 \
spi_obs_back_model04="GEDSAT" \
spi_obs_back_mpar04="" \
spi_obs_back_norm04="NO" \
spi_obs_back_npar04="" \
spi_obs_back_scale04=1 \
spiros_mode="SPECTRA" \
spiros_energy-subset="" \
spiros_pointing-subset="AUTO" \
spiros_detector-subset="" \
spiros_background-method=5 \
spiros_srclocbins="FIRST" \
spiros_image-proj="CAR" \
spiros_image-fov="POINTING+ZCFOV" \
spiros_nofsources=2 \
spiros_sigmathres=3 \
spiros_iteration-output="NO" \
spiros_optistat="CHI2" \
spiros_source-timing-mode="QUICKLOOK" \
spiros_source-timing-scale=0
