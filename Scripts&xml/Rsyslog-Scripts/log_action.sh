#!/bin/bash

#date +%Y%m%d%H%M%S
YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`
HOUR=`date +%H`
MINUTE=`date +%M`
SECOND=`date +%S`

#The Dir-path will be /SO-AcLog/Year/Month/Day
LOGDIR=/SO-AcLog/$YEAR/$MONTH/$DAY/

#The log file name
LOGFILE=$LOGDIR/$YEAR"-"$MONTH"-"$DAY"-"$HOUR$MINUTE$SECOND

#Create the dir
mkdir -p $LOGDIR

#Move the log file to new position, and change the name
mv -f /SO-AcLog/actmp.log $LOGFILE
