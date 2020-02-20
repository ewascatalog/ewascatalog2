# Instructions for installing the web server

**Note**: these instructions are somewhat generic, will need some customizing.

## File permissions

The Apache2 web server must be able to write to
the `website/catalog/static/tmp/` directory
and read everything else including `settings.env`.

We can set the file permissions as follows:
```
sudo chmod -R o-rwx ${WEBSITE_DIR}
sudo chgrp -R www-data ${WEBSITE_DIR}
sudo chmod -R g-w ${WEBSITE_DIR}
sudo chmod -R g+w ${WEBSITE_DIR}/catalog/static/tmp
```

## Install necessary packages

```
sudo apt-get update
sudo apt-get install apache2 libapache2-mod-wsgi-py3
```

## Create a Python virtual environment

This is necessary to ensure that Python package version changes
on the computer don't affect this application.
This virtual environment is referenced below in the virtual host
configuration file for the web server.

Initalize the environment.
```
virtualenv -p /usr/bin/python3 ${WEBSITE_DIR}/ewascatalogenv
```

Activate the environment.
```
source ${WEBSITE_DIR}/ewascatalogenv/bin/activate
```

Install the necessary packages by 
running the `../website/install-dependencies.sh` script.
```
bash ../website/install-dependencies.sh
```

Deactivate the virtual environment.
```
deactivate
```

## Install apache virtual host config file

Edit 000-default.conf so that the website directory is correct.
```
sudo cp 000-default.conf /etc/apache2/sites-available/
```

## Restart the webserver

```
sudo service apache2 restart
```

## Enable the virtual host

```
sudo a2ensite 000-default.conf
systemctl reload apache2
```

## Enable WGSI module
```
sudo a2enmod wsgi
```

## Start the EWAS catalog

```
python ${WEBSITE_DIR}/manage.py runserver
```

If something fails, error messages can be found here:
`/var/log/apache2/error.log`.


## Incorporating changes 

The website must be restarted after any changes.  Here are the steps:
```
sudo service apache2 restart
```

If changes to the virtual host file (000-default.conf) were made: 
```
sudo a2ensite 000-default.conf
systemctl reload apache2
```

Finally the website Django server must be restarted.
```
python ${WEBSITE_DIR}/manage.py runserver
```