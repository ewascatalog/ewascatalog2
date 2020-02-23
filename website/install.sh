#!/bin/bash

WEBSITE_DIR="$1"
FILE_DIR="$2"
SETTINGS="$3"

## Prepare to copy
mkdir -p ${WEBSITE_DIR}

## delete old versions 
rm -rf ${WEBSITE_DIR}/*

## copy the website files
cp -rv website/website/* ${WEBSITE_DIR}

## copy over settings.env
cp ${SETTINGS} ${WEBSITE_DIR}

## create directory for temporary files
mkdir -p ${WEBSITE_DIR}/catalog/static/tmp

## copy ewas catalog download file
mkdir -p ${WEBSITE_DIR}/catalog/static/docs
cp ${FILE_DIR}/catalog-download/ewascatalog.txt.gz \
   ${WEBSITE_DIR}/catalog/static/docs

## set file permissions for web server
chmod -R o-rwx ${WEBSITE_DIR}
chgrp -R www-data ${WEBSITE_DIR}
chmod -R g-w ${WEBSITE_DIR}
chmod -R g+w ${WEBSITE_DIR}/catalog/static/tmp
