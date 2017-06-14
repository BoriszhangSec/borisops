#!/bin/bash

Dirs="/SO-AcLog/All /SO-AcLog/local /SO-AcLog/wan"
Caption="Time,200,500,303,503,404,0,Err"
DayStsDir="/SO-AcLog/DaySts"

mkdir -p $DayStsDir
rm -f $DayStsDir/*

Time=`awk 'BEGIN{ print strftime("%F", systime()-60*60*24)}'`
#Time=`date +%F`

for dir in $Dirs
do
    cd $dir/httpstatus
    FileName=$DayStsDir/$Time"-day."`basename $dir`
    rm -f $FileName
    echo $Caption >>$FileName
    find . -name "*.prd" | xargs -n 1 cat| grep $Time | grep -v "Time"| sort -t, -k 1 >> $FileName
done
