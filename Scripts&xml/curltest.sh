#!/bin/bash

logdir="/opt/fanyj/"
GUIDS=(`cat $1`)
GUIDNUM=${#GUIDS[@]}
#echo $GUIDNUM

if [ -e ${logdir}err.log ]; then
	rm -f ${logdir}err.log
fi

echo `date` > ${logdir}err.log
for ((i=0;i<$GUIDNUM;i++))
do
        result=`curl -Is "http://127.0.0.1/${GUIDS[i]}" | grep "HTTP"|awk '{print $2}'`
#        echo ${GUIDS[i]}
#        echo $result
        if [ $result -ne 200 ];then
                echo ${GUIDS[i]} >> ${logdir}err.log
        fi
done
