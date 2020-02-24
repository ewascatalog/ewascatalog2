# EWAS Catalog

Instructions, code and data for installing the EWAS Catalog.

This repository contains all code related to the EWAS Catalog.
The catalog website and database is installed by [Makefile] commands
in a docker container. 

> The file [not-docker.md] contains information about
> installing the EWAS Catalog outside of a docker container.

Files are divided into the following directories:

- `published-ewas`: collected published EWAS summary statistics
- `website`: website python code (Django)
- `database`: scripts for creating and populating the database from data found in the ${FILES_DIR} (see below)
- `docker`: initialization files and scripts for installing the website and database within a docker container
- `r-package`: R package for accessing the database
- `logo`: logo graphics files

## Environment

Required variables for defining the environment can be found in `settings.env`.
A copy is located here:
```
/projects/MRC-IEU/research/projects/ieu1/wp2/004/working/scripts/ewascatalog2/settings.env
```
You will need to at least set `WEBSITE_DIR` (the location of the running website when running)
and `FILE_DIR` (the location of data files used to populate the database). 

The file [Makefile] defines the system pipeline.
You will need to make sure it can find `settings.env`.

## Running docker commands

For a user to run docker commands,
they will need to belong to the 'docker'
linux permissions group.
```
sudo usermod -a -G docker [USER]
```
For this change to take effect, the user
will need to logout and then login.

## Installing the catalog as docker container

The entire pipeline is defined in [Makefile].
To build the entire catalog system from
files to running container, running the following
command in the current directory.

```
make all
```

This command is defined as the following sequence of 'make' commands:

1. `make website`: copies the website to a requested directory (`WEBSITE_DIR` defined in `settings.env`).
2. `make docker-build`: copy docker files to the website and builds the docker container.
3. `make docker-start`: starts the docker container running.
4. `make installr`: installs R in the running container.
5. `make database`: copies database-related scripts to the container and then creates and populates the database.

## Managing the docker container

### Stopping the container
```
make docker-stop
```

### Deleting the container

If the container is no longer needed or should be re-created,
then the current container should be deleted:
```
make docker-rm
```

### Database access port and hostname

The port and hostname for the database can be found in
`/etc/mysql/my.cnf` or `/etc/mysql/mysql.conf.d/mysqld.cnf`
in the container.
You may need to update this information in `settings.env`.

### Accessing the container website

First obtain the container IP address.
```
docker inspect dev.ewascatalog | grep '"IPAddress"' | head -n 1
```
Make sure that this address is permitted in `website/website/settings.py`.

The URL on the local machine to the website will be
the IP address followed by ":8000".  
Note that the port is set in the 'gunicorn'
startup command in docker/docker-compose.yml.

### Command-line access to the docker container

To get bash shell access to running container:
```
docker exec -it dev.ewascatalog bash
```

### Copying files to the container

```
docker cp local-file dev.ewascatalog:/destination-directory
```

## **To do**

* Not known how published EWAS summary statistics get from
  'published-ewas/study-files/' to the tables in
  'files/published-ewas/'.  

* Not known where the ARIES and GEO EWAS summary statistics come from.
  For ARIES, they just magically appear in a table in
  'files/aries-ewas/'. In fact, we may want a single procedure for all 
  EWAS with full summary data.  

* In general, need a single method for
  adding summary data to the database, this includes full statistics
  from GEO and ARIES as well as published studies (not sure there is
  a reason to have separate procedures and database tables for these).
