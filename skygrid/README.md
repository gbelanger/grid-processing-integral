# README file for /home/intportalowner/integral/skygrid

## Launching script for mosaics

There are two launching scripts:

1. `launch_single_mosaic.sh`
1. `launch_many_mosaics.sh`


### launch_single_mosaics.sh (and launch_many_mosaics.sh)

The script `launch_many_mosaics.sh` simply loops on the list and calls `launch_single_mosaic.sh`

The script `launch_single_mosaic.sh` calls the parent analysis script `run_integ_mosa.sh`

These launching scripts are called as follows:

./launch_many_mosaics.sh scwFileList instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82)

./launch_single_mosa.sh field/field_1.lis instrument (ISGRI|JMX1|JMX2) band (e.g., 20-35|46-82)


#### IBIS

#### JMX

#### SPI

## 

## Launching scripts for time series

There is only one launching script

1. `launch_timeseries_fullmission.sh`

./launch_timeseries_fullmission.sh srcname.lst band (e.g.,20-35|46-82) instrument (ISGRI|JMX1|JMX2)

### JMX

#### JMX1
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 46-82 JMX1
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 83-153 JMX1
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 154-224 JMX1

#### JMX2
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 46-82 JMX2
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 83-153 JMX2
./launch_timeseries_fullmission.sh ../refcat/jmx/jmx_cat_0043_names.txt 154-224 JMX2
