#!/bin/bash

fdump ScwDB_reduced_filterGTI.fits.gz[1] ScwDB_reduced_filterGTI_ScWID_tmp.txt prhead=no column=ScWID rows=- showcol=no showunit=no showrow=no clobber=yes

grep '[^[:blank:]]' < ScwDB_reduced_filterGTI_ScWID_tmp.txt > ScwDB_reduced_filterGTI_ScWID.txt

rm ScwDB_reduced_filterGTI_ScWID_tmp.txt
