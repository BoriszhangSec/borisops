#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
logfile="/root/install.log"
check_date=`date -d "-1 min" "+%Y-%m-%d %H:%M"`
check_query="query use time"
check_key="^$check_date.*$check_query"
qutc=5
qutc=`grep -P "$check_key" $logfile |awk -F: '{if(NR==1) nar=$6}; END{print $6-nar} '`
echo $qutc
