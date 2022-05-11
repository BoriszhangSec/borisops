#!/usr/bin/python
import json
import os
import re
import sys
import urllib

nflag_list = ['SRC', 'DST']
pflag_list = ['IPV4', 'IPV6']
# port_conf='/data0/scripts/discovery/port.conf'
SNFile_PATH = '/'


def get_snfile(SNFile_PATH):
    try:
        sndir = os.listdir(SNFile_PATH)
    except OSError, e:
        return None
    else:
        for snfile in os.listdir(SNFile_PATH):
            sname = re.match(r'SN\d{10}', snfile)
            if sname is not None:
                return os.path.join(SNFile_PATH, sname.group())


def discovery_port(nflag, monitor_conf, pflag=None):
    plist = []
    pdata = {}
    monitor_flag = 0
    try:
        lconf = open(monitor_conf)
    except  IOError, e:
        print
        monitor_conf, e
        sys.exit(1)
    else:
        for conf_line in lconf:
            conf_line = conf_line.strip()
            if conf_line == "[Monitor]":
                monitor_flag = 1
                continue
            if len(conf_line) == 0 or conf_line[0] == '#' or monitor_flag == 0:
                continue
            if conf_line[0] == '[' and monitor_flag == 1:
                break
            if monitor_flag == 1:
                pdata['{#PORT}'] = conf_line.split()[0]
                pdata['{#SERVICE}'] = conf_line.split()[1]
                pdata['{#NFLAG}'] = conf_line.split()[2]
                pdata['{#PROTOCOL}'] = conf_line.split()[3]
                pdata['{#HEALTH_URL}'] = conf_line.split()[4]
                if pdata['{#NFLAG}'] == nflag and pflag == None:
                    plist.append(pdata)
                elif pdata['{#PROTOCOL}'] == pflag and pdata['{#NFLAG}'] == nflag:
                    plist.append(pdata)
                pdata = {}
            all = {'data': list(plist)}
    lconf.close()
    print
    json.dumps(all)
    # return plist


def check_url(url):
    try:
        httpcode = urllib.urlopen(url).getcode()
    except IOError, e:
        print
        0
    else:
        print
        httpcode


def main():
    if len(sys.argv) < 2:
        sys.exit(1)
    nflag = sys.argv[1]
    port_conf = get_snfile(SNFile_PATH)
    try:
        pflag = sys.argv[2]
    except IndexError, e:
        if nflag in nflag_list:
            discovery_port(nflag, port_conf)
    else:
        if nflag == 'check_url':
            check_url(pflag)
        elif pflag in pflag_list:
            discovery_port(nflag, port_conf, pflag)


if __name__ == '__main__':
    main()
