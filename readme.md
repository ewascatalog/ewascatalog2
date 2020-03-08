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
variables `FILES_DIR`, `WEBSITE_DIR` and `SETTINGS` in [Makefile](Makefile).

`FILES_DIR` should provide the path to the directory
containing catalog data files.
A copy of this directory is here:
```
/projects/MRC-IEU/research/projects/ieu1/wp2/004/working/data/data-files-for-ewascatalog2
```

`WEBSITE_DIR` should provide the path to the base directory
where the website files will be located on the host machine.

`SETTINGS` should provide the path to the `settings.env` file
described earlier.

That single step is actually composed of a sequence of several sub-steps:

1. `make website`: copies the website to `WEBSITE_DIR`
2. `make docker-build`: copy docker files to the website and build the docker container
3. `make docker-start`: start the docker container running
4. `make r`: install R in the running container
5. `make database`: create and populate the database with EWAS summary statistics

## Navigating to the website

The website can be found at `localhost:8080`
or `[host IP address]:8080` or `[host name]:8080`.

## Making changes

Changes to the repository can be reflected in the running EWAS catalog as follows:

- `website/`: Run `make update-website` and reload the website in the browser.
  This will copy the files to the running website
  and restart the 'web' docker service (defined [docker/docker-compose.yml](docker/docker-compose.yml)).
- `database/`: This is more complicated. Details can be found [database/readme.md](database/readme.md).
- `docker/`: Probably need to stop and start the whole thing (i.e. `make docker-stop` and then `make docker-start`).
- `webserver/`: Run `make update-webserver` and reload the website in the browser.
  This will copy the files to the running website
  and restart the 'nginx' docker service (defined [docker/docker-compose.yml](docker/docker-compose.yml)).

Note that the running website will be accessing files in `WEBSITE_DIR`.
It is possible to edit files in `WEBSITE_DIR/catalog/static`
and `WEBSITE_DIR/catalog/template` directly and observe the effects.
Query-generated TSV files will appear here: `WEBSITE_DIR/catalog/static/tmp`.

To completely take the whole system down and rebuild,
it will need to be stopped (`make docker-stop`),
the docker containers deleted (`make docker-rm`),
the files deleted (`sudo rm -r WEBSITE_DIR`),
and rebuilt (`make all`).

## Command-line access to running docker containers

To get bash shell access to the website running in the container:
```
docker exec -it dev.ewascatalog bash
```

For debugging purposes, it may be useful to look at:
- web server (`docker exec -it dev.ewascatalog_srv`) logs in `/var/log/nginx`.
- mysql (`docker exec -it dev.ewascatalog_db`) files in: `/var/db/mysql/`.

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

## Next steps

### To do

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
    
### Errors
    
* 'Acetoacetate' is an ARIES EWAS trait but searching for it produces 
  no results.

* Searching for gene names only works if the name is in all caps.

* When ZOOMA is down you can't search for traits in the database at all.

### New features

* Create an intermediate page between search and results that allows the 
  user to refine their query (e.g. related trait, particular study).

* Enrichment test for a set of CpG sites
