# TinyTinyRSS

Docker compose file and env templates for self-hosted TinyTinyRSS instance

## Deployment

See https://git.tt-rss.org/fox/ttrss-docker-compose.git/tree/README.md

## Backups
Backups performed by `ttrss-backup.sh` script located in the project root directory
### Usage:
```
/home/username/repos/ttrss-docker/ttrss-backup.sh /home/username/backups/ttrss
```
The script must be in the same directory with `docker-compose.yml` and `.env` files.
It archives DB dump, feeds in OPML format and `.env` file into tar.gz archive and copies it into destination directory provided as an argument to the script.
After script finishes  `ttrss-backup.status` file created inside the directory the script located in  which contains the info on how each stage of backup proceeded.

### Set up

Add to /etc/crontab
```
58 0 * * * username /home/username/repos/ttrss-docker/ttrss-backup.sh /home/username/backups/ttrss >> /var/log/ttrss-backup.log 2>&1
```
### Restore

```
cd  ~/backups/ttrss
tar -zxvf backup.tar.gz
cd ~/repos/ttrss
source .env
docker exec -i ttrss-docker_db_1 psql -U $TTRSS_DB_USER $TTRSS_DB_NAME -e -c "drop schema public cascade; create schema public"
zcat ~/backups/ttrss/backup/postgres.sql.gz | docker exec -i ttrss-docker_db_1 psql -U $TTRSS_DB_USER $TTRSS_DB_NAME
```
