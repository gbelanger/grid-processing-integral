#!/bin/bash

# Last modified by 
#
# G.Belanger (April 2022)
#  - Removed unneeded case statement for instrument
# G.Belanger (September 2012)
# G.Belanger (June 2009)	
# D.Tapiador (April 2007)
#

if [[ $# -lt 3 ]]
then
   echo "Usage: . launch_many_mosaics.sh lists.filenames instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82)"
   return 1
fi

scwfilelist=$1
instrument=$2
band=$3


##  Define launch command
command=". launch_single_mosaic.sh"

echo "Submitting jobs..."

for scwfile in $(cat $scwfilelist) ; do
  bash -c "$command ${scwfile} ${instrument} ${band}"
done
