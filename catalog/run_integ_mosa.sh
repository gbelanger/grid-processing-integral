#!/bin/bash

# Last modified
#
# G.Belanger (Aug 2022)
#  - Added support for spi
# G.Belanger (May 2022)
#  - Added support for jemx
#  - Generalised logic to work for skygrid and normal mosaics
#  - Improved syntax
# G.Belanger (October 2015)
#  - Modifed from version used in skygrid for less specific file/dir name formats
# G.Belanger (September 2015)
#  - Added image selection before making the mosaic
# G.Belanger (September 2014)
#  - changed the output directory structure
# G.Belanger (July 2014) 
#  - removed 'instrument' argument that was not needed
#  - added the band argument to define emin emax in the processing
#  - process directly in final storage directory
# G.Belanger (September 2012)
#  - wrote script

log(){
    local progName="run_integ_mosa.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    log="[INFO] - $date - ($progName) : "
    echo $log
    unset progName
}

warn(){
    local progName="run_integ_mosa.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    warn="[WARN] - $date - ($progName) : "
    echo $warn
    unset progName
}

error(){
    local progName="run_integ_mosa.sh"
    date=$(date +"%d-%m-%Y %H:%M:%S")
    error="[ERROR] - $date - ($progName) : "
    echo $error
    unset progName
}

if [[ $# != 3 ]]
then
  echo "Usage: ./run_integ_mosa.sh scw.lis (field/field_1.lis) instrument (ISGRI|JMX1|JMX2|SPI) band (e.g., 20-35|46-82|83-153|154-224|25-400)"
  exit -1
fi

START_DIR=${PWD}

## We must specify how much java memory to allocate, otherwise java crahses
JAVA_HOME="${HOME}/jdk"
JAVA="${JAVA_HOME}/bin/java -Xms200m -Xmx200m"

##  Define FTOOLS
HEADAS="/opt/sw/heasoft6.25/x86_64-pc-linux-gnu-libc2.12"
# HEADAS="/opt/sw/heasoft-6.30.1/x86_64-pc-linux-gnu-libc2.28"

export HEADAS
. $HEADAS/headas-init.sh
export FTOOLS="${HEADAS}/bin"

# Read arguments
list=$1
instrument=$2
band=$3

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
case $instrument in
  ISGRI)
    inst_idx="ibis";
    inst=${inst_idx};
    processing=${inst_idx}_ima_mosaic.sh;
    ;;
  JMX1|JMX2)
    # lower case
    inst_idx=${instrument,,};
    inst="jmx";
    processing=${inst_idx}_ima_mosaic.sh;
    ;;
  SPI)
    inst_idx=${instrument,,};
    inst=${inst_idx};
    processing=${inst_idx}_spe_mosaic.sh;
    ;;
  *)
    echo "$(error) $instrument : Unknown instrument. Options are ISGRI|JMX1|JMX2|SPI.";
    exit -1;
    ;;
esac


##  Check band and input data directory
ISOC5="/data/int/isoc5/gbelange/isocArchive"
DATA_DIR="${ISOC5}/${inst}/scw_${band}"
if [[ ! -d $DATA_DIR ]] ; then
  echo "$(error) $DATA_DIR : Directory not found"
  exit -1
fi

##  Define INTEGRAL directories
BIN_DIR="/home/int/intportalowner/bin"
INT_DIR="/home/int/intportalowner/integral"
PIPELINE_DIR="${INT_DIR}/pipeline"
MOSAICS_DIR="${ISOC5}/${inst}/mosaics_${band}"
SKYGRID_DIR="${ISOC5}/${inst}/skygrid_${band}/mosaics"

##  Define output directory based on name/path of scw.lis

### IMPORTANT : ${list} must contain _one_ directory name above the file name

listname=$(echo $list | cut -d"/" -f2)

