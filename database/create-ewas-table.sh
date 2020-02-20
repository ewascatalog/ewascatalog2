#!/bin/bash

DB=$1
FILE_DIR=$2  

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mysql $DB < ${SRC_DIR}/create-ewas-table.sql

mysql $DB -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/published-ewas/studies.txt' INTO TABLE studies LINES TERMINATED BY '\n' IGNORE 1 LINES"
mysql $DB -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/published-ewas/results.txt' INTO TABLE results LINES TERMINATED BY '\n' IGNORE 1 LINES"

mysql $DB -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/aries-ewas/studies.txt' INTO TABLE studies LINES TERMINATED BY '\n' IGNORE 1 LINES"
mysql $DB -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/aries-ewas/results.txt' INTO TABLE results LINES TERMINATED BY '\n' IGNORE 1 LINES"
