#!/bin/bash

set -ex

if [ -z "$1" ]; then
    echo "Please specify a project name"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Please specify an environment"
    exit 2
fi

PROJECT=$1
ENV=$2

if [ -z "$3" ]; then
  DB_NAME=$ENV
else
  DB_NAME=$3
fi

if [ ! -e ~/Project/$PROJECT/magento2 ]; then
  echo "Project directory doesn't exist"
  exit 4
fi

if ! grep -q "Host $PROJECT.$ENV" ~/.ssh/config ; then
    echo "No valid host found in ssh-config"
    exit 3
fi

HOST=$(grep "Host $PROJECT.$ENV" ~/.ssh/config | grep -v '#' | awk '{print $2}' | xargs | awk '{print $1}')

if [ -z "$4" ]; then
  ssh "$HOST" bash -c "'
  if [ ! -d backup ]; then
    mkdir backup
  fi

  if [ ! -d bin ]; then
    mkdir bin
  fi'"

  scp ~/bin/magento2-backup.sh "$HOST":bin/magento2-backup.sh

  DATETIME=`date -u +"%Y%m%d%H%M"`
  ssh "$HOST" bash -c "'

  if [ -d magento2 ]; then
    cd magento2
  fi

  if [ -d public ]; then
    cd public
  fi

  if [ -d public_html ]; then
    cd public_html
  fi

  if [ -d html ]; then
    cd html
  fi

  if [ -d /var/www/html ]; then
    cd /var/www/html
  fi

  chmod +x ~/bin/magento2-backup.sh
  ~/bin/magento2-backup.sh -m db -o ~/backup/ -n $PROJECT.$DB_NAME.magento2.$DATETIME

  '"

  if [ ! -d ~/Project/$PROJECT/db ]; then
    mkdir -p ~/Project/$PROJECT/db
  fi

  cd ~/Project/$PROJECT/db
else
  DATETIME=$4
fi

if [ -z "$5" ]; then
  scp $HOST:backup/$PROJECT.$DB_NAME.magento2.$DATETIME.sql.gz ./
fi

gzip -d $PROJECT.$DB_NAME.magento2.$DATETIME.sql.gz > /dev/null || echo

mysql -e "create database if not exists ${PROJECT}_${DB_NAME}_magento2_${DATETIME}"
mysql ${PROJECT}_${DB_NAME}_magento2_${DATETIME} < $PROJECT.$DB_NAME.magento2.$DATETIME.sql
mysql ${PROJECT}_${DB_NAME}_magento2_${DATETIME} -e "update core_config_data set value = \"https://$PROJECT-m2.127.0.0.1.xip.io/\" where path like \"%base_url\";"
mysql ${PROJECT}_${DB_NAME}_magento2_${DATETIME} -e "delete from core_config_data where path = 'dev/static/sign';"
mysql ${PROJECT}_${DB_NAME}_magento2_${DATETIME} -e "insert into core_config_data (path, value) values ('dev/static/sign', 0);"
mysql ${PROJECT}_${DB_NAME}_magento2_${DATETIME} -e "delete from core_config_data where path like \"dev/%s/merge%s\";"

gzip $PROJECT.$DB_NAME.magento2.$DATETIME.sql &

#cd ~/Project/$PROJECT/magento2
#php bin/magento deploy:mode:set developer
#php bin/magento cache:clean
#php bin/magento cache:flush