#  Define variables based on launch directory: 
if [[ $PWD == ${INT_DIR}/skygrid ]] ; then

  MOSAICS_DIR=${SKYGRID_DIR}

  ### IMPORTANT : ${listname} must have the form:  scw_pt${num}_${ra}_${dec}_${dist}deg.lis

  field=$(echo ${listname} | cut -d"_" -f2 | sed s/"pt"/"field_"/g)
  output_mosa_dir="${MOSAICS_DIR}/${field}"

elif [[ $PWD == ${INT_DIR}/mosaics ]] ; then

  ### IMPORTANT : ${list} must have the form:  parentfield/field_*.lis

  parentfield=$(echo $list | cut -d"/" -f1)
  field=$(echo $listname | cut -d"." -f1)
  output_mosa_dir="${MOSAICS_DIR}/${parentfield}/${field}"

else
  echo "$(error) Unknown launch dir: $PWD. Must launch from ${INT_DIR}/skygrid | ${INT_DIR}/mosaics"
  exit -1
fi

##  Check/Create parent output directory
if [[ ! -d ${MOSAICS_DIR} ]] ; then mkdir -p ${MOSAICS_DIR} ; fi

##  Move into parent output directory
touch ${MOSAICS_DIR}
cd ${MOSAICS_DIR}

##  Copy the input scw list here temporarily
cp ${START_DIR}/${list} ./${listname}

##  Exit if only one scw
n=$(wc -l ${listname} | awk '{print $1}') 
if [[ $n -eq 1 ]] ; then
  echo "Only one scw in ${listname}" >> ${MOSAICS_DIR}/no-mosaic/NO_MOSAIC.readme
  rm ./${listname}
  exit 0
fi

##  Construct list of input data directories needed for mosaic
pathToData=""
dirs=$(cat ${listname} | cut -d"/" -f2 | sort -nu)
set -o noglob

for rev in ${dirs} ; do
  ##  Make sure we are using data beyond rev 26
  if [ $rev -ge 0026 ] ; then
    path2="${DATA_DIR}/${rev}/obs"
    pathToData="${pathToData} ${path2}"
  fi
done

if [[ "${pathToData}" == "" ]] ; then
  echo "$(error) No data beyond rev 26. Cannot make mosaic"
  echo "No data beyond rev 26 for ${listname}" >> ${MOSAICS_DIR}/no-mosaic/NO_MOSAIC.readme
  exit 0
fi
set +o noglob


##  Prepare the Observation Groups

