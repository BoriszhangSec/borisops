#!/bin/bash

date=`date +%Y%m%d`
for dbname in `mysql -uroot -pSOSPV1StorageMySQL -e "show databases;" | grep -Evi "database|infor|perfor"`
do
    #echo $dbname
    mysqldump -uroot -p'SOSPV1StorageMySQL' --events -B $dbname | gzip > /opt/cronjob/mysql_bak/${date}_${dbname}.sql.gz
done

/usr/bin/find /opt/cronjob/mysql_bak -name "*.sql.gz" -mtime +7 | /usr/bin/xargs rm -f
