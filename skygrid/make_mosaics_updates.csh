#! /bin/csh -f

#### To produce mosaics of images made in ParalL
## For JEM X-1 call: make_mosaics.sh 1
#  For the largest possible output mosaic one can use the Aitoff-Hammer projection (in galactic coordinates) by setting the option AITproj as 2nd input.
 
if ( $#argv == 0) then
    echo "Usage: $0 JEMX_instrument_number <AIT>"
    echo ""
    exit
endif

if ( -e swg_idx_jmx${1}.fits ) /bin/rm swg_idx_jmx${1}.fits
if ( -e list_swg${1}.txt ) /bin/rm list_swg${1}.txt

### provide an image path according to your main script so that a common observation group can be created. 
ls ${rep_base_prod}/obs/$scwid/scw/${scwid}.001/jmx${1}_sky_ima.fits > list_swg${1}.txt
#ls */scw/*/jmx${1}_sky_ima.fits > list_swg${1}.txt   ## Gaurava's working directory
sed -i "s/jmx$1_sky_ima.fits/swg_jmx$1.fits/g" list_swg${1}.txt
txt2idx list_swg${1}.txt swg_idx_jmx${1}.fits

if ( -e og_jmx${1}.fits ) /bin/rm og_jmx${1}.fits
dal_create og_jmx${1}.fits GNRL-OBSG-GRP.tpl
dal_attach og_jmx${1}.fits swg_idx_jmx${1}.fits "" "" "" ""

#fparkey: an ftools's component that sets instrument name in the new observation group file  
fparkey JMX${1} og_jmx${1}.fits INSTRUME

if ( $#argv == 1) then
j_ima_mosaic inObsGrp=og_jmx${1}.fits print_ScWs=Y dolBPL="$REP_BASE_PROD/ic/jmx${1}/rsp/jmx${1}_bpl_grp_0007.fits[jmx${1}-DMAP-BPL]"
else if ( $#argv == 2) then
j_ima_mosaic inObsGrp=og_jmx${1}.fits print_ScWs=Y dolBPL="$REP_BASE_PROD/ic/jmx${1}/rsp/jmx${1}_bpl_grp_0007.fits[jmx${1}-DMAP-BPL]" \
AITproj=Y diameter=-1
endif

gzip jmx$1_mosa_ima.fits
#clean unnecessary files
/bin/rm -f log swg_idx_jmx${1}.fits og_jmx${1}.fits list_swg${1}.txt

