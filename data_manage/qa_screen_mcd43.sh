#!/bin/bash

# This masks input TIF mcd43 files with the TIF version of the mandatory qa, max value only
# Should be improved in many ways, e.g. specify more than qa=0, intake the HDFs, etc
# Author: Arthur Elmes 2020-08-01

tile=$1

# Set these
in_dir="/ipswich/data01/arthur.elmes/bsky/tif/${tile}"
qa_dir="/ipswich/data01/arthur.elmes/MCD43_mandatory_qa/${tile}"
sza_dir="/ipswich/data01/arthur.elmes/MCD43A2/all/${tile}"
out_dir="/ipswich/data01/arthur.elmes/bsky/tif/qa_screened/${tile}"

if [ ! -d ${out_dir} ]; then
    mkdir $out_dir
fi


for tif in ${in_dir}/*.tif; do 
    filename=$(basename -- ${tif})
    extension="${filename##*.}"
    filename_bare="${filename%.*}"
    date=${filename_bare:9:14}
    tmp_name=${tif}_temp.tif
    out_name=${out_dir}/${filename_bare}_high_qa.tif

    # Find matching qa file
    qa_tif=`find ${qa_dir} -type f -name "*${date}*qa*"`

    # Find previously extracted SZA file
    sza_tif=`find ${sza_dir} -type f -name "*${date}*sza*"`
    
    # This could probably be one step
    gdal_calc.py --format GTiff -A ${tif} -B ${qa_tif} --outfile=${tmp_name} --calc="A*(B==0)"
    gdal_calc.py --format GTiff -A ${tmp_name} --outfile=${tmp_name}_2 --calc="A*(A>0)" --NoDataValue=0
    gdal_calc.py --format GTiff -A ${tmp_name}_2 -B ${sza_tif} --outfile=${out_name} --calc="A*(B<72.0)" --NoDataValue=0

    # For some reason the vrt format is not working, so delete the temporary tifs (this is super non-optimal)
    rm ${tmp_name}
    rm ${tmp_name}_2
done
