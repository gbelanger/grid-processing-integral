#!/bin/bash

LD_LIBRARY_PATH=/opt/sw/osa11.2-rhel8_test/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
# OSA software
#OSA_INSTALL=/opt/sw/osa11.2-rhel6
OSA_INSTALL=/opt/sw/osa11.2-rhel8_test
export OSA_INSTALL

# ISDC env
ISDC_ENV=${OSA_INSTALL}
export ISDC_ENV

REP_BASE_PROD=$PWD
export REP_BASE_PROD

##  Data location (using new netapp volume)
DATA_PATH="/integral/data/rev_3"
export DATA_PATH

##  Create link to most recent catalogs
ln -sf ${DATA_PATH}/cat

cd cat/hec
file=`ls -tr *fits | tail -1`
cd ../../
ISDC_REF_CAT=${DATA_PATH}/cat/hec/${file}\[1]
export ISDC_REF_CAT

cd cat/omc
file=`ls -tr *fits | tail -1`
cd ../../
ISDC_OMC_CAT=${DATA_PATH}/cat/omc/${file}\[1]
export ISDC_OMC_CAT

##  Create links for SCW and AUX data files
ln -sf ${DATA_PATH}/scw
ln -sf ${DATA_PATH}/aux

##  Create links for IC and IDX files
ln -sf ${DATA_PATH}/ic
ln -sf ${DATA_PATH}/idx

### IMPORTANT

# When changing OSA versions, delete ~/pfiles directory

PFILES=${ISDC_ENV}/pfiles:$PFILES
if [ ! -d ${REP_BASE_PROD}/pfiles ] ; then
  mkdir ${REP_BASE_PROD}/pfiles
fi
cp ${ISDC_ENV}/pfiles/*.par ${REP_BASE_PROD}/pfiles/
PFILES=${REP_BASE_PROD}/pfiles:$PFILES
export PFILES

ROOTSYS=${ISDC_ENV}/root
export ROOTSYS

LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${OSA_INSTALL}/root/lib
export LD_LIBRARY_PATH

### Other ISDC ENV
. ${ISDC_ENV}/bin/isdc_init_env.sh

COMMONLOGFILE=+osa.log
export COMMONLOGFILE

COMMONSCRIPT=1
export COMMONSCRIPT

PATH=${ISDC_ENV}/bin:${ROOTSYS}/bin:$PATH
export PATH
