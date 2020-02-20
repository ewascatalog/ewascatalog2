#!/bin/bash

DB=$1
FILE_DIR=$2  
SETTINGS=$3

source ${SETTINGS}

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mysql -e "drop database if exists `${DB}`"
mysql -e "create database ${DB}"
mysql -e "grant all privileges on *.* to '${DATABASE_USER}'@'localhost' identified by '${DATABASE_PASSWORD}'"

bash ${SRC_DIR}/create-cpg-table.sh ${DB} ${FILE_DIR}
bash ${SRC_DIR}/create-gene-table.sh ${DB} ${FILE_DIR}
bash ${SRC_DIR}/create-ewas-table.sh ${DB} ${FILE_DIR}

echo "${DB} created" `date` > $1
