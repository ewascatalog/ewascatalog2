#!/bin/bash

DB=$1
FILE_DIR=$2  

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mysql $DB < ${SRC_DIR}/create-gene-table.sql
mysql -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/gene_annotation.txt' INTO TABLE cpgs LINES TERMINATED BY '\n' IGNORE 1 LINES" --database=$DB
