#!/bin/bash

guidfile=$1
guids=(`cat $guidfile | grep -v "#"`)
guidnum=${#guids[@]}

for ((i=0;i<$guidnum;i++))
do
	guid=${guids[i]}
	echo $guid >> $1.result
	`/usr/bin/python /opt/ccg_cns_db_editor.py get $guid | grep -v $guid >> $1.result`
done
