# -*- coding: utf-8 -*-
# author: orangleliu date: 2014-11-12
# python2.7.x ip_scaner.py

''''' 
不同平台，实现对所在内网端的ip扫描 
  
有时候需要知道所在局域网的有效ip，但是又不想找特定的工具来扫描。 
使用方法 python ip_scaner.py 192.168.1.1 
(会扫描192.168.1.1-255的ip) 
'''

import os
import platform
import sys
import thread
import time


def get_os():
    '''''
    get os 类型
    '''
    os = platform.system()
    if os == "Windows":
        return "n"
    else:
        return "c"


def ping_ip(ip_str):
    cmd = ["ping", "-{op}".format(op=get_os()),
           "1", ip_str]
    output = os.popen(" ".join(cmd)).readlines()

    flag = False
    for line in list(output):
        if not line:
            continue
        if str(line).upper().find("TTL") >= 0:
            flag = True
            break
    if flag:
        print
        "%s" % ip_str


def find_ip(ip_prefix):
    '''''
    给出当前的127.0.0 ，然后扫描整个段所有地址
    '''
    for i in range(1, 256):
        ip = '%s.%s' % (ip_prefix, i)
        thread.start_new_thread(ping_ip, (ip,))
        time.sleep(0.3)


if __name__ == "__main__":
    #  print "start time %s"%time.ctime()
    commandargs = sys.argv[1:]
    args = "".join(commandargs)

    ip_prefix = '.'.join(args.split('.')[:-1])
    find_ip(ip_prefix)
#  print "end time %s"%time.ctime()
