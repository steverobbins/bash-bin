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

if ! grep -q "Host $PROJECT.$ENV" ~/.ssh/config ; then
    echo "No valid host found in ssh-config"
  
    exit 3
fi

HOST=$(grep "Host $PROJECT.$ENV" ~/.ssh/config | grep -v '#' | awk '{print $2}' | xargs | awk '{print $1}')

ssh "$HOST" bash -c "'

if [ ! -d bin ]; then
  mkdir bin
fi

if [ ! -f bin/magerun ]; then
  cd bin
  wget https://files.magerun.net/n98-magerun.phar
  mv n98-magerun.phar magerun
  chmod +x magerun
fi

'"
