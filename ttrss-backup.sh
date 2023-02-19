#!/usr/bin/env bash 

#set -x

print_usage () {
	echo "Usage: $0 /backups/destination/dir"
	echo "Or add the script to /etc/crontab:"
	echo "Example:"
	echo "58 0 * * * username /home/username/repos/ttrss-docker/ttrss-backup.sh /home/username/backups/ttrss >> /var/log/ttrss-backup.log 2>&1"
}

logger () {
	LOG_TIMESTAMP=$(date "+%F %T")
	echo "[$LOG_TIMESTAMP]: $1"
}

do_backup () {
	cd $SRC_DIR
	if [[ -f ".env" ]]; then
		logger "${SRC_DIR}/.env exists OK"
	else
		logger "${SRC_DIR}/.env does not exist ERROR"
		exit 1
	fi
	[ -d $DEST_DIR ] || mkdir -p $DEST_DIR
	[ -d $TMP_DIR ] || mkdir -p $TMP_DIR
	source .env
	docker exec -t --user=postgres ttrss-docker_db_1 pg_dump $TTRSS_DB_NAME  > ${TMP_DIR}/${TTRSS_DB_NAME}.sql
	EXIT_CODE=$?
	if [ $EXIT_CODE -eq 0 ]; then
		logger "Postgres dump OK"	
		PG_DUMP_STATUS="OK"
	else
		logger "Postgres dump ERROR"
		PG_DUMP_STATUS="ERROR"
	fi
	gzip -9 ${TMP_DIR}/${TTRSS_DB_NAME}.sql
	docker exec -t --user app ttrss-docker_app_1 /var/www/html/tt-rss/update.php --opml-export admin:admin-${TIMESTAMP}.opml > /dev/null 2>&1
	EXIT_CODE=$?
	if [ $EXIT_CODE -eq 0 ]; then
		logger "OPML dump OK"	
		OPML_STATUS="OK"
	else
		logger "OPML dump ERROR"
		OPML_STATUS="ERROR"
	fi
	docker cp  ttrss-docker_app_1:/var/www/html/tt-rss/admin-${TIMESTAMP}.opml ./$TMP_DIR > /dev/null 2>&1
	EXIT_CODE=$?
	if [ $EXIT_CODE -eq 0 ]; then
		logger "OPML copy OK"	
	else
		logger "OPML copy ERROR"
		OPML_STATUS="ERROR"
	fi
	cp -a .env $TMP_DIR
	EXIT_CODE=$?
	if [ $EXIT_CODE -eq 0 ]; then
		logger ".env copy OK"	
		ENV_STATUS="OK"
	else
		logger ".env copy ERROR"
		ENV_STATUS="ERROR"
	fi
	tar -zcf ${TIMESTAMP}.tar.gz $TMP_DIR
	EXIT_CODE=$?
	if [ $EXIT_CODE -eq 0 ]; then
		logger "tar OK"	
		TAR_STATUS="OK"
	else
		logger "tar ERROR"
		TAR_STATUS="ERROR"
	fi
}

do_cleanup () {
	rm ./$TMP_DIR/.env
	rm ./$TMP_DIR/$TTRSS_DB_NAME.sql.gz
	rm ./$TMP_DIR/admin-${TIMESTAMP}.opml
	rmdir ./$TMP_DIR
	mv ${TIMESTAMP}.tar.gz $DEST_DIR
}

main () {
	logger "backup started"

	SRC_DIR=$(dirname "$0")
	DEST_DIR=$1

	PG_DUMP_STATUS=""
	OPML_STATUS=""
	ENV_STATUS=""
	TAR_STATUS=""
	BACKUP_STATUS_FILE=/var/log/ttrss-backup.status

	TIMESTAMP=$(date '+%F')
	TMP_DIR=$TIMESTAMP

	if [[ -z "$DEST_DIR" ]]; then
		print_usage
		exit 1
	fi
	do_backup
	do_cleanup
	logger "backup finished"
	echo "PG DUMP - $PG_DUMP_STATUS : OPML - $OPML_STATUS : ENV - $ENV_STATUS : TAR : $TAR_STATUS" > $BACKUP_STATUS_FILE
}

main "$@"
