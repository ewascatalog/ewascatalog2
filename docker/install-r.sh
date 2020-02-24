#!/bin/bash

apt update
apt install -y dirmngr apt-transport-https ca-certificates software-properties-common gnupg2
apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/'
apt update
apt install -y r-base

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
Rscript -e "BiocManager::install('BiomaRt')"
Rscript -e "devtools::install_github('https://github.com/perishky/meffil')"

