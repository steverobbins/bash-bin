#!/bin/bash

date

echo

uptime

echo

cat /proc/meminfo | head -n 3

echo

sensors -f
