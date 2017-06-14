#!/bin/sh

usage (){
	echo "Usage: `basename $0` hostname"
	exit
}
if [ $# -ne 1 ];then
	usage
fi

nameserver=`grep -v "#" /etc/resolv.conf | wc -l`
if [ ${nameserver} -eq 0 ];then
	echo "Please Configure NameSever"
	exit
fi

if [ ! -d "/opt/rpm" ];then
	echo "Please mkdir /opt/rpm "
	exit
fi

installfile="install.error" 
#configure hostname
hostname=$1
hostname $hostname
sed -i 's/streamocean/$hostname/g' /etc/sysconfig/network | grep $hostname /etc/sysconfig/network >>  $installfile 2>&1 &

#adjust system time
/etc/init.d/ntpd stop >> $installfile 2>&1 &
ntpdate 0.centos.pool.ntp.org >> $installfile 2>&1 &
/etc/init.d/ntpd start >> $installfile 2>&1 &
chkconfig ntpd on

#yum install deps
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
cp /opt/rpm/epel.repo /etc/yum.repos.d/
cp /opt/rpm/centos-sohu.repo /etc/yum.repos.d/
yum install java-1.6.0-openjdk --nogpgcheck -y >> $installfile 2>&1 &
yum install openssl-devel --nogpgcheck -y >> $installfile 2>&1 &
yum install python26 --nogpgcheck -y >> $installfile 2>&1 &
yum install python26-mysqldb  --nogpgcheck -y  >> $installfile 2>&1 &
yum install python26-zmq  --nogpgcheck -y >> $installfile 2>&1 &

#install rpm 
cd /opt/rpm
/etc/init.d/streamocean stop >> $installfile 2>&1 &
rpm -e SO-StreamSense-3.4-11996 SO-StreamSense-debuginfo-3.4-11996  --nodeps >> $installfile 2>&1 &
rpm -ivh SO-StreamSense-3.6.1-15728.x86_64.rpm SO-StreamSense-debuginfo-3.6.1-15728.x86_64.rpm  >> $installfile 2>&1 &
rpm -ivh rsyslog-5.8.5-120322.x86_64.rpm >> $installfile 2>&1 &
rpm -ivh zabbix-1.8.16-2.x86_64.rpm >> $installfile 2>&1 &
rpm -ivh zabbix-agent-1.8.16-2.x86_64.rpm  >> $installfile 2>&1 &

#deploy rsyslog
rm /etc/rsyslog.conf
cp /opt/rpm/rsyslog.conf /etc
chkconfig rsyslog on >> $installfile 2>&1 &
chkconfig syslog off >> $installfile 2>&1 &
/etc/init.d/syslog stop >> $installfile 2>&1 &
/etc/init.d/rsyslog restart >> $installfile 2>&1 &

#deploy zabbix
rm -f /SO/zabbix/bin/* 
cp zabbix-bin.tgz /SO/zabbix/bin
cp zabbix_agentd.conf /SO/zabbix/etc 
cd /SO/zabbix/bin
tar -xzvf zabbix-bin.tgz >> $installfile 2>&1 &

#Change core dump file dir
rm /video/ -rf
mkdir /v01/video
ln -s /v01/video /video >> $installfile 2>&1 &

#Add crontab
echo '*/2 * * * * if [ `/etc/init.d/zabbix-agentd status | grep -E "stop|locked" | grep -v "grep" | wc -l` -ne 0 ];then /etc/init.d/zabbix-agentd restart >> /tmp/zabbix_agentd.log 2>& 1; fi' >>  /var/spool/cron/root
echo "# Service Monitor crontab" >>  /var/spool/cron/root
echo "*/3 * * * * /SO/zabbix/bin/monitor_service.sh" >>  /var/spool/cron/root

rpm -qa | egrep "SO|zabbix|rsyslog"
echo "Need to Configure SO zabbix rsyslog"
