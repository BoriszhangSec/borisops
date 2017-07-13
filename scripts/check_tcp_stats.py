#!/usr/bin/python
import sys

def tcp_conn_stat(port,tcp_stat,direction,ip_type,ipaddr=None):
    TCP_STATUS={'ESTABLISHED' : '01',
                'SYN_SENT' : '02',
                'SYN_RECV' : '03',
                'FIN_WAIT1' : '04',
                'FIN_WAIT2' : '05',
                'TIME_WAIT' : '06',
                'CLOSE' : '07',
                'CLOSE_WAIT' : '08',
                'LAST_ACK' : '09',
                'LISTEN' : '0A',
                'CLOSING': '11'
               }
    tcp_stat=TCP_STATUS[tcp_stat]
    X_port=('%04x' %int(port)).upper()
    #X_port=hex(port).split('x')[1].upper()
    if ip_type == 'ipv4':
        lines=open("/proc/net/tcp").readlines()
    else:
        lines=open("/proc/net/tcp6").readlines()
    tcp_stat_count=0 
    for tcp_line in lines:
        tl=tcp_line.split()
        try: st=tl[1].split(':')[1]
        except IndexError,e:
               continue
        ipadr=''
        if ipaddr is not None:
           for x in ipaddr.split('.'):
             ipa=('%02x' %int(x)).upper()
             ipadr=''.join([ipa,ipadr])
           if ip_type != 'ipv4':
               ipadr='0000000000000000FFFF0000'+ipadr
               print ipadr
           if direction == 'SRC':
               if tl[1].split(':')[1] == X_port and tl[3] == tcp_stat and tl[1].split(':')[0] == ipadr:
                   tcp_stat_count+=1
           else:
               if tl[2].split(':')[1] == X_port and tl[3] == tcp_stat and tl[2].split(':')[0] == ipadr:
                   tcp_stat_count+=1
        else:
            if direction == 'SRC':
                if tl[1].split(':')[1] == X_port and tl[3] == tcp_stat:
                    tcp_stat_count+=1
            else:
                if tl[2].split(':')[1] == X_port and tl[3] == tcp_stat:
                    tcp_stat_count+=1

    print tcp_stat_count        
        
#tcp_conn_stat(10050,'TIME_WAIT','SRC','127.0.0.2')

def main():
    if len(sys.argv) <5:
        sys.exit(1)
    port=sys.argv[1]
    tcp_stat=sys.argv[2]
    direction=sys.argv[3]
    ip_type=sys.argv[4]
    try :ipaddr=sys.argv[5]
    except IndexError,e:
        tcp_conn_stat(port,tcp_stat,direction,ip_type)
    else:
        tcp_conn_stat(port,tcp_stat,direction,ip_type,ipaddr)
if __name__ =='__main__':
    main()





