#!/bin/bash
if [ "$LOGNAME" != 'root' ];then
   echo "please use non-root user execute"
   exit 1
fi
touch sysre.log
logs="tee -a sysre.log"

a1()
{
if [ ! -s /etc/motd ]
then    echo " Authorized users only. All activity may be monitored and reported " >>/etc/motd
        echo "###Message has been added, 4 fixes"|$logs
fi
}
a2()
{
days=`cat /etc/login.defs|grep -v "^#"|grep PASS_MAX_DAYS|awk '{print $2}'`
        cp -p /etc/login.defs /etc/login.defs_bak
        sed -ri 's/(PASS_MAX_DAYS).*/\1 90/g' /etc/login.defs
        sed -ri 's/(PASS_MIN_LEN).*/\1 8/g' /etc/login.defs
        sed -ri 's/(UMASK).*/\1 027/g' /etc/login.defs
        #cat /etc/login.defs |sed '/^#/d'|sed '/^$/d'|$logs
        #read -n 1
        echo "###Message has been added, 5 fixes"|$logs
}
a3()
{
if [ ! -e /etc/sshbanner ];then
		touch /etc/sshbanner
		chown bin:bin /etc/sshbanner
		chmod 644 /etc/sshbanner
		echo " Authorized users only. All activity may be monitored and reported "   >/etc/sshbanner
		cp /etc/ssh/sshd_config /etc/ssh/sshd_configbak
		echo "Banner /etc/sshbanner">>/etc/ssh/sshd_config
		/etc/init.d/sshd reload
		if [ $? -eq 0 ];then
			echo "sshd reload ok"
		else
			echo "sshd fail"
		fi
		echo "###Message has been added, 7 fixes"|$logs
fi
}
a4()
{
grep "minlen=8" /etc/pam.d/system-auth
if [ $? -ne 0 ];then
	cp /etc/pam.d/system-auth /etc/pam.d/system-authbak
	sed -i '/pam_cracklib.so/d' /etc/pam.d/system-auth
	sed -ri '/^password.*pam_unix.so/i password    requisite     pam_cracklib.so dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 minclass=2 minlen=8' /etc/pam.d/system-auth
	echo "###Message has been added, 9 fixes"|$logs
fi
}
a5()
{
#	¼ìÖ»ú¿Øƣ¨IPÏÖ£©
#allowno=`egrep -i "sshd|telnet|all" /etc/hosts.allow |sed '/^#/d'|sed '/^$/d'|wc -l`
#if [ "$allowno" -eq "0" ];then
#	echo "all:10.1.5.235:allow">>/etc/hosts.allow
#	echo "sshd:10.1.5.252:allow">>/etc/hosts.allow
#	echo "sshd:all:DENY">>/etc/hosts.allow
#	echo "###Message has been added, 10 fixes"|$logs
#fi
: 	
}

#delete user
a6()
{
 mfile="/etc/passwd"
 searchkey="tomcat|root|yz|loguser|ftpuser|mongod|www"
 grep bash $mfile|grep -vE $searchkey|awk -F: '{print $1}'|xargs -i sh -c 'for ua in "{}"; do  passwd -l $ua; done'
 sed -ri 's#^(www.*:)/bin/bash#\1/sbin/nologin#g' $mfile
 sed -ri 's#^(ftpuser.*:)/bin/bash#\1/sbin/nologin#g' $mfile
 
}
a7()
{
cat /etc/profile |sed '/^#/d'|sed '/^$/d'|grep -i TMOUT
if [ $? -ne 0 ];then
	cp -p /etc/profile /etc/profile_bak
	cp -p /etc/csh.cshrc /etc/csh.cshrc_bak
	echo "TMOUT=600" >>/etc/profile
	echo "export TMOUT" >>/etc/profile
	#echo "set autologout=30" >>/etc/csh.cshrc
	echo "###Message has been added, 12 fixes"|$logs
fi
}

a10()
{

result=`chkconfig --list|egrep "amanda|chargen|chargen-udp|cups|cups-lpd|daytime|daytime-udp|echo|echo-udp|eklogin|ekrb5-telnet|finger|gssftp|imap|imaps|ipop2|ipop3|klogin|krb5-telnet|kshell|ktalk|ntalk|rexec|rlogin|rsh|rsync|talk|tcpmux-server|telnet|tftp|time-dgram|time-stream uucp"|grep -w "on"|wc -l`
if [ $result -ne 0 ];then
	for servers in `chkconfig --list|egrep "amanda|chargen|chargen-udp|cups|cups-lpd|daytime|daytime-udp|echo|echo-udp|eklogin|ekrb5-telnet|finger|gssftp|imap|imaps|ipop2|ipop3|klogin|krb5-telnet|kshell|ktalk|ntalk|rexec|rlogin|rsh|rsync|talk|tcpmux-server|telnet|tftp|time-dgram|time-stream uucp"|grep -w "on"|awk '{ print $1 }'`
	do
		chkconfig $servers off
		echo "$servers off"|$logs
		echo "###Message has been added, 17 fixes"|$logs
	done
fi
}

a11()
{

grep "PermitRootLogin no" /etc/ssh/sshd_config |grep -v "#"
if [ $? -ne 0 ];then
		cp -p /etc/securetty /etc/securetty_16bak
		cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config_16bak
		grep "pts" /etc/securetty |grep -v "^#"
		sed -i s/pts/#pts/gi /etc/securetty
		grep "PermitRootLogin yes" /etc/ssh/sshd_config |grep -v "#"
		if [ $? -ne 0 ];then
			echo "PermitRootLogin no">>/etc/ssh/sshd_config
		else
			sed -i /PermitRootLogin\ yes/d /etc/ssh/sshd_config
			echo "PermitRootLogin no">>/etc/ssh/sshd_config
		fi	
		grep "PermitRootLogin no" /etc/ssh/sshd_config |$logs
		echo "###Message has been added, 16 fixes"|$logs
		#sed -i /^PasswordAuthentication\ yes/s/yes/no/i /etc/ssh/sshd_config
		#echo /etc/ssh/sshd_config==== `egrep "^PasswordAuthentication no" /etc/ssh/sshd_config`|$logs
		/etc/init.d/sshd reload		
fi
}


a8()
{
 mfile='/etc/pam.d/su'
 i1="auth   required   pam_wheel.so group=wheel"
 i2="auth   sufficient pam_rootok.so"
 searchkey="^auth.*pam_rootok.so"
 if ! `grep -E "group=wheel" $mfile>/dev/null 2>&1`;then 
    if `grep -E "$searchkey" $mfile >/dev/null 2>&1`;then
        sed -ri "/$searchkey/ a $i1 " $mfile
    else
        sed -i -e "1 a $i2" -e "1 a $i1" $mfile
    fi
 fi
 usermod -G wheel yz
 usermod -G wheel tomcat

}

a9()
{
 mfile='/etc/sudoers'
 sed -ri '/^Defaults.*requiretty/ s/(Defaults.*requiretty)/#\1/' $mfile
 if ! `grep yz $mfile >/dev/null 2>&1`;then
    sed -i '96 a yz  ALL=(ALL) NOPASSWD: ALL' $mfile
 fi
 find / -name ".rhosts" -o -name ".netrc" -o -name "hosts.equiv"|xargs -i rm -f {}

}



for function in `seq 1 11`
do
	a$function
done
exit

