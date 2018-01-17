#!/bin/bash

set -e

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

if [ ! -e ~/html/$PROJECT ]; then
  echo "Project html directory doesn't exist"
  exit 4
fi

if ! grep -q "Host $PROJECT.$ENV" ~/.ssh/config ; then
    echo "No valid host found in ssh-config"
    exit 3
fi

HOST=$(grep "Host $PROJECT.$ENV" ~/.ssh/config | grep -v '#' | awk '{print $2}' | xargs | awk '{print $1}')
DATETIME=`date -u +"%Y%m%d%H%M"`
#DATETIME=201711292226

ssh "$HOST" bash -c "'
if [ ! -d backup ]; then
  mkdir backup
fi

if [ ! -d bin ]; then
  mkdir bin
fi

if [ ! -f bin/magento-backup.sh ]; then
  cd bin
  wget https://gist.github.com/steverobbins/b68308b7323d53664f72/raw/e10a8ea4107f2ace189f193661911fd75391a553/magento-backup.sh
  chmod +x magento-backup.sh
  cd ..
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

~/bin/magento-backup.sh -m db -o ~/backup/ -n $PROJECT.$DB_NAME.magento.$DATETIME

'"

if [ ! -d ~/Project/$PROJECT/db ]; then
  mkdir -p ~/Project/$PROJECT/db
fi

cd ~/Project/$PROJECT/db

scp $HOST:backup/$PROJECT.$DB_NAME.magento.$DATETIME.sql.gz ./

gzip -d $PROJECT.$DB_NAME.magento.$DATETIME.sql.gz

mysql -e "create database ${PROJECT}_${DB_NAME}_magento_${DATETIME}"
mysql ${PROJECT}_${DB_NAME}_magento_${DATETIME} < $PROJECT.$DB_NAME.magento.$DATETIME.sql

gzip $PROJECT.$DB_NAME.magento.$DATETIME.sql &

cd ~/html/$PROJECT
~/bin/mage-local.py $PROJECT ${PROJECT}_${DB_NAME}_magento_${DATETIME}