case $instrument in

  ISGRI)

    ##  Delete previous child output directory
    if [[ -d ${output_mosa_dir} ]] ; then
      chmod -fR 755 ${output_mosa_dir}
      /bin/rm -r ${output_mosa_dir}
    fi

    ##  Select images 
    ${JAVA} -jar ${INT_DIR}/bin/SelectSkyIma.jar $listname signif 1 1.9 $pathToData

    if [[ ${MOSAICS_DIR} != ${SKYGRID_DIR} ]] ; then
      if [[ ! -e ${MOSAICS_DIR}/${parentfield} ]] ; then mkdir -p ${MOSAICS_DIR}/${parentfield} ; fi
      mv ${listname}* ${MOSAICS_DIR}/${parentfield}/
      touch ${MOSAICS_DIR}/${parentfield}
      cd ${MOSAICS_DIR}/${parentfield}
    fi

    ##  Make og for ibis analysis (this creates $output_mosa_dir here named $field)
    ${JAVA} -jar ${INT_DIR}/bin/OG_merge.jar ${listname}.selected $field $pathToData

    ##  Move all the lists into the final output mosa dir
    mv ${listname}* $field/

    ##  Check if OG_merge.jar worked
    if [ ! -d $field/obs/myobs ] ; then
      echo "$(error) OG_merge.jar failed to prepare mosaic directory"
      exit -1
    fi

    ##  Copy support files needed for imaging analysis (to not recreate them for each scw)
    cp ${INT_DIR}/osa_support/rebinned_back_ima_${band}.fits ${field}/obs/myobs/rebinned_back_ima.fits
    cp ${INT_DIR}/osa_support/rebinned_corr_ima_${band}.fits ${field}/obs/myobs/rebinned_corr_ima.fits
    cp ${INT_DIR}/osa_support/rebinned_unif_ima_${band}.fits ${field}/obs/myobs/rebinned_unif_ima.fits

    ##  This hidden option makes a residual map where both sources and ghosts are removed
    #echo "8" > ${field}/obs/myobs/ii_skyimage.hidden

    ##  Set OSA environment variables
    touch ${output_mosa_dir}
    cd ${output_mosa_dir}
    . ${PIPELINE_DIR}/osa11.setenv.sh

    ##  Move into final output mosaic dir
    cd obs/myobs
    ;;

  JMX1 | JMX2)

    ##  Check/Create the mosaic directory
    if [[ ! -e ${output_mosa_dir} ]] ; then mkdir -p ${output_mosa_dir} ; fi
    touch ${output_mosa_dir}

    ##  Check/Update the scw list
    if [[ -e ${output_mosa_dir}/${listname} ]] ; then
      diff ./${listname} ${output_mosa_dir}/${listname} > ${output_mosa_dir}/diffs.txt
      if [[ -s diffs.txt ]] 
      then
        mv ${output_mosa_dir}/${listname} ${output_mosa_dir}/previous_${listname}
      fi
    fi
    mv ./${listname} ${output_mosa_dir}/

    ##  Go into the mosaic directory
    cd ${output_mosa_dir}

    ##  Set OSA environment variables
    . ${INT_DIR}/pipeline/osa11.setenv.sh

    ##  Create final mosaic output directory
    if [[ ! -e obs/myobs ]] ; then mkdir -p obs/myobs ; fi

    ##  Go into this directory
    cd obs/myobs/

    ##  Remove files from previous run
    inst_idx="${instrument,,}"
    if [[ -e swg_idx_${inst_idx}.fits ]] ; then /bin/rm swg_idx_${inst_idx}.fits ; fi
    if [[ -e list_swg_${inst_idx}.txt ]] ; then /bin/rm list_swg_${inst_idx}.txt ; fi

    ##  Compile list of images to mosaic
    filetype=${inst_idx}_sky_ima.fits
    idxlist=list_swg_${inst_idx}.txt
    cat ../../${listname} | while read line
    do
      rev=$(echo $line | cut -d"/" -f2)
      scwdir=$(echo $line | cut -d"/" -f3)
      scwid=$(echo $scwdir | cut -d"." -f1)
      ls ${DATA_DIR}/${rev}/obs/${scwid}/scw/${scwdir}/${filetype} | sed s/${filetype}/swg_${inst_idx}.fits/g >> $idxlist
    done

    ##  Convert the text file to a fits file of the swg index for all images
    txt2idx ${idxlist} swg_idx_${inst_idx}.fits

    ##  Remove old observation group file
    if [[ -e og_${inst_idx}.fits ]] ; then /bin/rm og_${inst_idx}.fits ; fi

    ##  Create new observation group file
    dal_create og_${inst_idx}.fits GNRL-OBSG-GRP.tpl
    dal_attach og_${inst_idx}.fits swg_idx_${inst_idx}.fits '' '' '' ''

    ##  Add instrument name in the new observation group file  
    ${FTOOLS}/fparkey ${instrument} og_${inst_idx}.fits INSTRUME
    ;;

  SPI)

    ##  Delete previous child output directory
    echo "$(log) Deleting previous run"
    if [[ -d ${output_mosa_dir} ]] ; then
      chmod -fR 755 ${output_mosa_dir}
      /bin/rm -r ${output_mosa_dir}
    fi
    mkdir -p ${output_mosa_dir}


    ##  Move the lists into the final output mosa dir
    echo "$(log) Moving scw list to mosa dir ${output_mosa_dir}"
    mv ./${listname} ${output_mosa_dir}/


    ##  Go into the mosaic directory
    cd ${output_mosa_dir}


    ##  Filter the scw list based on overall spi scw db
    echo "$(log) Filtering list based on general SPI scw DB file"
    in=${listname}
    out="${listname}.selected"
    nlines=$(cat ${in} | wc -l)
    echo "$(log) - Input list has $nlines scws"
    . ${INT_DIR}/skygrid/select_spi_scws.sh ${in} ${out}
    sort -u $out > tmp
    mv tmp $out
    nlines=$(cat ${out} | wc -l)
    echo "$(log) - Selected list has $nlines scws"
    list="${listname}.selected"


    ##  Filter based on event
    echo "$(log) Filtering based on events ..."
    event_file="evts_det_spec.fits"
    if [[ -f ${listname}.evts ]] ; then rm ${listname}.evts ; fi
    cat ${list} | while read line
    do
      rev=$(echo $line | cut -d"/" -f2)
      scwdir=$(echo $line | cut -d"/" -f3)
      scwid=$(echo $scwdir | cut -d"." -f1)
      nevents=$(${FTOOLS}/fkeyprint ${DATA_DIR}/${rev}/obs/${scwid}/${event_file}[1] NAXIS2 | tail -1 | awk '{print $3}')
      if [[ $nevents -gt 0 ]]
      then
        echo $line >> ${listname}.evts
      else
        echo "$(warn) - No events in ${scwid}"
      fi
    done
    list=${listname}.evts
    nlines=$(cat ${list} | wc -l)
    echo "$(log) - Filtered list has $nlines scws"


    ##  Set OSA environment variables
    echo "$(log) Setting OSA env"
    . ${INT_DIR}/pipeline/osa11.setenv.sh


    ##  Create and move into final mosaic output directory
    mkdir -p obs/myobs
    cd obs/myobs/


    ##  Make lists of all the available files for each filetype
    filetypes="evts_det_spec gti dead_time pointing gain_coeff_index energy_boundaries"
    for filetype in $filetypes ; do
      if [[ -f ${filetype}.lst ]] ; then rm ${filetype}.lst ; fi
    done
    echo "$(log) Making lists of all available files by filetype ..."
    cat ../../${list} | while read line
    do
      rev=$(echo $line | cut -d"/" -f2)
      scwdir=$(echo $line | cut -d"/" -f3)
      scwid=$(echo $scwdir | cut -d"." -f1)
      for filetype in $filetypes ; do
        file="${DATA_DIR}/${rev}/obs/${scwid}/${filetype}.fits"
        if [[ -s $file  ]] ; then
          ls $file >> ${filetype}.lst
        fi
      done
    done
    for file in *.lst ; do
      nlines=$(cat $file | wc -l)
      echo "$(log) - $file ready with $nlines lines"
    done


    ##  Filter to include only observations that have all required files
    echo "$(log) Filtering to include only obs with all required files ..."
    filetypes="evts_det_spec gti dead_time pointing gain_coeff_index"
    final_list="../../${listname}.final"
    if [[ -f ${final_list} ]] ; then rm ${final_list} ; fi
    cat ../../${list} | while read line
    do
      rev=$(echo $line | cut -d"/" -f2)
      scwdir=$(echo $line | cut -d"/" -f3)
      scwid=$(echo $scwdir | cut -d"." -f1)
      for filetype in $filetypes ; do
        egrep "${DATA_DIR}/${rev}/obs/${scwid}" ${filetype}.lst > ${filetype}.check
      done
      n=$(cat *.check | wc -l)
      if [[ $n -eq 5 ]] ; then
        echo $line >> ${final_list}
        for filetype in $filetypes ; do
          cat ${filetype}.check >> ${filetype}.final
          ${FTOOLS}/fkeyprint ${DATA_DIR}/${rev}/obs/${scwid}/og_spi.fits[1] TELAPSE| tail -1 | awk '{print $3}' >> telapse.txt
        done
      fi
    done


    ##  Cleanup
    rm *.check
    for filetype in $filetypes ; do
      diff ${filetype}.final ${filetype}.lst > diff.txt
      if [[ ! -s diff.txt ]] ; then rm ${filetype}.lst ; fi
    done
    rm diff.txt


    ##  Search for and fix pointing.fits files with an extra row
    cat pointing.final | while read file
    do
      nrows=$(${FTOOLS}/fkeyprint $file[1] NAXIS2 | tail -1 | awk '{print $3}')
      if [[ $nrows -eq 2 ]] ; then
        echo "File $file contains two rows."
        t=$(ftlist ${file}[1] columns="TELAPSE" rows=1 T | tail -1 | awk '{print $2}')
        if [[ "$t" == "0.00000000000000" ]] ; then
          echo "$(log) - Confirming that TELAPSE in first row is 0.00000000000000"
          echo "$(log) - Deleting that row ..."
          ${FTOOLS}/ftdelrow $file[1] none 1 confirm=yes chatter=0
          nrows=$(${FTOOLS}/fkeyprint $file[1] NAXIS2 | tail -1 | awk '{print $3}')
          echo "$(log) - File now has $nrows rows"
          ftchecksum ${file} update=yes chatter=0
        fi
      fi
    done


    ##  Create scw idx file
    echo "$(log) Making swg_idx  based on final filtered list"
    event_file="evts_det_spec.fits"
    idxlist=list_swg_${inst_idx}.txt
    cat ${final_list} | while read line
    do
      rev=$(echo $line | cut -d"/" -f2)
      scwdir=$(echo $line | cut -d"/" -f3)
      scwid=$(echo $scwdir | cut -d"." -f1)
      ls ${DATA_DIR}/${rev}/obs/${scwid}/${event_file} | sed s/${event_file}/"scw\/${scwdir}\/swg_${inst_idx}.fits"/g >> $idxlist
    done

    #  Convert the text file to a fits file of the swg index
    txt2idx $idxlist swg_idx_${inst_idx}.fits


    ##  Merge the result files from the selected scw one by one
    echo "$(log) Merging files ..."
    filetypes="evts_det_spec gti dead_time gain_coeff_index pointing"
    for filetype in $filetypes ; do
      echo "$(log) - $filetype ..."
      if [[ -f ${filetype}.fits ]] ; then rm ${filetype}.fits ; fi
      file_one=$(head -1 ${filetype}.final)
      n=$(cat ${final_list} | wc -l)
      i=2
      while [ $i -le $n ]; do
        file_two=$(head -$i ${filetype}.final | tail -1)
        ${FTOOLS}/fmerge "${file_one} ${file_two}" tmp.fits columns=-
        mv tmp.fits ${filetype}.fits
        file_one=${filetype}.fits
        ((i++))
      done
      nrows=$(${FTOOLS}/fkeyprint ${filetype}.fits[1] NAXIS2 | tail -1 | awk '{print $3}')
      echo "$(log) - merged ${filetype}.fits ready with $nrows rows"
    done

