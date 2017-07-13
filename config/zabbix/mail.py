#!/usr/bin/python
# -*- coding: utf-8 -*-
import getopt
import sys
import smtplib
import re

def smail(toaddrs,mail_body,subject):
    server = smtplib.SMTP('mail.umessage.com.cn')
    server.login('cc_monitor','DRj%@U4O^0!&kV')
    fromaddr = 'cc_monitor@umessage.com.cn'
    mail_body = "From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s\n" % (fromaddr,", ".join(toaddrs),subject,mail_body)
    try:
        #server.set_debuglevel(1)
        server.sendmail(fromaddr, toaddrs, mail_body)
    except:
        return 1
    server.quit()
    return 0



if __name__ == "__main__":
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hs:t:")
    except getopt.GetoptError, err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        sys.exit(2)
    output = None
    subject = ""
    toaddrs = ""
    mail_body = ""
    for o, a in opts:
        if o == "-s":
            subject = a
        elif o in ("-h"):
            print "echo message|%s -s subject -t mailaddr" %(sys.argv[0])
            sys.exit()
        elif o in ("-t"):
            s = re.compile(r"([^,]+)")
            toaddrs = s.findall(a)
    while(1):
        try:
            tmp=raw_input()
        except EOFError:
            break
        mail_body = '%s\n%s' % (mail_body,tmp)

    smail(toaddrs, mail_body,subject)
