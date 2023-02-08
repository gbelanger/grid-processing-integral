qstat -u intportalowner -s p | awk '{print $1}' | egrep '^[0-9]' | xargs qdel
