#!/bin/sh
echo "$3"|/data/scripts/zabbix/mail.py -s "$2"  -t "$1"
echo `date +"%Y-%m-%d %H:%M:%S"` >>/tmp/fz
