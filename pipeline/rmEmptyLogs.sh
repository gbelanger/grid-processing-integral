#!/bin/bash

cd logs/error/
for file in `ls`
do
  if [ ! -s $file ]
  then
      rm $file
  fi
done
cd ..
