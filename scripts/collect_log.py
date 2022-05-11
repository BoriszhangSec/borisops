#!/usr/local/bin/python
import ftplib
import getopt
import os
import re
import shutil
import sys
import tarfile
from cStringIO import StringIO
from cc_func import smail
from datetime import date, timedelta

ISOTIMEFORMAT = '%Y-%m-%d'
LOG_DATE = (date.today() - timedelta(days=1)).strftime(ISOTIMEFORMAT)
TODAY = date.today().strftime(ISOTIMEFORMAT)
SPEC_LOG = 'catalina.out'
SPEC_LOG_F = SPEC_LOG + '.' + LOG_DATE
# IP='10.1.5.31'
UP_TEMP = '/data0/logs/uploads'
SNFile_PATH = '/'
MailOwn = 'huxs@umessage.com.cn,taoye@umessage.com.cn'
s = re.compile(r"([^,]+)")
toaddrs = s.findall(MailOwn)
print
MailOwn
print
toaddrs


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


def get_ip(SN_file):
    local_ip = None
    sn_file = open(SN_file)
    for sn_line in sn_file:
        ip_ob = re.match(r'LocalIP=(.*)', sn_line)
        if ip_ob is not None:
            local_ip = ip_ob.group(1)
            break
    return local_ip


def readconf(log_conf):
    log_list = []
    para_list = {}
    log_flag = 0
    try:
        lconf = open(log_conf)
    except  IOError, e:
        print
        log_conf, e
        sys.exit(1)
    else:
        for log_conf_line in lconf:
            log_conf_line = log_conf_line.strip()
            # value=re.split('\s+',log_conf_line)
            if len(log_conf_line) > 0 and log_conf_line == "[Log]":
                log_flag = 1
                continue
            if len(log_conf_line) == 0 or log_conf_line[0] == '#' or log_flag == 0:
                continue
            if log_conf_line[0] == '[':
                break
            if log_flag == 1:
                log_list.append(log_conf_line)

        lconf.close()
        return (log_list)


# print readconf('/data0/scripts/SN1001010020')

def tar_log(logname, stpath):
    fname = os.path.join(stpath, '%s.tgz' % logname)
    with tarfile.open(fname, 'w:gz') as tarf:
        tarf.add(logname)
    return fname


def ftp_client(fpath, fname, lip):
    # fpath='hotel/10.1.5.31/2012/05'
    succ_flag = 'successfully transferred'
    upath = fpath.split('/')
    ftpserver = '10.1.5.252'
    ftp = None
    ftp_stat = 'fail'
    try:
        ftp = ftplib.FTP(ftpserver)
        ftp.login('loguser', 'ZWSZFxdKAs')
    except ftplib.all_errors, e:
        print
        e.message
        print
        'Plese check FTP Server configuration info'
        smail(toaddrs, 'Plese check FTP Server configuration info', '%s Log Upload Error Notify' % lip)
        sys.exit(1)
    else:
        fdir = "/"
        file_handler = open(fname, 'rb')
        fcmd = 'STOR ' + fname.split('/')[-1]
        for rdir in upath:
            fdir = fdir + rdir + "/"
            # print fdir
            try:
                ftp.cwd(fdir)
            except ftplib.error_perm, e:
                if e.message.split(" ")[0] == "550":
                    ftp.mkd(rdir)
                    ftp.cwd(rdir)
                else:
                    print
                    e.message
                    sys.exit(1)
        old_stdout = sys.stdout
        sys.stdout = stdout = StringIO()
        print
        ftp.storbinary(fcmd, file_handler, 1024)
        sys.stdout = old_stdout
        fmsg = stdout.getvalue()
        if fmsg.rfind(succ_flag) == -1:
            # print 'upload %s fail' %fname
            ftp_stat = 'fail'
        else:
            ftp_stat = 'ok'
        file_handler.close()
    finally:
        if ftp is not None:
            ftp.quit()
        return ftp_stat


def create_log(srcfile, dstfile):
    shutil.copyfile(srcfile, dstfile)
    sfd = open(srcfile, 'w')
    sfd.close()


