#!/bin/bash


date=`date "+%y%m%d%H%M"`
dataname="${date}_so_ad_detect.sql"

#echo $date
#echo $dataname

mysqldump -uroot -pdb -B so_ad_detect > /tmp/${dataname}
scp /tmp/${dataname} bjw:/tmp
ssh bjw "ls /tmp/${dataname}"
ssh bjw "scp /tmp/${dataname} vp:/tmp"
ssh bjw "ssh vp mysql -uroot -pdb < /tmp/${dataname}"

localcounts=`mysql -uroot -pdb -e "select count(*) from so_ad_detect.ad_ref_t;"`
vpcounts=`ssh bjw ssh vp sh /application/show_vp_so_ad_detect.sh`

echo "SO villa 172.16.1.238: $localcounts"
echo "Sanyuanqiao vp: $vpcounts"

rm -f /tmp/${dataname}
ssh bjw "rm -f /tmp/${dataname}"
ssh bjw "ssh vp rm -f /tmp/${dataname}"
