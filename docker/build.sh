#!/bin/bash

set -a

SETTINGS="$1"
source ${SETTINGS}
shift
DOCKER_FILES="$@"

## copy docker container files to the website directory
cp ${DOCKER_FILES} ${WEBSITE_DIR}

## replace variables in 'docker-compose.yml' with values
## found in 'settings.env'
set -a
. ${SETTINGS} && envsubst < docker/docker-compose.yml > ${WEBSITE_DIR}/docker-compose.yml
set +a

## build the container
cd ${WEBSITE_DIR}
docker-compose build

set +a



