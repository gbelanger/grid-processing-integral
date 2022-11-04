# README file for /home/intportalowner/integral/skygrid

The purpose of the scripts in this directory is to combine the results produced by the pipeline processing at the level of each scw. 

This second level processing applies to individual images, time series, and spectra, all of which need to be combined to produce mosaics, or long-term time series and spectra.

## Launching scripts for mosaics

There are 2 mosaics launching scripts:

1. `launch_single_mosaic.sh`
1. `launch_many_mosaics.sh`

### launch_single_mosaics.sh (and launch_many_mosaics.sh)

The script `launch_many_mosaics.sh` simply loops on the list and calls `launch_single_mosaic.sh`

The script `launch_single_mosaic.sh` calls the parent analysis script `run_integ_mosa.sh`

These launching scripts are called as follows:

./launch_many_mosaics.sh scwFileList instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82)

where the `scwFileList` is a file containing a list of filenames each of which is a list of scws defined for a particular point on the sky grid. 

Example: `scw-lists-step-10deg-radius-10deg.filenames`

./launch_single_mosa.sh field/field_1.lis instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82)

where `field/field_1.lis` is the list of scw to use for this mosaic, which must be supplied the correct filename format, as these details that are used to define the output directory and file strucuture. 

Example: `scw-lists-step-10deg-radius-10deg/scw_pt99_131.4386_4.5038_10deg.lis`


#### IBIS
./launch_many_mosaics.sh scw-lists-step-10deg-radius-10deg.filenames ISGRI 20-35
./launch_many_mosaics.sh scw-lists-step-10deg-radius-10deg.filenames ISGRI 35-60
./launch_many_mosaics.sh scw-lists-step-10deg-radius-10deg.filenames ISGRI 60-100

#### JMX
./launch_many_mosaics.sh scw-lists-step-5deg-radius-3deg.filenames JMX1 46-82
./launch_many_mosaics.sh scw-lists-step-5deg-radius-3deg.filenames JMX1 82-153
./launch_many_mosaics.sh scw-lists-step-5deg-radius-3deg.filenames JMX1 154-224

./launch_many_mosaics.sh scw-lists-step-5deg-radius-3deg.filenames JMX2 46-82
./launch_many_mosaics.sh scw-lists-step-5deg-radius-3deg.filenames JMX2 82-153
./launch_many_mosaics.sh scw-lists-step-5deg-radius-3deg.filenames JMX2 154-224


#### SPI 

(this is not ready yet)
 

## Launching scripts for time series

There is only one launching script

1. `launch_timeseries_fullmission.sh`

./launch_timeseries_fullmission.sh srcname.lst band (e.g.,20-35|46-82) instrument (ISGRI|JMX1|JMX2)

### IBIS
./launch_timeseries_fullmission.sh ../refcat/ibis/isgri_cat_0043_names.txt 20-35 ISGRI
./launch_timeseries_fullmission.sh ../refcat/ibis/isgri_cat_0043_names.txt 35-60 ISGRI
./launch_timeseries_fullmission.sh ../refcat/ibis/isgri_cat_0043_names.txt 60-100 ISGRI


### JMX

#### JMX1
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 46-82 JMX1
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 83-153 JMX1
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 154-224 JMX1

#### JMX2
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 46-82 JMX2
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 83-153 JMX2
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 154-224 JMX2


## Analysis scripts for mosaics

### run_integ_mosa.sh

This is the parent script that controls the analysis and calls the various instrument specific processing modules


It calls the instrument-specific OSA processing commands

#### IBIS
- ibis_ima_mosaic.sh

#### JEMX
- jmx1_ima_mosaic.sh
- jmx2_ima_mosaic.sh

#### SPI
- spi_spe_mosaic.sh


## Analysis scripts for time series

### ibis_timeseries.sh

Produces ISGRI time series by extracting values from the scw images

./ibis_timeseries.sh srcname band (20-35|35-60|60-100) /full/path/to/scw.lis

### jmx_timeseries.sh

Produces source time series by combining the results for each scw

./jmx_timeseries.sh srcname band (46-82|83-153|153-224) instrument (JMX1|JMX2) /full/path/to/scw.lis


## Essential utility scripts

### makeLists.sh

This script produces the lists of scw for every point on the skygrid based on the input parameters which specify the angular step size between points and the radius (off-axis angle) for selection of pointings around the grid point.

Usage: ./makeLists.sh step radius

It calls

1. `get-grid-points.py` that generates the grid point in Gal coordinates
1. `Gal2fk5.jar` that converts them to RA, Dec in FK5 coordinates
1. `coords2scwLists.sh` that produces all the lists of scws as well as the file that contains all the file names needed as an argument to `launch_many_mosaics.sh`


=======
## Launching scripts

There are only two launching scripts:

1. `launch_single_rev.sh`
1. `launch_many_revs.sh`

### launch_single_rev.sh

This script calls the analysis script `run_integ_analysis.sh`

./launch_single_rev.sh  processing (ibis_analysis_IMA.sh) rev (e.g., 0053|1630) instrument (ISGRI|JMX1|JMX2|SPI) band (e.g., 20-35|46-82|25-400) overwrite (y|n)

#### IBIS

Overwriting:

./launch_single_rev.sh ibis_analysis_IMA.sh 0053 ISGRI 20-35 y ;
./launch_single_rev.sh ibis_analysis_IMA.sh 0053 ISGRI 35-60 y ;
./launch_single_rev.sh ibis_analysis_IMA.sh 0053 ISGRI 60-100 y ;

