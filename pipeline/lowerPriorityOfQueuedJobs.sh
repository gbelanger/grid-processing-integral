#!/bin/bash

if [ $# -ne 1 ] ; then
  echo "Usage: . lowerPriorityOfQueuedJobs.sh priotity"
  return 1 2>/dev/null
fi
qalter -p -$1 $(qstat | grep -w qw | awk '{print $1}')

