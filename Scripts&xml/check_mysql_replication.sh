#!/bin/bash
    
errornum=(1158 1159 1008 1007 1062)
mysql_cmd="mysql -uroot -p"

#while true
#do
    array=($($mysql_cmd -e "show slave status\G" | egrep "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master" | awk '{print $2}'))
    flag=0
    for status in ${array[@]}
    do
        if [ "$status" != "Yes" -a "$status" != "0" ]
        then
             lastnum=($($mysql_cmd -e "show slave status\G" | egrep "Last_Errno" | awk '{print $2}'))
             for ((i=0; i<${#errornum[@]}; i++))
             do
                [ $lastnum -eq ${errornum[i]} ] && {
                let flag=flag+1
                continue 2 
                }
            done
            #char="Mysql slave is not ok."
            #return or mail
            echo 0
            break
        else
            let flag=flag+1
        fi
    done

[ $flag -eq 3 ] && {
    #echo "Mysql slave is ok." | mail -s "mysql_slave_ok" qinlu2222@126.com
    #return or mail
    echo 1
    flag=0
}

#sleep 10
#done