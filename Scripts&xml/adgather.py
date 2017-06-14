#!/usr/bin/python26

#####################################
# SO advertisement information gathering and reporting to payer
#
#####################################
import sys
import os

ROOT=os.environ.get("CALIDUS_ROOT_DIR", "/SO")
LIBS=os.path.join(ROOT, "lib/pylibs")
sys.path.insert(0, LIBS)
files = os.listdir(LIBS)
for name in files:
    if name.endswith("zip"):
        file_path = os.path.join(LIBS, name)
        sys.path.insert(0, file_path)

import getopt
import logging
import zmq
import struct
import zlib
import cPickle as pickle
import hashlib
import httplib
import time
from logging.handlers import RotatingFileHandler
from logging.handlers import SysLogHandler
import event_pack
import dbhelper        
import xmlhelper
import urllib
import urllib2
import urlparse
import socket
import json
from threading import Thread
from Queue import Queue
#typedef struct ses_vc_swch_info_ {
#    uint64_t            sid;
#    int32_t             sock_fd;
#    int32_t             ip;
#    int32_t             port;
#    int32_t             reserved;
#define VC_GUID_LEN 128
#    char                guid[VC_GUID_LEN];
#define MAX_UA_LEN 200
#    char                ua[MAX_UA_LEN];
#    char                url[0];
#}ses_vc_swch_info_t;
VC_SWCH_FORMAT="QIIII128s200s1024s"
VC_SWCH_KEYS = ("sid", "sock_fd", "ip", "port","pad", "guid", "ua", "url")
pendingReportList = Queue()

def runPendingReportList():
    global pendingReportList
    logger = logging.getLogger('adgather')
    while True:
        newUrl = pendingReportList.get()
        try:
            curtime = time.time()
            ret = urllib2.urlopen(newUrl).read()
            tDelay = int ((time.time() - curtime)*1000)
            logger.info("URI : [%s] ret : [%s] delay %s ms pending %s", newUrl, ret, tDelay, pendingReportList.qsize())
        except Exception, e:
            logger = logging.getLogger('adgather')
            logger.warning("runPendingReportList URI : [%s] %s %s pending %s", newUrl, e, pendingReportList.qsize())   
            pass
def UrlProxyThread(name):
    logger = logging.getLogger('adgather')
    logger.info("runPendingReportList %s", name)   
    while True:
        try:
            runPendingReportList()
        except Exception, e:
            logger = logging.getLogger('adgather')
            logger.warning("runPendingReportList %s ", e)    
            pass
        time.sleep(1)
def startUrlProxy(idx): 
    try:
        thread = Thread(target=UrlProxyThread, args=("UrlProxyThread-%s"%idx, ) )
        thread.daemon = True
        thread.start()
        #thread.join()
    except Exception, e:
        logger = logging.getLogger('adgather')
        logger.warning("startUrlProxy%s %s ", idx, e)  
        pass
def int2ip(addr):                                                               
    return socket.inet_ntoa(struct.pack("I", addr))  
