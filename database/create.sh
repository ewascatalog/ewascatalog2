#!/bin/bash

SETTINGS=$1

source ${SETTINGS}

FILE=${FILE_DIR}/cpg_annotation.txt
Rscript --vanilla create-cpg-annotation.r ${FILE}

FILE=$(FILE_DIR)/gene_annotation.txt
Rscript --vanilla create-gene-annotation.r ${FILE}

##########################################################
## Initialise database
mysql -uroot -p${DATABASE_ROOT_PASSWORD} <<EOF
drop database if exists `${DB}`;
create database ${DB};
grant select on *.* to '${DATABASE_USER}'@'localhost' identified by '${DATABASE_PASSORD}';
EOF

##########################################################
## Create CpG table
mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD} $DB < create-cpg-table.sql

mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/cpg_annotation.txt' INTO TABLE cpgs LINES TERMINATED BY '\n' IGNORE 1 LINES" --database=$DB

###########################################################
## Create gene table
mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD} $DB < create-gene-table.sql

mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/gene_annotation.txt' INTO TABLE genes LINES TERMINATED BY '\n' IGNORE 1 LINES" --database=$DB


###########################################################
## Create EWAS table
mysql $DB < create-ewas-table.sql

mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/published-ewas/studies.txt' INTO TABLE studies LINES TERMINATED BY '\n' IGNORE 1 LINES" --database=$DB

mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/published-ewas/results.txt' INTO TABLE results LINES TERMINATED BY '\n' IGNORE 1 LINES" --database=$DB

mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/aries-ewas/studies.txt' INTO TABLE studies LINES TERMINATED BY '\n' IGNORE 1 LINES" --database=$DB

mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/aries-ewas/results.txt' INTO TABLE results LINES TERMINATED BY '\n' IGNORE 1 LINES" --database=$DB


