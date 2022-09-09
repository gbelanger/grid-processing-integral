#! /bin/csh -f

## create a summed source spectrum
# call: make_spec.sh 1or2 SOURCE_ID 

if ( $#argv == 0) then
    echo Usage: $0 JEMX_nb Source_ID
    echo ""
    exit
endif

if ( -e swg_idx_jmx${1}.fits ) /bin/rm swg_idx_jmx${1}.fits
if ( -e list_swg.txt ) /bin/rm list_swg${1}.txt


### location of spectrum in each directory  
ls ${rep_base_prod}/obs/$scwid/scw/${scwid}.001/jmx${1}_srcl_spe.fits > list_swg${1}.txtl
sed -i "s/jmx${1}_srcl_spe.fits/swg_jmx$1.fits/g" list_swg${1}.txt
txt2idx list_swg${1}.txt swg_idx_jmx${1}.fits

if ( -e og_jmx${1}.fits ) /bin/rm og_jmx${1}.fits
dal_create og_jmx${1}.fits GNRL-OBSG-GRP.tpl
dal_attach og_jmx${1}.fits swg_idx_jmx${1}.fits "" "" "" ""
fparkey JMX$1 og_jmx${1}.fits INSTRUME

spe_pick og_jmx${1}.fits source=$2

/bin/rm -f log swg_idx_jmx${1}.fits og_jmx${1}.fits list_swg${1}.txt
