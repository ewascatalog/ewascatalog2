#!/bin/bash

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}
source ${FILE_DIR}/ewas-sum-stats/ewas-to-add.sh

ROOT_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
USER_CMD="mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD}"

### ALSO NEED TO ADD AN R SCRIPT TO CHECK DATA IS IN CORRECT FORMAT!
### AND IN RIGHT PLACE!
# -- essentially will look like this:
# - if file doesn't exist stop
# - read in data
# - if colnames don't match allocated colnames stop
# - if data types don't match allocated data types stop

### ADD A LOOPING FUNCTION TO ADD IN NEW DATA!

${ROOT_CMD} ${DB} < add-to-ewas-table.sql
${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/${NEW_DATA}/studies.txt' INTO TABLE new_studies LINES TERMINATED BY '\n' IGNORE 1 LINES"
${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/${NEW_DATA}/results.txt' INTO TABLE new_results LINES TERMINATED BY '\n' IGNORE 1 LINES"

${ROOT_CMD} ${DB} -e "INSERT INTO studies SELECT * FROM new_studies"
${ROOT_CMD} ${DB} -e "INSERT INTO results SELECT * FROM new_results"

### ADD A BASH SCRIPT THAT APPENDS NEW DATA TO COMBINED DATA!