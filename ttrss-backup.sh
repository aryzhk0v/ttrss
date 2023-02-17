#!/usr/bin/env bash 


set -x
src_dir=$(dirname "$0")
dest_dir=$1

cd $src_dir
if [[ -f ".env" ]]; then
	echo "${src_dir}/.env exists"
else
	echo "$src_dir/.env does not exist"
	exit 1
fi

[ -d $dest_dir ] || mkdir -p $dest_dir

tmp_dir=tmp
[ -d $tmp_dir ] || mkdir -p $tmp_dir

source .env
docker exec -t --user=postgres ttrss-docker_db_1 pg_dump $TTRSS_DB_NAME | gzip -9 > ${tmp_dir}/${TTRSS_DB_NAME}.sql.gz
docker exec -t --user app ttrss-docker_app_1 /var/www/html/tt-rss/update.php --opml-export admin:admin-$(date '+%F').opml
docker cp  ttrss-docker_app_1:/var/www/html/tt-rss/admin-$(date '+%F').opml .
cp -a .env $tmp_dir
cp -a admin-$(date '+%F').opml $tmp_dir
tar -zcvf $(date '+%F').tar.gz $tmp_dir

rm ./$tmp_dir/.env
rm ./$tmp_dir/$TTRSS_DB_NAME.sql.gz
rm ./$tmp_dir/admin-$(date '+%F').opml
rmdir ./$tmp_dir
mv $(date '+%F').tar.gz $dest_dir
