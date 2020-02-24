# Instructions for installing the web server (optional)

These instructions are only needed to make the website available
via an Apache2 webserver outside of docker container.

## Install necessary packages

```
sudo apt-get update
sudo apt-get install apache2 libapache2-mod-wsgi-py3
```

## Give server access to the website files

To give the server access to website files,
they will need to belong to group 'www-data'.
To change group ownership, the current user
will need to belong to the 'www-data' group.
```
sudo usermod -a -G www-data [USER]
```

Now set file permissions:
```
chmod -R o-rwx ${WEBSITE_DIR}
chgrp -R www-data ${WEBSITE_DIR}
chmod -R g-w ${WEBSITE_DIR}
chmod -R g+w ${WEBSITE_DIR}/catalog/static/tmp
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

Install the necessary Python packages:
```
pip install -r ../docker/python-requirements.txt
```

Deactivate the virtual environment.
```
deactivate
```

## Install apache virtual host config file

Below we convert the template config file
to match our configuration defined by `settings.env`
and copy it to the apache2 configuration directory:
```
set -a
. ${SETTINGS} && envsubst < 000-default.template > 000-default.conf
set +a
sudo mv 000-default.conf /etc/apache2/sites-available/
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

Finally the website Django server must be (re)started.
```
python ${WEBSITE_DIR}/manage.py runserver
```
