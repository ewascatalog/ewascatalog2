This directory contains instructions and miscellaneous files for
getting the website running in a docker container.  Needs organizing and
corresponding code added to `../Makefile` so that it is automated as
much as possible.

## If docker is not installed (on an Ubuntu machine)

Remove anything out-of-date:
```
sudo apt-get remove docker docker-engine docker.io
```

Install docker:
```
sudo apt install docker.io
```

Setup docker to run automatically at startup:
```
sudo systemctl start docker
sudo systemctl enable docker
```

## Create docker container

In the main project directory, 
create `Dockerfile` specifying commands to build the container,
`requirements.txt` to define python dependencies,
`docker-compose.yml` specifying required services
(web server and database). 


```
cd ${WEBSITE_DIR}
docker-compose build
```


## Start the container

```
cd ${WEBSITE_DIR}
docker-compose up -d
```

To stop it, just run `docker-compute stop`.



```
# Add EWAS Catalog MySQL database
docker exec -i ewascatalog_db mysql -uroot -p${DATABASE_ROOT_PASSWORD} < ./mysql/initial/database.sql
docker exec -i ewascatalog_db mysql -uroot -p${DATABASE_ROOT_PASSWORD} ${DATABASE_NAME} < ./mysql/cpgs/cpgs.sql
docker exec -i ewascatalog_db mysql -uroot -p${DATABASE_ROOT_PASSWORD} ${DATABASE_NAME} < ./mysql/genes/genes.sql
docker exec -i ewascatalog_db mysql -uroot -p${DATABASE_ROOT_PASSWORD} ${DATABASE_NAME} < ./mysql/catalog/refresh.sql
docker exec -i ewascatalog_db mysql -uroot -p${DATABASE_ROOT_PASSWORD} ${DATABASE_NAME} < ./mysql/catalog/19-07-03/database.sql
docker exec -i ewascatalog_db mysql -uroot -p${DATABASE_ROOT_PASSWORD} ${DATABASE_NAME} < ./mysql/aries/refresh.sql
docker exec -i ewascatalog_db mysql -uroot -p${DATABASE_ROOT_PASSWORD} ${DATABASE_NAME} < ./mysql/aries/catalog/database.sql

# Docker-compose up
docker-compose up -d

# R download
# Add the following to the Dockerfile:
RUN apt-get update
RUN apt-get install -y dirmngr apt-transport-https ca-certificates software-properties-common gnupg2
RUN apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/'
RUN apt-get update
RUN apt-get install -y r-base

# Sometimes the following needs to be re-copied: RUN apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
# To install an R package: RUN R -e "install.packages('dplyr', repos = 'http://cran.us.r-project.org')"
```