#!/bin/bash

if [[ $# -ne 1 ]] ; then
    echo "Usage: ./getISDCReports.sh listOfRevs.txt"
    exit -1
fi
if [ ! -f $1 ] ; then
    echo "Error: Cannot find file $1"
    exit -1
fi
file=$1
if [ ! -d isdcReports ] ; then mkdir isdcReports ; fi
if [ -f reports.log ] ; then rm reports.log ; fi
cat $file | while read rev ; do 
    if [[ $rev -lt 1000 ]] ; then 
        r=`echo $rev | awk '{print substr($1,2,4)}'` ; 
        wget http://www.isdc.unige.ch/integral/Operations/Shift/Reports/${rev}/Revolution_${r}_Pass_Summary.pdf
    else
        wget http://www.isdc.unige.ch/integral/Operations/Shift/Reports/${rev}/Revolution_${rev}_Pass_Summary.pdf
    fi
    file=`ls Revolution_*_Pass_Summary.pdf`
    if [[ ! -f $file ]] ; then
        echo "$rev : No report" >> reports.log
    else
        mv Revolution* isdcReports/
    fi
done
sort reports.log > tmp
mv tmp reports.log
