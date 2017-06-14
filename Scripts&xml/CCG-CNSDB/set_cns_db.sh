#!/bin/bash

guidfile=$1
guids=(`cat $guidfile | grep -v "#"`)
guidnum=${#guids[@]}

for ((i=0;i<$guidnum;i++))
do
	guid=${guids[i]}
#	echo $guid >> $1.result
	`/usr/bin/python /opt/ccg_cns_db_editor.py set $guid 163DAA4409E14AB69BF1E3F50F771DF7 >/dev/null`
done
