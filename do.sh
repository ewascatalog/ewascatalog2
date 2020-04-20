#!/bin/bash

FILES_DIR=../files
## A copy of the FILES_DIR folder is here: /projects/MRC-IEU/research/projects/ieu1/wp2/004/working/data/data-files-for-ewascatalog2

WEBSITE_DIR=../running
## Base directory of the website directory

## Database settings can be found in the settings.env file
##   /projects/MRC-IEU/research/projects/ieu1/wp2/004/working/scripts/ewascatalog2/settings.env
SETTINGS=../settings.env

CMD="$1"

USER_ID=`id -u`
GROUP_ID=`id -g`
DOCKER_COMPOSE="FILES_DIR=${FILES_DIR} USER_ID=${USER_ID} GROUP_ID=${GROUP_ID} docker-compose"

init_catalog() {
    bash website/install.sh ${WEBSITE_DIR} ${FILES_DIR} ${SETTINGS}
}
build_catalog() {
    cp docker/Dockerfile docker/*.yml docker/*.txt docker/*.r ${WEBSITE_DIR}
    cp -r webserver ${WEBSITE_DIR}
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} build"
}
start_catalog() {
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} up -d"
}
create_database() {
    cp -r database ${WEBSITE_DIR}
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} exec web bash -c 'cd /code/database; bash create-annotations.sh /files'"
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} exec db bash -c 'cd /code/database; bash create.sh ../settings.env /files'"
}
update_website() {
    init_catalog
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} restart web"
}
update_webserver() {
    cp -r webserver ${WEBSITE_DIR}
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} stop nginx"
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} build nginx"
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} start nginx"
}
stop_catalog() {
    cd ${WEBSITE_DIR}; eval "${DOCKER_COMPOSE} stop"
}


if [ ${CMD} = "init" ]; then
    init_catalog
elif [ ${CMD} = "build" ]; then
    build_catalog
elif [ ${CMD} = "start" ]; then
    start_catalog
elif [ ${CMD} = "database" ]; then
    create_database
elif [ ${CMD} = "update" ]; then
    update_website
elif [ ${CMD} = "stop" ]; then
    stop_catalog
elif [ ${CMD} = "all" ]; then
    init_catalog
    build_catalog
    start_catalog
    create_database
else
cat <<EOF
Usage do.sh [init|build|start|database|update|stop|all]

    init: copy the catalog website files to destination
    build: build the catalog docker container
    start: start the catalog running
    database: construct the catalog database
    update: copy the website files and restart the website
    stop: stop the catalog
    all: init->build->start->database
EOF
fi

## delete all docker containers and images
## docker system prune -a
