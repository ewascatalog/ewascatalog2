## Makefile requires settings for variables FILE_DIR, WEBSITE_DIR and the database

FILES_DIR=../files
## A copy of the FILES_DIR folder is here: /projects/MRC-IEU/research/projects/ieu1/wp2/004/working/data/data-files-for-ewascatalog2

WEBSITE_DIR=../running
## Base directory of the website directory

## Database settings can be found in the settings.env file
##   /projects/MRC-IEU/research/projects/ieu1/wp2/004/working/scripts/ewascatalog2/settings.env
SETTINGS=../settings.env
include $(SETTINGS)

## Commands for building the running the docker container:
## 
## make all
##   execute the entire pipeline (all commands below)
## make website
##   copy the website files to their destination
## make docker-build
##   copy docker files to website
##   and build the docker container
## make docker-start
##   start the docker container running
## make r
##   install R in the container
## make database 
##   create and populate the database for access

## Other useful commands:
## 
## make docker-stop
##   stop the docker container
## make docker-rm
##   delete the docker container

.PHONY: website docker-build docker-start r database docker-stop docker-rm

all:
	make website
	make docker-build
	make docker-start
	make r
	make database

website: $(WEBSITE_DIR)/manage.py

$(WEBSITE_DIR)/manage.py: website/website/website/*.py
$(WEBSITE_DIR)/manage.py: website/website/catalog/*.py
$(WEBSITE_DIR)/manage.py:
	bash website/install.sh $(WEBSITE_DIR) $(FILES_DIR) $(SETTINGS)

DOCKER_FILES=Dockerfile docker-compose.yml python-requirements.txt

docker-build: $(WEBSITE_DIR)/manage.py
docker-build: $(addprefix docker/,$(DOCKER_FILES))
docker-build:
	cp $(addprefix docker/, $(DOCKER_FILES)) $(WEBSITE_DIR)
	FILES_DIR=$(realpath $(FILES_DIR)) envsubst \
	  < docker/docker-compose.yml \
	  > $(WEBSITE_DIR)/docker-compose.yml
	cp -r webserver $(WEBSITE_DIR)
	cd $(WEBSITE_DIR); docker-compose build

docker-start: $(WEBSITE_DIR)/manage.py
docker-start: $(addprefix $(WEBSITE_DIR)/,$(DOCKER_FILES))
docker-start:
	cd $(WEBSITE_DIR); docker-compose up -d

r: docker/install-r.sh docker/install-packages.r
	cp docker/install-r.sh $(WEBSITE_DIR)
	cd $(WEBSITE_DIR); docker-compose exec web \
	        bash -c "cd /code; bash install-r.sh"
	cp docker/install-packages.r $(WEBSITE_DIR)
	cd $(WEBSITE_DIR); docker-compose exec web \
	        bash -c "cd /code; Rscript install-packages.r"
## could save time by saving contents of /usr/local/lib/R/site-library

database:
	cp -rv database $(WEBSITE_DIR)
	cd $(WEBSITE_DIR); docker-compose exec web \
	        bash -c "cd /code/database; bash create-annotations.sh /files"
	cd $(WEBSITE_DIR); docker-compose exec db \
		bash -c "cd /code/database; bash create.sh ../settings.env /files"
## could save time by saving contents of /var/db/mysql/

docker-stop:
	cd $(WEBSITE_DIR); docker-compose stop

docker-rm:
	cd $(WEBSITE_DIR); docker-compose rm


## to do: command to update database
## to do: command to update website code


