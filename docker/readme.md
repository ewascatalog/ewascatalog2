This directory contains instructions and miscellaneous files for
getting the website running in a docker container.  Needs organizing and
corresponding code added to `../Makefile` so that it is automated as
much as possible.

## If docker is not installed (on an Ubuntu machine)

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

```
sudo usermod -a -G docker [USER]
```
You will need to log out and then back
in again for this to take effect.

## Navigate to the container website

First obtain the container IP address.
```
docker inspect dev.ewascatalog | grep '"IPAddress"' | head -n 1
```
Make sure that this address is permitted in `website/website/settings.py`.

Access the website here, e.g.
```
lynx [IP-ADDRESS]:8000
```
Note that the port is set in the 'gunicorn'
startup command in docker-compose.yml.

## Access to the docker container

To get bash shell access to running container:
```
docker exec -it dev.ewascatalog bash
```

To copy a file from the host machine into a docker container:
```
docker cp local-file dev.ewascatalog:/destination-directory
```

## Save/restore the database

Save the database (variables refer to settings.env):
```
docker exec ewascatalog_db sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > /some/path/on/your/host/all-databases.sql
```

Restore the database:
```
docker exec -i ewascatalog_db sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /some/path/on/your/host/all-databases.sql
```