Not overwriting:

./launch_single_rev.sh ibis_analysis_IMA.sh 0053 ISGRI 20-35 n ;
./launch_single_rev.sh ibis_analysis_IMA.sh 0053 ISGRI 35-60 n ;
./launch_single_rev.sh ibis_analysis_IMA.sh 0053 ISGRI 60-100 n ;


#### JMX

Overwriting:

./launch_single_rev.sh 0053 JMX2 46-82 y ;
./launch_single_rev.sh 0053 JMX2 83-153 y ;
./launch_single_rev.sh 0053 JMX2 154-224 y ;

Not overwriting:

./launch_single_rev.sh jmx2_analysis_IMA.sh 0053 JMX2 46-82 n ;
./launch_single_rev.sh jmx2_analysis_IMA.sh 0053 JMX2 83-153 n ;
./launch_single_rev.sh jmx2_analysis_IMA.sh 0053 JMX2 154-224 n ;


#### SPI

Overwriting:

./launch_single_rev.sh spi_analysis_BIN.sh 0053 SPI 25-400 y ;

Not overwriting:

./launch_single_rev.sh spi_analysis_BIN.sh 0053 SPI 25-400 n ;


### launch_many_revs.sh

This script loops on the revolutions and calls launch_single_rev.sh

./launch_many_revs.sh revList (rev.lis) processing (e.g., ibis_analysis_IMA.sh) instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82) overwrite (y|n)


#### IBIS

Overwriting:

./launch_many_revs.sh revs-26-2500.lis ibis_analysis_IMA.sh ISGRI 20-35 y ;
./launch_many_revs.sh revs-26-2500.lis ibis_analysis_IMA.sh ISGRI 35-60 y ;
./launch_many_revs.sh revs-26-2500.lis ibis_analysis_IMA.sh ISGRI 60-100 y ;

Not overwriting:

./launch_many_revs.sh revs-26-2500.lis ibis_analysis_IMA.sh ISGRI 20-35 n ;
./launch_many_revs.sh revs-26-2500.lis ibis_analysis_IMA.sh ISGRI 35-60 n ;
./launch_many_revs.sh revs-26-2500.lis ibis_analysis_IMA.sh ISGRI 60-100 n ;


#### JMX

Overwriting:

./launch_many_revs.sh revs-26-2500.lis jmx2_analysis_IMA.sh JMX2 46-82 y ;
./launch_many_revs.sh revs-26-2500.lis jmx2_analysis_IMA.sh JMX2 83-153 y ;
./launch_many_revs.sh revs-26-2500.lis jmx2_analysis_IMA.sh JMX2 154-224 y ;

./launch_many_revs.sh revs-26-2500.lis jmx1_analysis_IMA.sh JMX1 46-82 y ;
./launch_many_revs.sh revs-26-2500.lis jmx1_analysis_IMA.sh JMX1 83-153 y ;
./launch_many_revs.sh revs-26-2500.lis jmx1_analysis_IMA.sh JMX1 154-224 y ;

Not overwriting:

./launch_many_revs.sh revs-26-2500.lis jmx2_analysis_IMA.sh JMX2 46-82 n ;
./launch_many_revs.sh revs-26-2500.lis jmx2_analysis_IMA.sh JMX2 83-153 n ;
./launch_many_revs.sh revs-26-2500.lis jmx2_analysis_IMA.sh JMX2 154-224 n ;

./launch_many_revs.sh revs-26-2500.lis jmx1_analysis_IMA.sh JMX1 46-82 n ;
./launch_many_revs.sh revs-26-2500.lis jmx1_analysis_IMA.sh JMX1 83-153 n ;
./launch_many_revs.sh revs-26-2500.lis jmx1_analysis_IMA.sh JMX1 154-224 n ;


#### SPI

Overwriting:

./launch_many_revs.sh revs-26-2500.lis spi_analysis_BIN.sh SPI 25-400 y ;

Not overwriting:

./launch_many_revs.sh revs-26-2500.lis spi_analysis_BIN.sh SPI 25-400 n ;


##  Analysis script

### run_integ_analysis.sh

This is the most important script that runs the OSA analysis. 

All OSA analysis starts by defining the environment variables using `osa11.setenv.sh`.

. run_integ_analysis.sh processing (e.g., ibis_analysis_IMA.sh) rev (e.g., 0046) instrument (ISGRI|JMX1|JMX2|SPI) band (e.g., 20-35|46-82|25-400)

It calls the instrument-specific OSA pipepine processing commands:

#### IBIS
1. `ibis_analysis_IMA.sh`
1. `ii_pif.sh`
1. `ii_light.sh`
1. `merge_ii_light.sh`

#### JMX
1. `jmx1_analysis_IMA.sh`
1. `jmx2_analysis_IMA.sh`
1. `jmx1_analysis_SPE.sh`
1. `jmx2_analysis_SPE.sh`


##  Useful utility scripts

### Current
- `check_mosaic_completion.sh`
- `count_mosaics.sh`
- `galGridPoints2RaDecName.sh`
- `get_filename_list_to_rerun.sh` produces the filename with the lists of fields to rerun
- `check_ang_dist.sh` computes the angular distance between successive points in a list of coordinates
- `grid2reg.sh` produces a ds9 region file from grid points


### May need updating
- `countRejectedScw.sh` looks in the log files to see how many images were rejected in the selection process