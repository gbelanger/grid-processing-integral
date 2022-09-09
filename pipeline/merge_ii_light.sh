#!/usr/bin/env bash

#set -o errexit # exit when a command fails
#set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)


dal_create obj_name="ii_light_results.fits" template="ISGR-SRC.-LCR-IDX.tpl"

## Loop through all scw
for file in ${REP_BASE_PROD}/obs/*/scw/*/ii_light_results.fits ; do
    idx_collect index="ii_light_results.fits" template="ISGR-SRC.-LCR-IDX.tpl" element="$file"
done

## Compile the list of all detected sources
list="list_of_detected_sources.txt"
cat obs/*/$list | sort -u | egrep -v NEW | awk '{print $2, $3, $4, $5, $6, $7}' | cat -n > $list

##  Extract ts for each source
cat $list | while read line ra dec sourceid name ; do
    sourceName=$(echo $name | sed s/" "/_/g) ; 
    lc_pick source="$name" attach=n \
	group=ii_light_results.fits+1 lc=ts_${sourceName}.fits \
	emin="20" emax="80" instrument="ISGRI"
done

## Clean up
mkdir ts
mv ts_* ts/
