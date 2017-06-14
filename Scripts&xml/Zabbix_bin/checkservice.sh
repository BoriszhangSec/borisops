#!/bin/bash
# MANAGED BY PUPPET

sudo service streamocean status >& /dev/null

if [ "$?" -eq "0" ];then
        echo "1"
else
        echo "0"
fi
