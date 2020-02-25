# EWAS Catalog website

Instructions, code and data for installing the EWAS Catalog.

This repository contains all code related to the EWAS Catalog.
The catalog website and database is installed by [Makefile](Makefile) commands
in a docker container. 

Files are divided into the following directories:

- `published-ewas`: collected published EWAS summary statistics
- `website`: website python code (Django)
- `database`: scripts for creating and populating the database from data found in the `FILES_DIR` (see below)
- `docker`: initialization files and scripts for installing the website and database within a docker container
- `webserver`: configuration files for the webserver
- `r-package`: R package for accessing the database
- `logo`: logo graphics files

## Environment

Variables for the accessing the database can be found in `settings.env`.
A copy is located here:
```
/projects/MRC-IEU/research/projects/ieu1/wp2/004/working/scripts/ewascatalog2/settings.env
```

## Running docker commands

The system will run within a Docker container. 

For a user to run docker commands,
they will need to belong to the 'docker'
linux permissions group.
```
sudo usermod -a -G docker [USER]
```
For this change to take effect, the user
will need to logout and then login.

## Building the EWAS Catalog

The entire pipeline is defined in [Makefile](Makefile)
and the catalog can be built with the following command
(when the current directory is the base directory
of this repository):

```
make all
```

*Before* running it, however, you will need to assign values to
`FILES_DIR`, `WEBSITE_DIR` and `SETTINGS`.

`FILES_DIR` should provide the path to the directory
containing catalog data files.
> A copy of this directory is here:
> /projects/MRC-IEU/research/projects/ieu1/wp2/004/working/data/data-files-for-ewascatalog2

`WEBSITE_DIR` should provide the path to the base directory
where the website files will be located on the host machine.

`SETTINGS` should provide the path to the `settings.env` file
described earlier.

That single step is actually composed of a sequence of several sub-steps:

1. `make website`: copies the website to `WEBSITE_DIR`
2. `make docker-build`: copy docker files to the website and build the docker container
3. `make docker-start`: start the docker container running
4. `make r`: install R in the running container
5. `make database`: create and populates the database with EWAS summary statistics

## Navigating to the website

The website can be found at `localhost:8080`
or `[host IP address]:8080` or `[host name]:8080`.

## Making changes

Files used by the system can be found and modified in `WEBSITE_DIR`.
For example, the query-generated TSV can be found in `WEBSITE_DIR/catalog/static/tmp`.
The contents of some files can be changed while the system runs
without having to restart.

Some changes will require restarting or rebuilding the container
to have effect:

- `make docker-stop`: stop the container.  It can be restarted with `make docker-start`.
- `make docker-rm`: remove the container.  To be started again, it will need to be rebuilt.
  This command is needed if you want to make major changes to the system.

## Command-line access to docker

To get bash shell access to the website running in the container:
```
docker exec -it dev.ewascatalog bash
```

For debugging purposes, it may be useful to look at:
- web server (`dev.ewascatalog_srv`) logs in `/var/log/nginx`.
- mysql (`dev.ewascatalog_db`) files in: `/var/db/mysql/`.

## Database access port 

The files `docker/docker-compose.yml` and `settings.env`
refer to a port for accessing the MySQL database.
It should match ports referenced in 
`/etc/mysql/my.cnf` or `/etc/mysql/mysql.conf.d/mysqld.cnf`
of the container.

## Container IP address

The container IP address is typically '172.17.0.3', but
this can be verified:
```
docker inspect dev.ewascatalog | grep -e '"IPAddress"' | head -n 1 | sed 's/[^0-9.]*//g'
```

## **To do**

* Not known how published EWAS summary statistics get from
  'published-ewas/study-files/' to the tables in
  'files/published-ewas/'.  

* Not known where the ARIES and GEO EWAS summary statistics come from.
  For ARIES, they just magically appear in a table in
  'files/aries-ewas/'. In fact, we may want a single procedure for all 
  EWAS with full summary data.  

* Need a single method for
  adding summary data to the database, this includes full statistics
  from GEO and ARIES as well as published studies (not sure there is
  a reason to have separate procedures and database tables for these).

* Should have a command in the Makefile for creating a backup of the
  container. Building is pretty quick except for installing R packages ...