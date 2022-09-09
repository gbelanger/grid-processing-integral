qstat -u intportalowner  | egrep '^[0-9]' | egrep qw | awk '{print $1}' | xargs qdel
