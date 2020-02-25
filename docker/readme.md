This folder contains files needed to 'dockerize' the website:
`docker-compose.yml`, `Dockerfile`, `python-requirements.txt`.
These files are copied to the website base directory by the
project `Makefile` before building the docker container.

The remainder of this document gives information
for working with docker.

## If docker is not installed (on an Ubuntu machine) ...

Remove anything out-of-date:
```
sudo apt-get remove docker docker-engine docker.io
```

Install docker:
```
sudo apt install docker.io
sudo apt install docker-compose
```

Setup docker to run automatically at startup:
```
sudo systemctl start docker
sudo systemctl enable docker
```

## Add user to docker group

For a user to run docker commands,
they will need to belong to the docker
linux permissions group.
```
sudo usermod -a -G docker [USER]
```
You will need to log out and then back
in again for this to take effect.


## Save/restore the database (optional)

Save the database (variables defined in settings.env):
```
docker exec dev.ewascatalog_db sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > ${FILES}/database-dump/dump.sql
```

Restore the database:
```
docker exec -i dev.ewascatalog_db sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < ${FILES}/database-dump/dump.sql
```






