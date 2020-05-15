#!/bin/bash

# BEFORE THIS SCRIPT REPORT SHOULD HAVE BEEN GENERATED!
# could be worth doing the subsetting and report at the same time...
# At end of report can just say, check report and if it's good then
# can run second part of adding EWAS

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}
# source ${FILE_DIR}/ewas-sum-stats/ewas-to-add.sh

declare -a NEW_DATA=()

# add in new directories to add!
PUB_PATH=/ewas-sum-stats/published/to-add
for dir in ${FILE_DIR}${PUB_PATH}/*/     # list directories in the form "/tmp/dirname/"
do
    dir=${dir%*/}
    echo $dir
    NEW_DATA+=($dir)
    # NEW_DATA+=($PUB_PATH}/${dir##*/})      # remove the trailing "/"
    # echo ${dir##*/}    # print everything after the final "/"
done

NEW_DATA+=() # add filepath of summary stats completed in-house here

echo "${NEW_DATA[@]}"

for dir in "${NEW_DATA[@]}"
do
	echo ${dir}

	Rscript prep-new-data.r "${dir}" "${FILE_DIR}"
done
