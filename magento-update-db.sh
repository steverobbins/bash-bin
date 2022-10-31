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

if [ -z "$4" ]; then
  DATETIME=`date -u +"%Y%m%d%H%M"`
  ssh "$HOST" bash -c "'
  if [ ! -d backup ]; then
    mkdir backup
  fi

  if [ ! -d bin ]; then
    mkdir bin
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
else
  DATETIME=$4
fi

if [ -z "$5" ]; then
  scp $HOST:backup/$PROJECT.$DB_NAME.magento.$DATETIME.sql.gz ./
fi

gzip -d $PROJECT.$DB_NAME.magento.$DATETIME.sql.gz > /dev/null || echo

mysql -e "create database if not exists ${PROJECT}_${DB_NAME}_magento_${DATETIME}"
mysql ${PROJECT}_${DB_NAME}_magento_${DATETIME} < $PROJECT.$DB_NAME.magento.$DATETIME.sql

gzip $PROJECT.$DB_NAME.magento.$DATETIME.sql &

cd ~/html/$PROJECT
~/bin/mage-local.py $PROJECT ${PROJECT}_${DB_NAME}_magento_${DATETIME}
