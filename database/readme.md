# EWAS Catalog database

The scripts in this directory are for creating and populating the database.

The scripts are all copied to the docker container by the
[Makefile](../Makefile)
and then, in the container,
`create-annotations.sh` is executed to create
CpG and gene annotation text files
and `create.sh` is executed to
create and populate the database.

`create-annotations.sh` generates files
`cpg-annotation.txt` and `gene-anntoation.txt` using R scripts
(in the `FILES_DIR` directory defined in [Makefile](../Makefile)).

`create.sh` uses these files to create the 'cpgs' and 'genes'
tables and files from `${FILES_DIR}/published-ewas` to create
the 'results' and 'studies' tables.

**Note**: These scripts are written so that each creation
command (create file/database/table) will be skipped if
the file/database/table has already been created.
If the item needs to be recreated, then it should be deleted.

```
## gain command-line access to the mysql container
docker exec -it dev.ewascatalog_db bash
## load variables for database access
source /code/settings.env
ROOT_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
## delete the entire database!
${ROOT_CMD} ${DB} -e "drop database ${DB}" 
## or just delete the cpgs table
${ROOT_CMD} ${DB} -e "drop table cpgs"
## recreate anything that was deleted using updated code/data files
make database
```

It is possible to get direct access to the running database
and experiment with changes.
```
## start a bash session in the database container
docker exec -it dev.ewascatalog_db bash
## start a mysql session (see settings.env for password) 
mysql -uroot -p${MYSQL_ROOT_PASSWORD} ewascatalog
```