def usage(args):
    print
    '''%s -m (normal|norotate|onlyupload) -f SN_file
       -m Processing log model  
       -f sn_file Specify a SN_file configuration file,Don't use default 
       -h  get help info''' % (args)
    sys.exit(1)


def upload(logfile, appname, ip, up_file, fdate):
    ptime = fdate.split('-')
    ftp_dir = os.path.join(appname, ip, ptime[0], ptime[1])
    print
    ftp_dir, up_file
    if os.path.isfile(up_file):
        succ_flag = ftp_client(ftp_dir, up_file, ip)
        if succ_flag == 'ok':
            os.remove(up_file)
            if os.path.isfile(logfile):
                os.remove(logfile)
    else:
        print
        'fail'


def upload_log(log_dir, log_exp, today, up_temp, app_name, ip, only_upload):
    for logfile in os.listdir(log_dir):
        logf = re.search(log_exp, logfile)
        if logf is not None:
            fdate = logf.group(2)
            if fdate == today:
                continue
            app_dir = os.path.join(up_temp, app_name)
            if not os.path.exists(app_dir):
                os.mkdir(app_dir)
            if only_upload == 1:
                up_file = tar_log(logfile, app_dir)
            else:
                up_file = logfile
            # print logfile,app_name,ip,up_file,fdate
            upload(logfile, app_name, ip, up_file, fdate)


def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hm:f:", ['help'])
    except getopt.GetoptError, err:
        print
        str(err)
        sys.exit(2)
    def_flag = 0
    Create_Lock = 0
    only_up = 1
    if len(sys.argv) == 1:
        usage(sys.argv[0])
    for o, a in opts:
        if o in ("-h", "--help"):
            usage(sys.argv[0])
        elif o == "-m":
            # Create_Lock=1
            coll_mod = a
            coll_mods = ('normal', 'norotate', 'onlyupload')
            if coll_mod not in coll_mods:
                usage(sys.argv[0])
        elif o == "-f":
            sn_file = a
            def_flag = 1
        else:
            usage(sys.argv[0])
    if def_flag != 1:
        sn_file = get_snfile(SNFile_PATH)
    if sn_file is not None:
        log_conf = readconf(sn_file)
    else:
        print
        'SNfile is not found'
        sys.exit(1)
    IP = get_ip(sn_file)
    if not os.path.exists(UP_TEMP):
        os.makedirs(UP_TEMP)
    for loginfo in log_conf:
        log_dir = re.split('\s+', loginfo, 3)[0]
        log_exf = re.split('\s+', loginfo, 3)[1]
        app_name = re.split('\s+', loginfo, 3)[2]
        if os.path.isdir(log_dir):
            log_list = os.listdir(log_dir)
        else:
            smail(toaddrs, 'log dir %s is not exist,check SN_file configuration' % log_dir,
                  '%s Log Upload Error Notify' % IP)
            continue
        if coll_mod in ('normal', 'norotate'):
            if log_exf.find(SPEC_LOG) == 1 and coll_mod == 'normal':
                if not os.path.isfile(os.path.join(log_dir, SPEC_LOG_F)):
                    # print os.path.join(log_dir,SPEC_LOG_F)
                    if os.path.isfile(os.path.join(log_dir, SPEC_LOG)):
                        create_log(os.path.join(log_dir, SPEC_LOG), os.path.join(log_dir, SPEC_LOG_F))
                    else:
                        smail(toaddrs, '%s not found,check SN_file configuration' \
                              % (os.path.join(log_dir, SPEC_LOG)), '%s Log Upload Error Notify' % IP)

            os.chdir(log_dir)
            # print log_dir, log_exf, app_name, IP, UP_TEMP,TODAY
            upload_log(log_dir, log_exf, TODAY, UP_TEMP, app_name, IP, only_up)
        elif coll_mod == 'onlyupload':
            only_up = 0
            log_dir = os.path.join(UP_TEMP, app_name)
            os.chdir(log_dir)
            upload_log(log_dir, log_exf, TODAY, UP_TEMP, app_name, IP, only_up)


if __name__ == '__main__':
    main()
    # print get_ip('/data0/scripts/SN1001010020')
