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
  DB_NAME=$PROJECT
else
  DB_NAME=$3
fi

if ! grep -q "Host mconnect.$ENV" ~/.ssh/config ; then
    echo "No valid host found in ssh-config"
    exit 3
fi

HOST=$(grep "Host mconnect.$ENV" ~/.ssh/config | grep -v '#' | awk '{print $2}' | xargs | awk '{print $1}')

if [ -z "$4" ]; then
  DATETIME=`date -u +"%Y%m%d%H%M%S"`
  ssh "$HOST" bash -c "'
  if [ ! -d backup ]; then
    mkdir backup
  fi

  if [ ! -d bin ]; then
    mkdir bin
  fi

  cd ~/backup/

  mysqldump $PROJECT > $PROJECT.$DB_NAME.mconnect.$DATETIME.sql
  gzip $PROJECT.$DB_NAME.mconnect.$DATETIME.sql

  '"

  if [ ! -d ~/Project/mconnect/db ]; then
    mkdir -p ~/Project/mconnect/db
  fi

  cd ~/Project/mconnect/db
else
  DATETIME=$4
fi

scp $HOST:backup/$PROJECT.$DB_NAME.mconnect.$DATETIME.sql.gz ./

gzip -d $PROJECT.$DB_NAME.mconnect.$DATETIME.sql.gz > /dev/null || echo

mysql -e "create database if not exists ${PROJECT}_${DB_NAME}_mconnect_${DATETIME}"
mysql ${PROJECT}_${DB_NAME}_mconnect_${DATETIME} < $PROJECT.$DB_NAME.mconnect.$DATETIME.sql

gzip $PROJECT.$DB_NAME.mconnect.$DATETIME.sql &

perl -pi -e "s/DB_DATABASE.*/DB_DATABASE=${PROJECT}_${DB_NAME}_mconnect_${DATETIME}/g" /home/steve/Project/mconnect/middleware/.env
