if [[ $# -ne 2 ]]
then
  echo "Usage: . get_filename_list_to_rerun.sh scwpt_to_rerun.txt scwLists.filenames"
  return 1
fi

cat $1 | while read pt ; do egrep $pt $2 ; done > fields_to_rerun.filenames
