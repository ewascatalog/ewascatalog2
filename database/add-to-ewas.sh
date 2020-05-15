#!/bin/bash

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}

ROOT_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
USER_CMD="mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD}"

while read id; do
	echo "$id"
	# Make new results and studies tables in the sql database
	${ROOT_CMD} ${DB} < add-to-ewas-table.sql
	${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/ewas-sum-stats/${id}/studies.txt' INTO TABLE new_studies LINES TERMINATED BY '\n' IGNORE 1 LINES"
	${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/ewas-sum-stats/${id}/results.txt' INTO TABLE new_results LINES TERMINATED BY '\n' IGNORE 1 LINES"

	# Add these to the existing studies and results tables
	${ROOT_CMD} ${DB} -e "INSERT INTO studies SELECT * FROM new_studies"
	${ROOT_CMD} ${DB} -e "INSERT INTO results SELECT * FROM new_results"

done <${FILE_DIR}/ewas-sum-stats/studies-to-add.txt

