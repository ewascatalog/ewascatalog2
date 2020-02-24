#!/bin/bash

apt update
apt upgrade 
apt install -y dirmngr apt-transport-https ca-certificates software-properties-common gnupg2
apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian buster-cran35/'
  ## this repository name should match the debian version found in /etc/apt/sources.list
apt update
apt install -y r-base r-base-dev

## the following are required for typical R packages
apt install libcurl4-openssl-dev
apt install libxml2-dev
apt install libssl-dev
apt install libcairo2-dev
apt install libxt-dev

Rscript -e "install.packages('data.table')"
Rscript -e "install.packages('Hmisc')"
Rscript -e "install.packages('dplyr')"
Rscript -e "install.packages('devtools')"
Rscript -e "install.packages('BiocManager')"
Rscript -e "BiocManager::install('biomaRt')"
Rscript -e "devtools::install_github('https://github.com/perishky/meffil')"

