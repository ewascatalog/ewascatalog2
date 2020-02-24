## Makefile requires settings for variables FILE_DIR, WEBSITE_DIR and the database

FILE_DIR=../files
## A copy of the FILE_DIR folder is here: /projects/MRC-IEU/research/projects/ieu1/wp2/004/working/data/data-files-for-ewascatalog2

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
## make installr
##   install R in the container
## make database 
##   create and populate the database for access

## Other useful commands:
## 
## make docker-stop
##   stop the docker container
## make docker-rm
##   delete the docker container


all:
	make website
	make docker-build
	make docker-start
	make installr
	make database

website: $(WEBSITE_DIR)/manage.py

$(WEBSITE_DIR)/manage.py: website/website/website/*.py
$(WEBSITE_DIR)/manage.py: website/website/catalog/*.py
$(WEBSITE_DIR)/manage.py:
	bash website/install.sh $(WEBSITE_DIR) $(FILE_DIR) $(SETTINGS)

DOCKER_FILES=Dockerfile docker-compose.yml python-requirements.txt

docker-build: $(WEBSITE_DIR)/manage.py
docker-build: $(addprefix docker/,$(DOCKER_FILES))
docker-build:
	cp $(addprefix docker/, $(DOCKER_FILES)) $(WEBSITE_DIR)
	cd $(WEBSITE_DIR); docker-compose build

docker-start: $(WEBSITE_DIR)/manage.py
docker-start: $(addprefix $(WEBSITE_DIR)/,$(DOCKER_FILES))
docker-start:
	cd $(WEBSITE_DIR); docker-compose up -d

installr:
	cp docker/install-r.sh $(WEBSITE_DIR)
	docker-compose exec -w /code/ dev.ewascatalog \
		bash install-r.sh

database:
	cp -rv database $(WEBSITE_DIR}
	docker-compose-mount $(FILES_DIR) as volume at /files
	docker-compose exec -w /code/database dev.ewascatalog_db \
		bash create.sh ../settings.env /files
	docker-compose-release volume mounted at /files

docker-stop:
	cd $(WEBSITE_DIR); docker-compose stop

docker-rm:
	cd $(WEBSITE_DIR); docker-compose rm

## to do: command to update database
## to do: command to update website code


