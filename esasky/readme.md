# Update observation list for esasky

## Why

To do an automatic update of the observations list based on the pod files delivered with in the data. 

## How

Runs as cron job on intggw6.n1grid.lan; 
the executable called in the cron job is

/home/int/intportalowner/integral/bin/update_observations_list

It contains the following lines that call two other scripts 

/data/int/isoc5/gbelange/isocArchive/bin/db_compile_pod_files.sh
/data/int/isoc5/gbelange/isocArchive/bin/db_process_master_pod_file.sh
cp /data/int/isoc5/gbelange/isocArchive/pod_info/observations.dat $HOME/integral/esasky/
scp observations.dat intuser@ammiext.n1data.lan:observations_list/

The last line secure-copies the updated file to the esasky server under the user intuser.
I have generated a public key on intggw6, and added it to authorized_keys in ~/.ssh/ on ammiext.
This allows scp to work without password prompting.
