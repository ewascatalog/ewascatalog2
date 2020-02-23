# EWAS Catalog

Instructions, code and data for installing the EWAS Catalog.

## Environment

Required variables for defining the environment can be found in `settings.env`.
A copy is located here:
```
/projects/MRC-IEU/research/projects/ieu1/wp2/004/working/scripts/ewascatalog2/settings.env
```
You will need to at least set `WEBSITE_DIR` (the location of the running website when running)
and `FILE_DIR` (the location of data files used to populate the database). 

The file `Makefile` defines the system pipeline.
You will need to make sure it can find `settings.env`. 

## Database

### Install MySQL

```
apt install mysql-server
mysql_secure_installation
# settings.env:MYSQL_ROOT_PASSWORD
```

### Start the MySQL server
Start up the mysql server:
```
systemctl start mysql
```

Check that is running:
```
systemctl status mysql.service
```

### Install the database

```
make database
```

The port and hostname for the database can be found in
`/etc/mysql/my.cnf` or `/etc/mysql/mysql.conf.d/mysqld.cnf`.
You may need to update this information in `settings.env`.


## Website

### Create the website
```
make website
```

### Ensure python dependencies installed

```
make dependencies
```

### Make the website live

```
make startwebsite
```

## **To do**

* Not known how published EWAS summary statistics get from
  'published-ewas/study-files/' to the tables in
  'files/published-ewas/'.

* Not known where the ARIES and GEO EWAS summary statistics come from.
  For ARIES, they just magically appear in a table in
  'files/aries-ewas/'. In fact, we may want a single procedure for all 
  EWAS with full summary data.  

* Need to add a function to the R package for checking and uploading
  summary statistics for an EWAS.  

* Need a pipeline set up with instructions for adding new data to the
  catalog database.  For published EWAS, there is some information in
  the 'published-ewas/' folder but it needs to be simplified and the
  instructions clearer.

* There are instructions for setting up the webserver (see
  webserver/readme.md), but much of that could be automated
  within the Makfile.

* Add commands to Makefile to get the website running in a docker
  container.

