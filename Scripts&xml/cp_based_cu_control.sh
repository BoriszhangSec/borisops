#!/bin/bash - 
set +x
#===============================================================================
#
#          FILE:  cp_based_cu_control.sh
# 
#         USAGE:  ./cp_based_cu_control.sh 
# 
#   DESCRIPTION:  For CPID based CCU control
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Wenbo Wang (), wangwenbo@streamocean.com
#       COMPANY: StreamOcean, Inc.
#       CREATED: 10/30/2013 12:18:12 PM CST
#      REVISION: 0.1: initial version
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

MYSQL_LOGIN="mysql -uroot -pdb"
DB_CU="so_svr_st"
TBL_CU="cu_permission"
CPID=$3
MAX_CU=$4

HELP(){
	echo "Options:"
	echo "list  : List all policies."
	echo "add   : Add a new policy."
	echo "update: Update an existed policy."
	echo "delete: Delete an existed policy."
	echo "flush : Flush all policies."
	echo "cu    : CU control entry."
	echo "Example:"
	echo " - List all policies: `basename $0` list cu"
	echo " - Add max CU \"500\" for CP \"test\": `basename $0` add cu test 500"
	echo " - Delete policy of CP \"test\": `basename $0` delete cu test"
	echo " - Clear policy DB: `basename $0` flush cu"
}

if [ "$1" != "help" -a "$#" -lt "2" -o "$#" -gt "4" ];then
	HELP
fi

POLICY_CU_LIST(){
	$MYSQL_LOGIN $DB_CU -e "select * from $TBL_CU"
}

POLICY_CU_ADD(){
	$MYSQL_LOGIN $DB_CU -e "insert into $TBL_CU(cpid,max_cu) values('$CPID','$MAX_CU')"
}

POLICY_CU_UPDATE(){
	$MYSQL_LOGIN $DB_CU -e "update $TBL_CU set max_cu='$MAX_CU' where cpid='$CPID'"
}

POLICY_CU_DELETE(){
	$MYSQL_LOGIN $DB_CU -e "delete from $TBL_CU where cpid='$CPID'"
}

POLICY_CU_FLUSH(){
	$MYSQL_LOGIN $DB_CU -e "truncate table $TBL_CU"
}

case $1 in
	list	)	POLICY_CU_LIST;;
	add	)	POLICY_CU_ADD;;
	update	)	POLICY_CU_UPDATE;;
	delete	)	POLICY_CU_DELETE;;
	flush	)	POLICY_CU_FLUSH;;
	help	)	HELP;;
esac
