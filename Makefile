## Makefile requires settings for variables FILE_DIR, WEBSITE_DIR and DB. 
## These can be found in the following file:
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
	make r
	make database

website: $(WEBSITE_DIR)/manage.py

$(WEBSITE_DIR)/manage.py: website/website/website/*.py
$(WEBSITE_DIR)/manage.py: website/website/catalog/*.py
$(WEBSITE_DIR)/manage.py:
	bash website/install.sh $(WEBSITE_DIR) $(FILE_DIR) ${SETTINGS}

startwebsite: $(WEBSITE_DIR)/manage.py
	python3 $< runserver

DOCKER_FILES=Dockerfile docker-compose.yml requirements.txt

docker-build: $(WEBSITE_DIR)/manage.py
docker-build: $(addprefix docker/,$(DOCKER_FILES))
docker-build:
	bash docker/build.sh ${SETTINGS} \
		$(addprefix docker/,$(DOCKER_FILES))

docker-start: $(WEBSITE_DIR)/manage.py
docker-start: $(addprefix $(WEBSITE_DIR)/,$(DOCKER_FILES))
docker-start:
	bash docker/start.sh ${SETTINGS}

installr:
	bash docker/install-r.sh

database:
	cp -rv database $(WEBSITE_DIR}
	docker-compose exec -w /code/database dev.ewascatalog_db \
		bash create.sh ../settings.env

docker-stop:
	bash docker/stop.sh ${SETTINGS}

docker-rm:
	bash docker/rm.sh ${SETTINGS}

## to do: command to update database
## to do: command to update website code

