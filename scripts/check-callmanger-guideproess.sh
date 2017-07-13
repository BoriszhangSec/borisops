#!/bin/bash
source /app/yunwei/config.ini
callmanagerpath=${callmanagerpath:-/app/callmanager}
ipaddr=${ipaddr:-$HOSTNAME}
for i in `ls "$callmanagerpath"`;
   do
    for callmangerSN in `echo "$i"| sed 's/.*_//g'`;do
        if [ `cat $callmanagerpath/"$i"/bin/IVRserver_"$callmangerSN"check.sh| grep ipaddr| grep -v grep| wc -l` = "0" ];then
                sed -i 's/echo \"Restarting ivrappD.exe/logger -p daemon.error "serverip:"$ipaddr" `date "+%Y-%m-%d %H:%M:%S"` $i daemontag  Restarting CM"$callmangerSN"/g' $callmanagerpath/"$i"/bin/IVRserver_"$callmangerSN"check.sh;
                sed -i '2a 'ipaddr="$ipaddr"'' $callmanagerpath/"$i"/bin/IVRserver_"$callmangerSN"check.sh;
                sed -i '3a 'callmangerSN="$callmangerSN"'' $callmanagerpath/"$i"/bin/IVRserver_"$callmangerSN"check.sh;
        fi
             ps -ef | grep IVRserver_"$callmangerSN"check.sh| grep -v grep >/dev/null;
            if [ $? == "1" ];then
            cd $callmanagerpath/"$i"/bin/
            sh IVRserver_"$callmangerSN"check.sh &
            echo "IVRserver_"$callmangerSN"check.sh"
           else
            echo "OK !!!!!!!!!!!!!!"
            fi
   done
done
