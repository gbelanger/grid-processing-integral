
##  Make list of sources detected above 3 sigma
list="sources_detected_isgri.txt"
fcopy infile="scw/${scw}/isgri_sky_res.fits[2][DETSIG>3]" outfile=!"scw/${scw}/isgri_sky_res_detsig3.fits"
fdump scw/${scw}/isgri_sky_res_detsig3.fits[2] STDOUT "RA_OBJ DEC_OBJ SOURCE_ID NAME" - yes prhead=no | grep -v '^\s*$' | egrep -v "NAME|deg" | egrep -v "NEW_" > $list

##  Get the detected rates of sources above 3 sigma
rates="source_rates_isgri.txt"
sky_res="scw/${scw}/isgri_sky_res_detsig3.fits"
fdump $sky_res\[2] STDOUT "FLUX NAME" - yes prhead=no | grep -v '^\s*$' | egrep -v "NAME|count" | egrep -v "NEW_" > $rates;

##  Make list of sources in the FOV
list="sources_in_fov_isgri.txt"
scw="${PWD##*/}.001"
fdump scw/${scw}/isgri_model.fits[1] STDOUT "RA_OBJ DEC_OBJ NAME" - yes prhead=no | grep -v '^\s*$' | egrep -v "NAME|deg" | egrep -v "NEW_" > $list

