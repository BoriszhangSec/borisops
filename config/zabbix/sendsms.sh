#!/bin/sh
#echo "$3"|/data/scripts/zabbix/mail.py -s "$2"  -t "$1"
echo `date +"%Y-%m-%d %H:%M:%S"` >>/tmp/sms
Content="$2 $3"
Mobile=$1
SMSurl="http://msgw.intra.umessage.com.cn:7000/sms/single?UserName=mmtest&Password=mmtest&AppCode=99100001&ReceiveType=2&DestTermID=$Mobile&FeeTermID=13699154185"
echo $Mobile $Content >> /tmp/sms
/usr/bin/curl -s -d MessageContent="$Content" "$SMSurl" >>/tmp/sms 2>&1
