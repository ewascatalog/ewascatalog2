# Instructions for installing the web server

**Note**: these instructions are somewhat generic, will need some customizing.

## Install necessary packages
```
sudo apt-get update
sudo apt-get install apache2 libapache2-mod-wsgi-py3
```

## Create directory to save Django app
For now we'll call it `~/myproject`.

## Create virtual environment
```
virtualenv myprojectenv
```

## Activate virtual environment
```
source myprojectenv/bin/activate
```

## Create app and deactivate
```
deactivate
```

## Install apache config file
```
cp apache2-files/000-default.conf /etc/apache2/sites-available
```

## Restart, start and stop apache2
```
sudo service apache2 restart
sudo service apache2 start
sudo service apache2 stop
```

## Enable/disable virtual hosts
```
sudo a2ensite example.com.conf
sudo a2dissite example.com.conf
```

## Enable WGSI module
```
sudo a2enmod wsgi
```

For further details see: https://www.digitalocean.com/community/tutorials/how-to-serve-django-applications-with-apache-and-mod_wsgi-on-ubuntu-14-04


## Start the EWAS catalog

```
run web django-admin.py startproject ewas .
python manage.py runserver
```

## To delete temporary files periodically ...

Create a script `/remove.sh` that deletes temporary files.
```
#!/bin/bash
 
find /catalog/static/tmp/* -mmin +1 -exec rm -f {} \;
find /catalog/templates/catalog/tmp/* -mmin +1 -exec rm -f {} \;
```

Add the following the /etc/crontab file:
```
00 * * * * root /remove.sh
```
