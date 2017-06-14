#!/bin/bash
set -o nounset
set +x

###################################################
# Monitoring ZABBIX running status on client side #
###################################################

# Configuration
ERR_NOT_INSTALLED="1"
ERR_ALREADY_RUNNING="2"
INIT_PATH="/etc/init.d"
ZBX_INIT_FILE="$INIT_PATH/zabbix_agentd_ctl"
if [ -e "$ZBX_INIT_FILE" ];then
	ZBX_PID_FILE="`grep "PIDFILE=" $INIT_PATH/zabbix_agentd_ctl | awk -F"=" '{print $2}'`"
else
	echo "ZABBIX is NOT installed."
	exit $ERR_NOT_INSTALLED
fi
MON_AGTD_PID="`echo $$`"
MON_AGTD_PID_FILE="/tmp/monitor_agentd.pid"

# Monitoring
monitor_stat_check(){
	#ps -ef | grep "/bin/bash .*/`basename $0`" | grep -v "grep" &> /dev/null
	if [ -e "$MON_AGTD_PID_FILE" ];then
		ps -ef | awk -F' ' '{print $2}' | grep `cat $MON_AGTD_PID_FILE`
		if [ "$?" -eq "0" ];then
			echo "This script is already running."
			exit $ERR_ALREADY_RUNNING
		else
			echo $MON_AGTD_PID > $MON_AGTD_PID_FILE
		fi
	else
		echo $MON_AGTD_PID > $MON_AGTD_PID_FILE
	fi
}

start_all(){
	[ ! -e "$ZBX_PID_FILE" ] && stop_agtd && start_agtd
}

stop_agtd(){
        $INIT_PATH/zabbix_agentd_ctl stop &> /dev/null
}

start_agtd(){
        ${INIT_PATH}/zabbix_agentd_ctl start &> /dev/null
}

loop_check(){
	while true
	do
		start_all
		sleep 30
	done
}

monitor_stat_check
loop_check
