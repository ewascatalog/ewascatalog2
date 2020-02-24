#!/bin/bash

apt-get update
apt-get install -y dirmngr apt-transport-https ca-certificates software-properties-common gnupg2
apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/'
apt-get update
apt-get install -y r-base

## the following are required for typical R packages
apt install libcurl4-openssl-dev
apt install libxml2-dev
apt install libssl-dev
apt install libcairo2-dev
apt install libxt-dev

