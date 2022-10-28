#!/usr/bin/env bash
set -o errexit  # exit when a command fails
set -o nounset # exit when your script tries to use undeclared variables
#set -o xtrace # trace what gets executed (uncomment for debugging)

if [ $# -eq 1 ] ; then
  file=$1
else
  echo "Warning : no input catalog provided. Using gnrl_refr_cat_0043.fits"
  file="gnrl_refr_cat_0043.fits"
fi

echo "Getting RA, Dec, and Name from $file"
out=$(echo $file | sed s/".fits"/"_raDecName.txt"/g)
fdump ${file}[1] $out "RA_OBJ DEC_OBJ NAME" - more=yes prhead=no showcol=no showunit=no showrow=no clobber=yes
out2=$(echo $file | sed s/".fits"/"_names.txt"/g)
fdump ${file}[1] $out2 "NAME" - more=yes prhead=no showcol=no showunit=no showrow=no clobber=yes


# Remove empty lines
for outfile in $out $out2 ; do
  grep . $outfile > tmp
  mv tmp $outfile
done
