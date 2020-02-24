If the EWAS Catalog is being installed outside of a docker container,
MySQL, R and an Apache web server will need to be installed and configured,
the database created and populated, and the website installed.

## MySQL

```
apt install mysql-server
mysql_secure_installation
# settings.env:MYSQL_ROOT_PASSWORD
```

Start up the mysql server:
```
systemctl start mysql
```

Check that is running:
```
systemctl status mysql.service
```

The port and hostname for the database can be found in
`/etc/mysql/my.cnf` or `/etc/mysql/mysql.conf.d/mysqld.cnf`.
You may need to update this information in `settings.env`.

## Install R

On an Ubuntu system, you'll need to do something like this:
```
sudo apt-get update
sudo apt-get install -y dirmngr apt-transport-https ca-certificates software-properties-common gnupg2
sudo apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/'
sudo apt-get update
sudo apt-get install -y r-base
```

To install typical R packages, you'll need to install:
```
sudo apt install libcurl4-openssl-dev
sudo apt install libxml2-dev
sudo apt install libssl-dev
sudo apt install libcairo2-dev
sudo apt install libxt-dev
```

## Create and populate the database

```
cd database; bash create.sh ${SETTINGS}
```
Here `${SETTINGS}` is the location of `settings.env`.

**Note:** This script may fail because it is meant to be run in a
docker container where 'sudo' or root access is not required.

## Install the website

```
bash website/install.sh $(WEBSITE_DIR) $(FILE_DIR) ${SETTINGS}
```

Here `${SETTINGS}` is the location of `settings.env`, and
`${WEBSITE_DIR}` and `${FILE_DIR}` are defined in `settings.env`.

## Web server

See [../webserver/readme.md](../webserver/readme.md). 