class adStatus: 
    """This class will subscribe the session swith information, find out the 
    advertisement been played and report to payers"""
    def __init__(self, cfg, debug):
        self.initLog(debug)
        self.adList = dict()
        self.adExtList = dict()
        self.reportCnt = 0
        self.dispatchList = list()
        conf = cfg['configurations']
        
        try:
            infoDbCfg = conf['ad_info_db']
            self.logger.info(infoDbCfg)
            #adInfoDBArg = {"host":"epg.jstv.streamocean.net", "user":"root", "passwd":"db", "db":"so_ads"}
            self.adInfoDB = dbhelper.DB(**infoDbCfg)
   
        except Exception, e:
            print e
            self.logger.warning('Remote AD DB Error%s  ', e)
            raise
            

        #adStatisticDBArg = {"host":"127.0.0.1", "user":"root", "passwd":"db", "db":"so_svr_st"}    
        try:
            adStatisticDBArg = conf['ad_statistics_db']
            self.logger.info(adStatisticDBArg)
            self.adStatisticDB = dbhelper.DB(**adStatisticDBArg)
        except Exception, e:
            self.logger.exception("AD Statistic DB Error %s", e)
            raise
        
        self.testReportHost = conf.get('test_report_host', '')
        self.addbUpInterval = conf.get('ad_info_up_sec', 3600)
        self.msg_svr = conf['msg_svr']
        formatter = logging.Formatter('%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s', \
                        datefmt='%a, %d %b %Y %H:%M:%S')
         
        syslog_server = conf.get('syslog_server', '127.0.0.1:6603')
        sysloghost = syslog_server.split(':')[0]
        syslogport = int(syslog_server.split(':')[1])
        #syslog = SysLogHandler(address=(('%s'%sysloghost, syslogport)))
        syslog = SysLogHandler(address = '/dev/log', facility=SysLogHandler.LOG_LOCAL4)
        syslog.setFormatter(formatter)
        self.logger.addHandler(syslog)    
    def initLog(self, debug = False):
        
        self.logger = logging.getLogger('adgather')
        formatter = logging.Formatter('%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s', \
                        datefmt='%a, %d %b %Y %H:%M:%S')
        if ROOT == '/SO':
            log_path = '/SO_logs/btrace/adgather.log'
        else:
            log_path = 'adgather.log'
        
        filelog = RotatingFileHandler(log_path, maxBytes=50 * 1024 *1024, backupCount=20)
        filelog.setFormatter(formatter)
        # add ch to logger
        self.logger.addHandler(filelog)
        logging.getLogger('db').addHandler(filelog)
        
        
        if debug:
            console = logging.StreamHandler()
            self.logger.addHandler(console)
        
            self.logger.setLevel(logging.DEBUG)
            self.logger.debug("Set log level to debug mode")
        else:
            self.logger.setLevel(logging.INFO)
            
            
    def dispatchReport(self, url):
        global pendingReportList
        if pendingReportList.qsize() > 32 * 4 *1024: 
            self.logger.warning("pendingReportList %s drop", pendingReportList.qsize())
            return
        pendingReportList.put(url)
        
    def adListDiff(self, new, old):
        added = dict()
        deleted = dict()
        kept = dict()
        for key in new:
            if key in old: kept[key] = new[key] 
            else: added[key] = new[key] 
        for key in old:
            if key not in new: deleted[key] = old[key] 
        return  added, deleted, kept   
    def updateCachedAd(self):
        sql = """select ad2vod_ingestion.ad2vod_guid , ad_info.ad_imptraurl, ad_info.ad_extension from ad2vod_ingestion, ad_info where ad_info.ad_id = ad2vod_ingestion.ad_id;"""
        try:
            ret = self.adInfoDB.executeAndFetch(sql)
        except Exception, e:
            self.logger.warning("Can not update ad data %s", e)
            return None
        if ret is None or len(ret) == 0:
            self.logger.warning("Ad data empty")
            return None
        newAdList = dict()
        newAdExtList = dict()
        for item in ret:
            key = item[0]
            value = item[1]
            newAdList[key] = value
            if len(item) > 2:
                newAdExtList[key] = item[2]
        added, deleted, kept = self.adListDiff(newAdList, self.adList)  
        if len(added)!= 0 or len(deleted)!= 0:
            self.logger.info("Updated ad list added %s, deleted %s, kept len %s", added, deleted, len(kept))
        else:
            self.logger.info("Updated ad list, no change, ad list len %s", len(kept))
        self.adList = newAdList 
        self.adExtList = newAdExtList 
        self.logger.debug("Updated ad list %s", self.adList)
    def saveInfo(self, ip, mac, guid, ua):
        ipint = int(ip)
        sql = """INSERT INTO ad_statistic_t SET ip=%s, mac='%s', guid='%s', ua='%s';"""%(ipint, mac, guid, ua)
        try:
            #ret = self.adStatisticDB.executeOnly(sql)
            pass
        except Exception, e:
            self.logger.warning("Save to ad statistics error %s ", e)
            
    
    def parseVcSwitchMsg(self, message):
        """Parse the received message to a dict"""
        try:
            values = map(lambda v: v.strip('\0') if isinstance(v, str) else v, 
                         struct.unpack(VC_SWCH_FORMAT, message))
            swchIfo = dict(zip(VC_SWCH_KEYS, values))
        except Exception, e:
            self.logger.warning("Can not recognize message %s %s", message, e)
            return None
        return swchIfo
    def getdm(self, swchIfo):
        ua = swchIfo['ua']
        url = swchIfo['url']
        if 'Alilive' in ua or 'sp=7po' in url:
            return '7po'
        else:
            return 'VLC'
        
    def report(self, swchIfo):
        """Fill the ad info to the URL which the payer want to get"""
        guid = swchIfo['guid']
        if guid not in self.adList:
            return #Not a ad guid
		        
        url = swchIfo['url']
	#halimin
	ipintT = swchIfo['ip']
        ipstrT = int2ip(ipintT)
	self.logger.info("guid : [%s] ip : [%s] Session URL: %s UA: %s"%(guid, ipstrT, url, swchIfo['ua'])) 
        #self.logger.info("guid : [%s] Session URL: %s UA: %s"%(guid, url, swchIfo['ua'])) 
	#ip
        ipint = swchIfo['ip']
        ipstr = int2ip(ipint)
        blockIpList = ['127.0.0.1']
        if ipstr in blockIpList:
            self.logger.info("blocked ip %s in list %s", ipstr, blockIpList)
            return
        res = urlparse.urlparse(url)
        query = res.query
        orgSesQueryDict = dict(urlparse.parse_qsl(query))
        #mac
        mac = ''
        if 'mac' not in orgSesQueryDict:
            mac = '000000000000'
        else:
            mac = orgSesQueryDict['mac'].upper()
            if len(mac) != 12:
                mac = '000000000000'
                self.logger.warning("Invalid mac %s"%mac)
        
        macTemp = ''
        for i in range(0, 5):
            macTemp += mac[2*i:2*i+2]
            macTemp += ':' 
        macTemp += mac[10:12]
        
        self.logger.debug("MAC before md5 %s", macTemp)
        m = hashlib.md5(macTemp)
        macMd5 = m.hexdigest()
        
        
        
        self.saveInfo(ipint, mac, guid, swchIfo['ua'])
        
        orgUrl = self.adList[guid]
        #print orgUrl
        dm = self.getdm(swchIfo)
        newUrl = orgUrl.replace('%dm%', dm)
        newUrl = newUrl.replace('%ip%', ipstr)
        newUrl = newUrl.replace('%mac%', macMd5)
        
        if self.testReportHost != '':
            newUrl = newUrl.replace('advapi.joyplus.tv/advapi', self.testReportHost)
        
        
        #print newUrl
        self.reportCnt += 1

        if self.reportCnt % 1000 == 0:
            #print "Reported %s"%self.reportCnt
            self.logger.info("Reported : [%s]"%self.reportCnt)
        try:
            self.dispatchReport(newUrl)
        except Exception, e:
            self.logger.warning("URI : [%s] Failed : [%s]", newUrl, e)
            pass
        curExtList = list()
        if guid in self.adExtList:
            curExtList = self.adExtList[guid]
        curExtList = json.loads(curExtList)    
        for item in curExtList:
            if item['type'] == "report_url":
                for urlitem in item['content'].values():
                    if urlitem != orgUrl:
                        newUrl = urlitem.encode('utf-8')
                        newUrl = newUrl.replace('%dm%', dm)
                        newUrl = newUrl.replace('%ip%', ipstr)
                        newUrl = newUrl.replace('%mac%', macMd5)
                        try:
                            self.dispatchReport(newUrl)
                        except Exception, e:
                            self.logger.warning("Failed : [%s] %s", newUrl, e)
                            pass
    def vc_switchEventHandler(self, message):
        """Handle the vc switch event"""
        swchIfo = self.parseVcSwitchMsg(message)
        if swchIfo is None : 
            return
        self.logger.debug("Parsered msg %s", swchIfo)
        guid = swchIfo['guid']
        
        if guid not in self.adList: 
            self.logger.info("Received guid %s not in list message %s",  guid, swchIfo)
            return
        
        try:
            self.report(swchIfo)
        except Exception, e:
            self.logger.warning("Report error for message %s error %s ", message, e)
            raise
    def run(self):
        context = zmq.Context()
        socket = context.socket(zmq.SUB)
        try:
            socket.connect(self.msg_svr)
            socket.setsockopt(zmq.SUBSCRIBE, "ses_vc_switch")
        except Exception, e:
            self.logger.warning("Can not connect to msg_svr %s %s", self.msg_svr, e) 
        self.logger.debug("Starting to gather ad information...") 
        
        updateTimerStart = time.time()
        self.updateCachedAd()
        while True:
            now = time.time()
            if now - updateTimerStart > self.addbUpInterval:
                self.logger.debug("Update the cached ad guid...") 
                self.updateCachedAd() 
                updateTimerStart = now
            self.logger.debug("Receive....")
            evtType, data = socket.recv_multipart()
                        
            if evtType == "ses_vc_switch":
                events = event_pack.unpack(data)
                self.logger.debug("Received len %s", len(events))
                self.logger.debug("data: %s", events)
                self.vc_switchEventHandler(events[0])
            else:
                self.logger.warning("Get wrong msg %s", evtType)
def loadcfg(path):
    try:
        f = open(path)
        content = f.read()
        name, val = xmlhelper.parseSimpleXmlConfig(content)
    except Exception as e: 
        print e
        self.logger.warning("loadcfg error %s", e)
        sys.exit(1)
    assert(name == 'so_ad_srv')
    return val
    
def main():
    try:
        opts, _ = getopt.getopt(sys.argv[1:], "dc:m")
    except getopt.GetoptError, err:
        print str(err)
        sys.exit(1)
    debug = False
    cfg = dict()
    for opt, val in opts:
        if opt == "-d":
            debug = True
            print "Debug ..."
        elif opt == "-c":
            try:
                cfg = loadcfg(val)
            except:
                print "Please check you cfg file"
                sys.exit(1)
            
    
    if cfg['configurations']['enable'] != 1:
        time.sleep(5)
        sys.exit(1)
        
    try:
        ap = adStatus(cfg, debug)
    except Exception, e:
        print e
        print "Init error"
        sys.exit(1)
    for i in range(0, 16):    
        startUrlProxy(i)    
    ap.run() 

if __name__ == "__main__":
    main() 
        


