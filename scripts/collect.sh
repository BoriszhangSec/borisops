#!/bin/bash
export PATH=/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
logs=/var/log/collect.log
date=`date "+%Y-%m-%d %H:%M:%S"`
SNpath="/"
SNfile=`ls $SNpath |grep -E "SN[0-9]{10}"`
collect="/data0/scripts/collect_log.py"
apps=`cat $SNpath$SNfile|grep catalina| awk '{ print $3 }' `
log_uploads="/data0/logs/uploads/$apps"
echo "================= $date start================">>$logs
#cd $log_uploads&&ls $log_uploads|grep *  >/dev/null  2>&1
#`cd $log_uploads&&ls $log_uploads|grep *` 2&1 >/dev/null
#if [ $? -eq 0 ];then
#        echo "python $collect -m onlyupload" >>$logs
#       python $collect -m normal >>$logs
#        python $collect -m onlyupload >>$logs
 #       else
        echo "python $collect -m normal" >>$logs
        python $collect -m normal >>$logs
        echo "python $collect -m onlyupload" >>$logs
        python $collect -m onlyupload >>$logs
#fi
