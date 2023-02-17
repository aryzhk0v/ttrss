# TinyTinyRSS

Docker compose file and env templates for self-hosted TinyTinyRSS instance

## Deployment

See https://git.tt-rss.org/fox/ttrss-docker-compose.git/tree/README.md

## Backups
### Set up

Add to /etc/crontab
```
58 0 * * * username /home/username/repos/ttrss-docker/ttrss-backup.sh /home/username/backups/ttrss >> /var/log/ttrss-backup.log 2>&1
```
### Restore

```
cd  ~/backups/ttrss
tar -zxvf backup.tar.gz tmp/postgres.sql.gz
cd ~/repos/ttrss
source .env
docker exec -i ttrss-docker_db_1 psql -U $TTRSS_DB_USER $TTRSS_DB_NAME -e -c "drop schema public cascade; create schema public"
zcat ~/backups/ttrss/tmp/postgres.sql.gz | docker exec -i ttrss-docker_db_1 psql -U $TTRSS_DB_USER $TTRSS_DB_NAME
```
