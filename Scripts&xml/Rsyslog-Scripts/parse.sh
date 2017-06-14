#!/bin/bash
cd /SO-AcLog

YEAR=`date +%Y`
MONTH=`date +%m`

nohup find ./$YEAR/ -type f  -ctime -2 |xargs -n 1 awk -f /SO/scripts/logparser.awk > /dev/null 2>&1  &
nohup find ./$YEAR/ -type f  -ctime -2 |xargs -n 1 awk -f /SO/scripts/logparser-local.awk > /dev/null 2>&1  & 
nohup find ./$YEAR/ -type f  -ctime -2 |xargs -n 1 awk -f /SO/scripts/logparser-wan.awk  > /dev/null 2>&1  &

nohup  /SO/scripts/genDaySts.sh > /dev/null 2>&1  &
