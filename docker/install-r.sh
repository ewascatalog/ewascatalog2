#!/bin/bash

WEBSITE_DIR="$1"

cd ${WEBSITE_DIR}

## install R in the 'web' application
## this is defined in docker-compose.yml

DOCKEXEC="docker-compose exec web"
${DOCKEXEC} apt-get update
${DOCKEXEC} apt-get install -y dirmngr apt-transport-https ca-certificates software-properties-common gnupg2
${DOCKEXEC} apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
${DOCKEXEC} add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/'
${DOCKEXEC} apt-get update
${DOCKEXEC} apt-get install -y r-base

## the following are required for typical R packages
${DOCKEXEC} apt install libcurl4-openssl-dev
${DOCKEXEC} apt install libxml2-dev
${DOCKEXEC} apt install libssl-dev
${DOCKEXEC} apt install libcairo2-dev
${DOCKEXEC} apt install libxt-dev