exit 0

    ##  Copy the first available energy_boundaries file here (same for all observations)
    file=$(head -1 energy_boundaries.lst)
    if [[ -s $file ]] ; then
      cp $file .
    else
      i = 2
      while [[ ! -s $file ]] ; do
        file=$(head -$i energy_boundaries.lst | tail -1)
        ((i++))
      done
      cp $file .
    fi


    ##  Create new observation group file
    dal_create og_${inst_idx}.fits GNRL-OBSG-GRP.tpl


    ##  Add instrument name in the new observation group file  
    ${FTOOLS}/fparkey ${instrument} og_${inst_idx}.fits INSTRUME    


    ##  Attach the swg_idx to og file
    dal_attach og_${inst_idx}.fits swg_idx_${inst_idx}.fits '' '' '' ''


    ##  Attach all the merged files to og file
    echo "$(log) Attaching merged files to og_spi.fits ..."
    filetypes="evts_det_spec gti dead_time pointing gain_coeff_index energy_boundaries"
    for filetype in $filetypes ; do
      echo "$(log) - $filetype"
      ftchecksum ${filetype}.fits update=yes chatter=0
      dal_attach og_${inst_idx}.fits ${filetype}.fits '' '' '' ''
    done

    ##  Update keywords in og_spi.fits

    #  Take TSTART from the first scw
    file=$(head -1 evts_det_spec.final | sed s/"evts_det_spec.fits"/"og_spi.fits"/g)
    tstart=$(${FTOOLS}/fkeyprint ${file}[1] TSTART | tail -1 | awk '{print $3}')
    echo "$(log) TSTART = $tstart"
  
    #  Take TSTOP from the last scw
    file=$(tail -1 evts_det_spec.final | sed s/"evts_det_spec.fits"/"og_spi.fits"/g)
    tstop=$(${FTOOLS}/fkeyprint ${file}[1] TSTOP | tail -1 | awk '{print $3}')
    echo "$(log) TSTOP = $tstop"

    #  Sum the telapse from all scws
    echo "$(log) Summing total elapsed time ..."
    telapse=$(${BIN_DIR}/sum.sh telapse.txt)
    echo "$(log) TELAPSE = $telapse"

    #  Update the keywords
    echo "$(log) Updating header keywords in og_spi.fits"
    ${FTOOLS}/fthedit og_${inst_idx}.fits operation=add keyword=TSTART value=$tstart
    ${FTOOLS}/fthedit og_${inst_idx}.fits operation=add keyword=TSTOP value=$tstop
    ${FTOOLS}/fthedit og_${inst_idx}.fits operation=add keyword=TELAPSE value=$telapse
    ${FTOOLS}/fthedit og_${inst_idx}.fits operation=add keyword=OGID value='myobs'
    ${FTOOLS}/fthedit og_${inst_idx}.fits operation=add keyword=OBS_ID value=''
    ${FTOOLS}/fthedit og_${inst_idx}.fits operation=add keyword=PURPOSE value=''


    ##  Update relevant header keywords in pointing.fits
    echo "$(log) Updating header keywords in pointing.fits"
    n_points=$(${FTOOLS}/fkeyprint swg_idx_spi.fits[1] NAXIS2 | tail -1 | awk '{print $3}')
    ${FTOOLS}/fthedit pointing.fits[1] operation=add keyword=PT_NUM value=$n_points
    ${FTOOLS}/fthedit pointing.fits[1] operation=add keyword=ISOC_NUM value=$n_points


    ##  Create the scw directory and links to the data
    echo "$(log) Creating links to scw data"
    mkdir scw
    cd scw
    cat ../list_swg_spi.txt | while read line
    do
      scw_dir=$(echo $line | sed s/"swg_spi.fits"//g)
      ln -s ${scw_dir}
    done
    cd ..


    ##  Prepare the catalog
    cp ${INT_DIR}/osa_support/spi_cat_all_sources.fits .
#    ${INT_DIR}/skygrid/select_spi_sources.sh

    echo "$(log) Preparation complete"

    ;;

esac


##  Make mosaic
case ${instrument} in

  ISGRI|IBIS)

    ##  Make the mosaic
    ${INT_DIR}/mosaics/${processing} ${band}

    ## Prepare the catalog based on the imaging results
    fcopy "isgri_srcl_res.fits[1][DETSIG >= 7.0 && NEW_SOURCE == 0]" isgri_specat.fits

    ##  Run spectral extraction
#    ${PIPELINE_DIR}/ibis_analysis_SPE.sh
    ;;

  JMX1|JMX2)

    if [[ ! -e ../../diffs.txt || -s ../../diffs.txt ]]
    then
      ${INT_DIR}/mosaics/${processing} ${band}
    fi
    ;;

  SPI)

    ${INT_DIR}/skygrid/${processing}
    ;;

esac

##  Cleanup 
case ${instrument} in
  ISGRI)
    /bin/rm rebinned*;
    gzip *mosa_ima.fits
    ;;
  JMX1|JMX2)
    gzip *mosa_ima.fits
    ;;
  SPI)
    ;;
esac

##  Move back two levels into $output_mosa_dir
cd ../../

##  Remove the OSA links and pfiles
#/bin/rm -r ic idx cat aux scw pfiles

##  Go back to where we started from
cd $START_DIR
