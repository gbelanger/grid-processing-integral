#!/bin/bash

##  The executable lc_pick uses the source id from the GNRL ref cat.
##  This means that we need to either call the script with the id or
##  get the id from the name or (ra,dec) via the GRNL ref cat.
##
##  The procedure involves 
##  1) making a list of the input files to include
##  2) creating an swg index file based on this list
##  3) creating the og
##  4) running lc_pick
##
##  This will produce the combined time series for that source


# Modification history:
#
# G.Belanger (Oct 2022)
# - moved common variables to config/grid.setenv.sh
#
# G.Belanger (Aug 2022)
# - created script
# 


##  Define program name and logging functions
log(){
    local progName="jmx_timeseries.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - ${date} - (${progName}) : "
    echo $log
    unset progName
}
warn(){
    local progName="jmx_timeseries.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[WARN] - ${date} - (${progName}) : "
    echo $log
    unset progName
}
error(){
    local progName="jmx_timeseries.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[ERROR] - ${date} - (${progName}) : "
    echo $log
    unset progName
}
cleanup(){
  /bin/rm -f swg_idx_${inst_idx}.fits og_${inst_idx}.fits list_swg_${inst_idx}.txt files.txt
}


##  Check arguments
if [[ $# -ne 4 ]]
then
  echo "$(error) Usage: jmx_timeseries.sh srcname band (46-82|83-153|153-224) instrument (JMX1|JMX2) /full/path/to/scw.lis"
  exit -1
fi


# Assign args to variables
name=$1
band=$2
instrument=$3
list=$4

inst=${instrument,,}

##  Check list
if [[ ! -e $list ]] ; then 
  echo "$(error) $list : File not found" 
  exit -1
elif [[ ! -s $list ]] ; then
  echo "$(error) $list : File is blank"
  exit -1
fi


##  Sort the list and remove duplicate entries
sort -u ${list} > /tmp/tmp.lis
mv /tmp/tmp.lis ${list}


##  Check instrument and define inst_idx
if [[ $instrument != JMX1 ]] && [[ $instrument != JMX2 ]] ; then
  echo "$(error) Unkown instrument $instrument. Can be JMX1|JMX2."
else
  # lower case
  inst_idx=${instrument,,}
fi

START_DIR=${PWD}


##  Define common variables
echo "$(log) Setting common variables"
source /home/int/intportalowner/integral/config/grid.setenv.sh


##  Check band and input data directory
inst_dir=jmx
DATA_DIR="${ISOC5}/${inst_dir}/scw_${band}"
if [[ ! -d $DATA_DIR ]] ; then
  echo "$(error) $DATA_DIR : Input data directory not found"
  exit -1
fi
emin=$(echo $band | cut -d"-" -f1)
emax=$(echo $band | cut -d"-" -f2)


##  Define output directory
TS_DIR="${ISOC5}/${inst_dir}/timeseries_${band}"


##  Go to output directory
dir=$(echo $name | sed s/" "/"_"/g)
if [[ ! -d ${TS_DIR}/${dir} ]] ; then
  echo "$(warn) Output source time serie directory not found"
  echo "$(log) Creating time series directory"
  mkdir -p ${TS_DIR}/${dir}
fi
echo "$(log) cd ${TS_DIR}/${dir}"
cd ${TS_DIR}/${dir}


##  Set OSA env
echo "$(log) Setting OSA env"
. ${INT_DIR}/pipeline/osa.setenv.sh


##  Extract row of catalog for source name
echo "$(log) Extracting source information ..."
infile="cat/hec/gnrl_refr_cat.fits"
outfile=out.fits
echo NAME==\"${name}\" > select.txt
${FTOOLS}/ftselect ${infile}[1] ${outfile} @select.txt clobber=yes


##  Check extraction
nrows=$(${FTOOLS}/fkeyprint ${outfile}[1] NAXIS2 | tail -1 | awk '{print $3}')
if [[ $nrows -eq 0 ]] ; then
  echo "$(error) - $name not found in $infile. Cannot proceed."
  exit 1
fi


##  Get the srcid, ra, dec
srcid=$(${FTOOLS}/ftlist ${outfile}[1] columns="SOURCE_ID" rows=1 T | tail -1 | awk '{print $2}')
ra=$(${FTOOLS}/ftlist ${outfile}[1] columns="RA_OBJ" rows=1 T | tail -1 | awk '{print $2}')
dec=$(${FTOOLS}/ftlist ${outfile}[1] columns="DEC_OBJ" rows=1 T | tail -1 | awk '{print $2}')
/bin/rm ${outfile} select.txt

echo "$(log) - NAME = $name"
echo "$(log) - SOURCE_ID = $srcid"
echo "$(log) - RA_OBJ = $ra"
echo "$(log) - DEC_OBJ = $dec"


## Cleanup previous run
if [[ -f swg_idx_${inst_idx}.fits ]] ; then /bin/rm swg_idx_${inst_idx}.fits ; fi
if [[ -f list_swg_${inst_idx}.txt ]] ; then /bin/rm list_swg_${inst_idx}.txt ; fi


## Make list of files to be included
echo "$(log) Compiling list of time series files. This can take a while ..."
filetype="${inst_idx}_src_iros_lc.fits"
cp ${list} ./${inst_idx}.lis

yes=0
no=0
echo $yes > good.txt
echo $no > missing.txt
if [[ -f files.txt ]] ; then rm files.txt ; fi

cat ${inst_idx}.lis | while read line
do
  rev=$(echo $line | cut -d"/" -f2)
  scwdir=$(echo $line | cut -d"/" -f3)
  scwid=$(echo $scwdir | cut -d"." -f1)
  file=${DATA_DIR}/${rev}/obs/${scwid}/scw/${scwdir}/${filetype}
  if [[ -f $file ]] ; then 
    n=$(${FTOOLS}/ftkeypar ${file}[1] NAXIS2 chatter=3 | head -2 | tail -1 | awk '{print $2}')
    if [[ $n -ne 0 ]] ; then
      echo $file >> files.txt ; 
      yes=$((yes+1));
      echo $yes > good.txt
    fi
  else
    echo "$(warn) - File not found : $file";
    no=$((no+1));
    echo $no > missing.txt
  fi
done
echo "$(log) - $(cat good.txt) good input files found"
echo "$(warn) - $(cat missing.txt) are missing"
#rm good.txt missing.txt


##  Check if there are files
if [[ $(cat good.txt) -eq 0 ]] ; then
  echo $(warn) No available input time series files. Cannot proceed.
  exit -1
fi


##  Get emin and emax
file=$(head -1 files.txt)
min=$(${FTOOLS}/ftkeypar ${file}[2] E_MIN chatter=3 | head -2 | tail -1 | awk '{print $2}')
max=$(${FTOOLS}/ftkeypar ${file}[2] E_MAX chatter=3 | head -2 | tail -1 | awk '{print $2}')

##  Round to nearest integer
emin=$(${CALC} nint\($min\))
emax=$(${CALC} nint\($max\))
echo "$(log) Using [emin, emax] = [$emin, $emax]"


##  Check if time series already exists
output="ts_${inst_idx}_${ra}_${dec}_${emin}-${emax}keV.fits"
if [[ -f $output ]] ; then
  echo "$(warn) Detected previous version of file:  $output"
  echo "$(log) Comparing scw list"

  ##  Compare current list with previous
  if [[ -f ${inst}.lis ]] ; then
    mv ${inst}.lis ${inst}_old.lis
  fi
  cp $list ./${inst}.lis

  if [[ -f ${inst}_old.lis ]] && [[ -f ${inst}.lis ]] && [[ -s ${inst}.lis ]] ; then
    diff ${inst}.lis ${inst}_old.lis > ${inst}_diff.lis
    if [[ ! -s ${inst}_diff.lis ]] ; then
      rm ${inst}_old.lis
      echo "$(log) No difference in ${inst}.lis: nothing to update"
      rm ${inst}_diff.lis
      cleanup
      exit 0
    else
      echo "$(log) Updating time series"
      rm $output
    fi
  fi
else
  cp $list ./${inst}.lis
fi


##  Convert the text file to a fits file of the swg index
idxlist=list_swg_${inst_idx}.txt
sed s/${filetype}/swg_${inst_idx}.fits/g files.txt > $idxlist
txt2idx ${idxlist} swg_idx_${inst_idx}.fits


##  Create og
og_file="og_${inst_idx}.fits"
if [[ -f og_${inst_idx}.fits ]] ; then /bin/rm ${og_file} ; fi
dal_create ${og_file} GNRL-OBSG-GRP.tpl
dal_attach ${og_file} swg_idx_${inst_idx}.fits "" "" "" ""
fparkey ${instrument} ${og_file} INSTRUME


## Set correct file permissions
chmod 644 *.*


##  Run lc_pick  IMP: must leave emin and emax empty to use all source data
lc_pick ${og_file} lc="$output" source="$srcid" emin="" emax="" ra_obj="${ra}" dec_obj="${dec}" instrument="${inst_idx}"


##  Add ANGDIST column to time series
#${SKYGRID_DIR}/jmx_add_angdist_col.sh 


##  Clean up
#cleanup


##  Go back to where we started
cd $START_DIR
