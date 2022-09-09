#! /bin/bash

#  For the large output mosaic use Aitoff-Hammer projection (in galactic coordinates) 
#  by setting the option AITproj=Y
 
# STANDARD
j_ima_mosaic inObsGrp=og_jmx2.fits \
print_ScWs=Y \
dolBPL="$REP_BASE_PROD/ic/jmx2/rsp/jmx2_bpl_grp_0007.fits[JMX2-DMAP-BPL]"

# AITOFF
#j_ima_mosaic inObsGrp=og_jmx2.fits \
#print_ScWs=Y \
#dolBPL="$REP_BASE_PROD/ic/jmx2/rsp/jmx2_bpl_grp_0007.fits[JMX2-DMAP-BPL]" \
#AITproj=Y diameter=-1

# AITOFF with coordinates
#j_ima_mosaic inObsGrp=og_jmx2.fits \
#print_ScWs=Y \
#dolBPL="$REP_BASE_PROD/ic/jmx2/rsp/jmx2_bpl_grp_0007.fits[JMX2-DMAP-BPL]" \
#AITproj=Y diameter=-1 cdelt=0.075 \
#RAcenter=266.4 DECcenter=-28.94 
#emaxSelect=11. cdelt=0.03
