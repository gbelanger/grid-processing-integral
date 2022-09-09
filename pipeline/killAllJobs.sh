qstat -u intportalowner | awk '{print $1}' | egrep '^[0-9]' | xargs qdel
