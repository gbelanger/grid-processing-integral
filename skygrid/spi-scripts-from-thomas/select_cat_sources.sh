#!/bin/bash

# deg to rad conversion
d2r=0.01745329251

# cos of 24 deg (chosen to be useful radius of field of view 8+16)
cos24=0.9135454576426009

function angular_distance_query() {
    #echo "pointing position: $1 $2"
    #echo "source position:   $3 $4"

    angle_arg=$(bc -l <<< "s($2 * $d2r) * s($4 * $d2r) + c($2 * $d2r) * c($4 * $d2r) * c(($1 - $3) * $d2r)")

    #echo "The angle argument is: $angle_arg"
    #echo "cos of 24 deg is:     $cos24"

    if (( $(echo "$angle_arg > $cos24" |bc -l) )); then
	#echo "The source is INSIDE the FoV."
	echo "1"
    else
	#echo "The source is OUTSIDE the FoV."
	echo "0"
    fi


}


fsumrows pointing.fits[1] pointing_average.fits cols=RA_SPIX,DEC_SPIX rows=- operation=AVG


for i in {1..256}
do
    src_ra=$(fdump spi_cat_all_source_spimodfit_test.fits[1] STDOUT prhead=no column=RA_OBJ row=$i showcol=no showunit=no showrow=no)
    src_ra=$(sed 's/\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)/(\1*10^\2\3)/g' <<< "$src_ra")

    src_dec=$(fdump spi_cat_all_source_spimodfit_test.fits[1] STDOUT prhead=no column=DEC_OBJ row=$i showcol=no showunit=no showrow=no)
    src_dec=$(sed 's/\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)/(\1*10^\2\3)/g' <<< "$src_dec")

    src_name=$(fdump spi_cat_all_source_spimodfit_test.fits[1] STDOUT prhead=no column=NAME row=$i showcol=no showunit=no showrow=no)
    #echo "SRC RA:  $src_ra deg"
    #echo "SRC DEC: $src_dec deg"

    poin_ra=$(fdump pointing_average.fits[1] STDOUT prhead=no column=RA_SPIX row=1 showcol=no showunit=no showrow=no)
    poin_ra=$(sed 's/\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)/(\1*10^\2\3)/g' <<<"$poin_ra")
    poin_dec=$(fdump pointing_average.fits[1] STDOUT prhead=no column=DEC_SPIX row=1 showcol=no showunit=no showrow=no)
    poin_dec=$(sed 's/\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)/(\1*10^\2\3)/g' <<<"$poin_dec")

    qry=$(angular_distance_query $poin_ra $poin_dec $src_ra $src_dec)

    echo "$src_name $qry"

    if (( $(echo "$qry == 1" | bc -l) )); then
        echo "The source is INSIDE the FoV. Setting SEL_FLAG to 1."
	# nothing to do since starting with all sources included
	ftedit spi_cat_all_source_spimodfit_test.fits[1] column=SEL_FLAG row=$i value=1 
    else
        echo "The source is OUTSIDE the FoV. Setting SEL_FLAG to 0."
        # using ftedit iteratively to change SEL_FLAG values:
	ftedit spi_cat_all_source_spimodfit_test.fits[1] column=SEL_FLAG row=$i value=0 
    fi

done

