#!/usr/bin/env python

import time
import datetime
import sys

channel = sys.argv[1]
addr = sys.argv[2]

infile = open('%s.time'%channel,'r+')
outfile = open('calc_%s_%s.sh'%(channel,addr),'w+')
outfile.write('#!/bin/sh \n\n')
outfile.write('echo >cu_%s_%s.txt\n'%(channel,addr))
for strftime in infile: 
    endtime = strftime.strip()
    #endtime = '2013-12-16 7:00:00'
    endptime = time.strptime(endtime,"%Y-%m-%d %H:%M:%S") 
    startdatetime = datetime.datetime(*endptime[:6]) - datetime.timedelta(seconds=60)
    starttime = startdatetime.strftime("%Y-%m-%d %H:%M:%S") 
    line = '''mysql -uroot -pdb so_svr_st -e "select content.guid,status.utime,status.cu from status,content where content.pressid=status.pressid and content.guid='%s' and status.utime between '%s' and '%s' order by cu limit 1" >>cu_%s_%s.txt\n''' %(channel,starttime,endtime,channel,addr)
    outfile.write(line)

infile.close()
outfile.close()
