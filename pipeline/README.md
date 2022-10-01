# README file for /home/intportalowner/integral/pipeline

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

#### SPI
1. `spi_analysis_BIN.sh`


##  Useful utility scripts

### printGoodRevs.sh

Creates a list of revolution numbers from the arguments `first` and `last` with output filename `revs-first-last.lis`

Usage: ./printGoodRevs.sh first last (outputs to revs-first-last.lis)

Example: ./printGoodRevs.sh 26 2500


### makeListForRev.sh

Usage: ./makeListForRev.sh rev path/to/point.lis

Example: ./makeListForRev.sh 2500 /home/int/intportalowner/integral/osa_support/point.lis


### Grid job management

1. killQueuedJobs.sh
1. killAllJobs.sh
1. rmEmptyLogs.sh
1. rmAllLogs.sh
1. lowerPriorityOfQueuedJobs.sh
