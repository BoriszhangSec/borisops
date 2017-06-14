#!/bin/bash

##########################################
#This script is used to gather information
#when Server is down
#########################################
#set -x

CALIDUS_PROCS="bootstrap|launch-mgr|cns-mgr|mcache-mgr|dcache-mgr|ustream-mgr|ustream-scanner|caal-mgr|ses-server|sesmgr-scanner|ustream-mgr|us-engine-00|us-engine-01|us-engine-02|us-engine-03|sessvr-conn|cnsmgr-scanner|caal-scanner|csal-scanner|ce-scanner|ce-netin|ce-aio|pp-manifest|pp-scanner|chnl-cache|cc-scanner|gen-hinter-mgr|ses-cfgupdate|trans-agent|llb_dispatcher|vc-mgr|vc-scanner|vc-ingest|linear-svr"
date=`date +%Y%m%d%H%M%S`
dir=/root/serverInfo/${date}
session=${dir}/session.info
connection=${dir}/connection.info
process=${dir}/process.info
top=${dir}/top.info

`mkdir -p $dir`;
echo "Please wait for gathering infomation";

#Get Service IP
if [ "`/sbin/ifconfig|grep "bond"`" != "" ];then
	if [ "`/sbin/ifconfig|grep "lo:1"`" != "" ];then
		ipaddr=`/sbin/ifconfig | grep -A1 lo:1 | grep addr: | cut -d":" -f2 | cut -d" " -f1`
	elif [ "`/sbin/ifconfig|grep "bond0:0"`" != "" ];then
                ipaddr=`/sbin/ifconfig | grep -A1 bond0:0 | grep addr: | cut -d":" -f2 | cut -d" " -f1`
	else
		ipaddr=`/sbin/ifconfig | grep -A1 bond0 | grep addr: | cut -d":" -f2 | cut -d" " -f1`
	fi
elif [ "`/sbin/ifconfig|grep "eth0:0"`" != "" ];then
	ipaddr=`/sbin/ifconfig | grep -A1 eth0:0 | grep addr: | cut -d":" -f2 | cut -d" " -f1`
else
	ipaddr=`/sbin/ifconfig | grep -A1 eth0 | grep addr: | cut -d":" -f2 | cut -d" " -f1`	
fi

#Processes Info
ipcs >> $process;
ps -eL | egrep $CALIDUS_PROCS >> $process;
lsmod | grep kse >> $process;
echo "Process Finished";

#Tar /var/log/message
tar czf ${dir}/message.tar.gz /var/log/messages.* > /dev/null 2&>1;
echo "Tar Finished"

#System and Software info
rpm -qa | grep SO >> $top;
uname -a >> $top;

#Memory Info
echo "Memory Info" >> $top;
free -m >> $top;
echo "Memory Finished";

#Top Info
echo `/bin/ps ax | grep "/SO/bin/" | grep -v grep | sed 's/^ //g' | cut -d" " -f1` > ${dir}/process.pid;
/bin/sed -i 's/ /,/g' ${dir}/process.pid;
pid=(`cat ${dir}/process.pid`);
top -d 5 -n 4 -H -b -p $pid >>$top;
echo "Top Finished";

#System Connections
httpnumber=`netstat -ntp | grep "${ipaddr}:80" | grep -v "127.0.0.1" | wc -l`;
rtspnumber=`netstat -ntp | grep "${ipaddr}:554"| grep -v "127.0.0.1" | wc -l`;
echo "HTTP number is $httpnumber. RTSP number is $rtspnumber" >> $connection;
netstat -ntp | grep ":80" | grep -v "127.0.0.1" >> $connection;
netstat -ntp | grep ":554"| grep -v "127.0.0.1" >> $connection;
echo "Connection Finished";

#System Sessions
python noccmd.py localhost DUMP_SESSIONS >> /dev/null
SOVDNSession=`python noccmd.py localhost CURRENT_CONNS | grep CURRENT_CONNS | grep result  | cut -d"[" -f3 | cut -d"]" -f1`
sed -i "1i\SOVDNSession number is $SOVDNSession."  /SO_logs/btrace/ses_list.log;
mv /SO_logs/btrace/ses_list.log ${dir};
echo "Session Finished";

echo "All Finished.You can get all info in $dir"
