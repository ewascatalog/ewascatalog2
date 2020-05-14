#!/bin/bash

# BEFORE THIS SCRIPT REPORT SHOULD HAVE BEEN GENERATED!
# could be worth doing the subsetting and report at the same time...
# At end of report can just say, check report and if it's good then
# can run second part of adding EWAS

SETTINGS=$1
FILE_DIR=$2
WEBSITE_DIR=$3

source ${SETTINGS}
# source ${FILE_DIR}/ewas-sum-stats/ewas-to-add.sh

declare -a NEW_DATA=("")

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

NEW_DATA+=("") # add filepath of summary stats completed in-house here

unset 'NEW_DATA[0]' # Remove initial thing in array

echo "${NEW_DATA[@]}"

ROOT_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
USER_CMD="mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD}"

# for file in "${NEW_DATA[@]}"
# do
# 	echo ${file}

# 	# check the data being input is present and that it has the right columns
# 	# Rscript check-ewas-data.r "${file}" "${FILE_DIR}"

# 	# Make new results and studies tables in the sql database
# 	${ROOT_CMD} ${DB} < add-to-ewas-table.sql
# 	${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/${file}/studies.txt' INTO TABLE new_studies LINES TERMINATED BY '\n' IGNORE 1 LINES"
# 	${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/${file}/results.txt' INTO TABLE new_results LINES TERMINATED BY '\n' IGNORE 1 LINES"

# 	# Add these to the existing studies and results tables
# 	${ROOT_CMD} ${DB} -e "INSERT INTO studies SELECT * FROM new_studies"
# 	${ROOT_CMD} ${DB} -e "INSERT INTO results SELECT * FROM new_results"

# done

for dir in "${NEW_DATA[@]}"
do
	echo ${dir}

	# check the data being input is present and that it has the right columns
	# Rscript ${WEBSITE_DIR}/database/prep-new-data.r "${dir}"
	Rscript database/prep-new-data.r "${dir}"
done

while read id; do
	echo "$id"
	# Make new results and studies tables in the sql database
	${ROOT_CMD} ${DB} < add-to-ewas-table.sql
	${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/ewas-sum-stats/${id}/studies.txt' INTO TABLE new_studies LINES TERMINATED BY '\n' IGNORE 1 LINES"
	${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/ewas-sum-stats/${id}/results.txt' INTO TABLE new_results LINES TERMINATED BY '\n' IGNORE 1 LINES"

	# Add these to the existing studies and results tables
	${ROOT_CMD} ${DB} -e "INSERT INTO studies SELECT * FROM new_studies"
	${ROOT_CMD} ${DB} -e "INSERT INTO results SELECT * FROM new_results"

done <study_ids.txt

