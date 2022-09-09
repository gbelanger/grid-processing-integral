#!/bin/bash

while true ; do

  # Running
  status="r"
  nRunning=`qstat -u intportalowner | awk '{print $5}' | egrep $status | cat -n | tail -1 | awk '{print $1}'`
  if [[ $nRunning == "" ]] ; then nRunning=0 ; fi

  # Queued
  status="qw"
  nQueued=`qstat -u intportalowner | awk '{print $5}' | egrep $status | cat -n | tail -1 | awk '{print $1}'`
  if [[ $nQueued == "" ]] ; then nQueued=0 ; fi

  # Print info
  date=`date`
  echo "$nRunning running, $nQueued in the queue ($date)"

  # Wait before checking again
  sleep 300
done
