#!/bin/bash

#Setting
DBName_1=centreon
DBName_2=dcc
DBName_3=redmine
DBName_4=ungeoblog
DBName_5=ungeo
DBUser=root
DBPasswd='aicache'
remote_copy_key='/root/.ssh/mysql_backup'
remote_copy_command="/usr/bin/scp -oConnectTimeout=5 "
BackupPath=/data/backup/mysql
LogFile=${BackupPath}/mysql-bakcup-db.log
Other_DBPath='/data/backup/other'
DatePath=$(date +%Y-%m-%d)
shpath="/usr/local/mysql/bin/"
Backup_IP="113.31.29.242"
#Remote_Backup_Path=/letv/backup
ssh="/usr/bin/ssh -i $remote_copy_key $Backup_IP"
#Master_info=/letv/mysql/master.info
BackupMethod=mysqldump
BackupPara=" --default-character-set=utf8 --opt  --hex-blob --single-transaction "
lockfile=/var/run/mysql-backup.lock
#Setting End

if [ -f $lockfile ] 
    then
          exit 1
    else
          /usr/bin/touch $lockfile
fi


System=`uname`
if [ "$System" = "FreeBSD" ]
     then
          OldFile1="$(date -v -7d +%Y-%m-%d)"
     elif [ "$System" = "Linux" ]
           then
                OldFile1="$(date +%Y-%m-%d --date='7 days ago')"
fi

for DBName in {$DBName_1,$DBName_2,$DBName_3,$DBName_4,$DBName_5}
    do

       if [ ! -d "${BackupPath}${DBName}/${DatePath}" ]
           then 
                mkdir -p ${BackupPath}/${DBName}/${DatePath}
       fi

       NewFile1="$BackupPath"/"$DBName"/"$DatePath"/"$DBName"-$(date +%Y%m%d-%H).tgz
       DumpFile1="$BackupPath"/"$DBName"/"$DatePath"/"$DBName"-$(date +%Y%m%d-%H)


       echo "-------------------------------------------" >> $LogFile

       echo $(date +"%y-%m-%d %H:%M:%S") >> $LogFile
       echo "--------------------------" >> $LogFile


#Delete Old File
#-------------------------------------------------------
       $ssh "ls ${BackupPath}/${DBName}|grep "${OldFile1}"" >/dev/null 2>&1
       if [ $? -eq 0 ]
            then
                 $ssh "rm -rf $BackupPath/${DBName}/${OldFile1}" >> $LogFile 2>&1
                 #echo "$BackupPath/${DBName}/${OldFile1}"
                 echo "[$OldFile1]Delete Old File Success!" >> $LogFile
            else
                 echo "[$OldFile1]No Old Backup File!" >> $LogFile
       fi
#---------------------------------------------------------

#----------------------------------------------------------
       $ssh "ls ${BackupPath}/${DBName}/$DatePath|grep "$DBName"-$(date +%Y%m%d-%H).tgz" >/dev/null 2>&1
       if [ $? -eq 0 ]
          then
               echo "[$NewFile1]The Backup File is exists,Can't Backup!" >> $LogFile
                $remote_copy_command -r -i $remote_copy_key $LogFile  "$Backup_IP:$BackupPath"
       else
               case $BackupMethod in
                    mysqldump)
                              if [ -z $DBPasswd ]
                                  then
                                        "$shpath"mysqldump -u$DBUser  $BackupPara $DBName > $DumpFile1
                                  else
                                         #$shpath/mysql -uroot -p${DBPasswd} -e "stop slave"
                                         #$shpath/mysqladmin -uroot -p${DBPasswd}  flush-tables
                                         #sleep 10
                                         #cp "$Master_info" "${BackupPath}"/"${DBName}"/"${DatePath}"/master.info'-'$(date +%H)
                                         ${shpath}mysqldump -u$DBUser -p$DBPasswd $BackupPara $DBName >$DumpFile1
                              fi
                              tail -n1 $DumpFile1|grep completed >>/tmp/rm.log 2>&1
                                 if [ $? -eq 0 ]
                                      then
                                           #$shpath/mysql -uroot -p${DBPasswd} -e "start slave" 
                                           tar czvf $NewFile1 $DumpFile1 >> $LogFile 2>&1
                                           echo "[$NewFile1]Backup Success!" >> $LogFile
                                           rm -rf $DumpFile1
                                           #echo "Dump File is $DumpFile1"
                                           $remote_copy_command -r -i $remote_copy_key $BackupPath/*  $Backup_IP:$BackupPath/ >>/tmp/rm.log 2>&1
                                              if [ $? -eq 0 ]
                                                     then 
                                                          rm -rf "$BackupPath/$DBName"
                                                     else
                                                          mv $NewFile1 $Other_DBPath/
                                                          echo "The backup server $Backup_IP lost connection,Data stored in $Other_DBPath temporary directory"|/data/scripts/notify.py -s "mysql backup server error" -t 'ye.tao@ungeo.net'
                                              fi
                                           #echo "BACKUPDB file  $BackupPath/$DBName/*"
                                           # /bin/rm -f $lockfile
                                      else
                                           echo "the $DumpFile1 is fail,export unfinished"|/data/scripts/notify.py -s "mysql backup export error" -t 'ye.tao@ungeo.net'
                              fi 
                                           
                         ;;
                   mysqlhotcopy)
                               rm -rf $DumpFile1
                               mkdir $DumpFile1
                               if [ -z $DBPasswd ]
                                    then
                                          "$shpath"mysqlhotcopy -u $DBUser $DBName $DumpFile1 >> $LogFile 2>&1
                                    else
                                           "$shpath"mysqlhotcopy -u $DBUser -p $DBPasswd $DBName $DumpFile1 >>$LogFile 2>&1
                               fi
                               tar czvf $NewFile1 $DumpFile1 >> $LogFile 2>&1
                               echo "[$NewFile1]Backup Success!" >> $LogFile
                               rm -rf $DumpFile1
                               rm -f $lockfile
                          ;;
                          *)
                                echo "Please check Backup method!" >> $LogFile
                          ;;
                   esac
        fi
#----------------------------------------------------------

#----------------------------------------------------------
echo "-------------------------------------------" >> $LogFile
echo $(date +"%y-%m-%d %H:%M:%S") >> $LogFile
echo "-------------------------------------------" >> $LogFile
    done
/bin/rm -f $lockfile

