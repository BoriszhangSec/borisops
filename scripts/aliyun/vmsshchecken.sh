#!/bin/bash
############################################
# ssh远程检查脚本         
#
#2014-03-26 by 金象
#version:1.0
#使用方法：
#例：./vmsshcheck.sh
#
#脚本检查机制：
#1、检测重要文件权限
#2、检测ssh端口及root权限
#3、检测网卡IP地址
#4、检查开机磁盘自检
#5、检查NetworkManager服务状态
############################################
#华丽的分隔线
split_line="--------------------------------------------------"

#重要文件权限检查
check_permi()
{
 #文件权限检查列表
 file_ssh_rsa=/etc/ssh/ssh_host_rsa_key
 file_ssh_dsa=/etc/ssh/ssh_host_dsa_key
 doc_ssh_empty=/var/empty/sshd/
 file_passwd=/etc/passwd
 file_shadow=/etc/shadow
	
 echo ${split_line}
 echo "check file permission:"

 for file_current in ${file_ssh_rsa} ${file_ssh_dsa} ${doc_ssh_empty} ${file_passwd} ${file_shadow}
 do
  file_permi=$(ls -ld ${file_current}|awk '{print $1}')
  case ${file_current} in
  ${file_ssh_rsa}|${file_ssh_dsa})
   if [ "${file_permi}" != "-rw-------" ];then
    echo -e "\033[31mDanger!\033[0m"
    ls -ld ${file_current}
    chmod 600 ${file_current} && echo "has been fixed"
   else
    echo -e "${file_current}\t\033[32mpass\033[0m"
   fi
  ;;
  ${doc_ssh_empty})
   if [ "${file_permi}" != "drwx--x--x." ];then
    echo -e "\033[31mDanger!\033[0m"
    ls -ld ${file_current}
    chmod 711 ${file_current} && chown root.root ${file_current} && echo "has been fixed"
   else
    echo -e "${file_current}\t\t\033[32mpass\033[0m"
   fi
  ;;
  ${file_passwd})
   if [ "${file_permi}" != "-rw-r--r--" ];then
    echo -e "\033[31mDanger!\033[0m"
    ls -ld ${file_current}
    chmod 644 ${file_current} && echo "has been fixed"
   else
    echo -e "${file_current}\t\t\t\033[32mpass\033[0m"
   fi
  ;;
  ${file_shadow})
   if [ "${file_permi}" != "----------" ];then
    echo -e "\033[31mDanger!\033[0m"
    ls -ld ${file_current}
    chmod 000 ${file_current} && echo "has been fixed"
   else
    echo -e "${file_current}\t\t\t\033[32mpass\033[0m"
   fi
  esac
 done
 /etc/init.d/sshd restart
}

#NetworkManager服务检查
check_NM()
{
 echo ${split_line}
 echo "check NetworkManager:"
 networkmanager_status=$(chkconfig --list|grep NetworkManager|grep on)
 if [ -n "${networkmanager_status}" ];then
  echo "NetworkManager is started ,repairing"
  /etc/init.d/NetworkManager stop
  chkconfig NetworkManager off
  /etc/init.d/network restart
 else
  echo -e "\033[32mpass\033[0m"
 fi
}

#ssh端口检查
check_sshd()
{
 echo ${split_line}
 echo "check ssh port:"
	
 sshd_port_tmp=$(grep -i ^port /etc/ssh/sshd_config|awk '{print $2}')
 sshd_port=${sshd_port_tmp:-22}
 sshd_root_state_tmp=$(grep ^PermitRootLogin /etc/ssh/sshd_config|tail -1|awk '{print $2}'|tr [A-Z] [a-z])
 sshd_root_state=${sshd_root_state_tmp:-yes}
 sshd_passwd_state_tmp=$(grep ^PasswordAuthentication /etc/ssh/sshd_config|tail -1|awk '{print $2}'|tr [A-Z] [a-z])
 sshd_passwd_state=${sshd_passwd_state_tmp:-yes}
 echo -e "ssh port:\t\t\t\t"${sshd_port}
 echo -e "ssh permit root:\t\t\t${sshd_root_state}"
 echo -e "ssh permit password authentication:\t${sshd_passwd_state}"
}

#网卡IP检查
check_ip()
{
 echo ${split_line}
 echo "check IP:"
	
 internal_ip=$(ifconfig |grep -A 1 eth0|grep inet|awk -F: '{print $2}'|awk '{print $1}')
 internat_ip=$(ifconfig |grep -A 1 eth1|grep inet|awk -F: '{print $2}'|awk '{print $1}')
 if [ -n "${internal_ip}" ];then
  echo -e "Private IP:\t"${internal_ip}
 else
  echo -e "Private IP:\tnone"
 fi
 if [ -n "${internat_ip}" ];then
                echo -e "Public IP:\t"${internat_ip}
        else
                echo -e "Public IP\t:none"
        fi
 is_icmp=$(cat /proc/sys/net/ipv4/icmp_echo_ignore_all)
 if [ "${is_icmp}x" == "1"x ];then
 echo -e "icmp:\tdisable"
 fi
}

#磁盘开机挂载检查
check_fstab()
{
 echo ${split_line}
 echo "check mount file:"
 disk_dev=$(cat /etc/fstab |awk '{print $1}'|grep -E "^/dev|^UUID|^uuid"|sort|uniq -c|awk '{if ($1>1) print $2}')
 if [ -n "${disk_dev}" ];then
  echo "mount error，please check file /etc/fstab："
  for err_dev in ${disk_dev[*]}
  do
   grep ${err_dev} /etc/fstab
  done
 else
  echo -e "\033[32mpass\033[0m"
 fi
}

#执行脚本
check_sshd

check_ip

check_permi

check_NM

check_fstab


