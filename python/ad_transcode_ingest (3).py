#!/usr/bin/env python2.6
#  -*- coding: utf-8 -*-
#
#  @file ad_transcode_ingest.py
#  @brief A Documented file.
#
#  @author liyunteng <liyunteng@streamocean.com>
#  @copyright CopyRight (C) 2017 StreamOcean
#  @date Last-Updated: 2017/05/24 14:36:56


import os
import sys
import time
import urllib2
import MySQLdb
import MySQLdb.cursors
import hashlib
import commands
import httplib
import urllib
import copy
import logging
import so_version
from urlparse import urlparse

root = os.environ.get("CALIDUS_ROOT_DIR", "/SO")
ad_sources_dir      ='/opt/adsources'
ad_transcode_dir    ='/opt/adtranscoded'
ads_dir             = os.path.join(root, "gui/ads/")
ffmpeg_bin          = os.path.join(root,'bin/ad_config-'+so_version.__version__ + '/ffmpeg/bin/ffmpeg')
server_ip           = '127.0.0.1'
upload_mf           = 'http://%s:%d/upload_mf.php'
vod_source          = 'http://%s:%d/ads/%s'

ad_pro_status       = {'init':0, 'downloaded':1, 'transcoded':2, 'ingested':3}

g_chnl_type         = [{'type': 0, 'name': 'type0', 'reselution':'1280x720',
                           'framerate': '25.00', 'aspect': '16:9', 'bitrate': '1000k',
                           'audiosample': '44100', 'audiorate':'42k'},
                       {'type': 1, 'name': 'type1', 'reselution': '1280x720',
                           'framerate': '25.00', 'aspect': '16:9', 'bitrate': '2000k',
                           'audiosample': '44100', 'audiorate':'42k'}]


xml_ingest='''<root>
  <upload>
    <content>
      <ctype>vod</ctype>
      <createdate>2017-03-22</createdate>
          <expireddate>2038-03-22</expireddate>
      <files>
        <file>
          <name><![CDATA[%s]]></name>
        </file>
      </files>
      <guid>%s</guid>
    </content>
  </upload>
</root>
'''

xml_delete='''
<root>
    <task_uuid>0</task_uuid>
    <delete>
        <content>
            <guid>%s</guid>
            <ctype>live</ctype>
            <expireddate></expireddate>
        </content>
    </delete>
</root>'''

log = logging.getLogger("ad_config")

def open_db_conn(i_host, i_user, i_pwd, i_db):
    conn = MySQLdb.Connect(i_host, user=i_user, passwd=i_pwd, db=i_db, charset='utf8')
    return conn

def open_db_cur(conn):
    cur = conn.cursor()
    return cur

def close_db_conn(conn):
    conn.close()

def close_db_cur(cur):
    cur.close()

class Ad_Transcode_Ingest(object):
    def __init__(self, port):
        self.port = port

    def get_init_ad_list(self, ad_provider):
        ad_init = list()
        try:
            conn = open_db_conn(server_ip, 'root', 'db', 'so_ads')
            cur = open_db_cur(conn)
            sql = "select ad_id,ad_hash,ad_downloadurl from ad_info where ad_prostatus='%d' and ad_provider='%s';"%(ad_pro_status['init'], ad_provider)
            cur.execute(sql)
            conn.commit()
            data = cur.fetchall()
            if 0 == len(data):
                return None
            else:
                for a in data:
                    keys = ('ad_id', 'ad_hash', 'ad_downloadurl')
                    ad_init.append(dict(zip(keys, a)))
            close_db_cur(cur)
            close_db_conn(conn)
        except MySQLdb.Error,e:
            log.info("Mysql Error %d: %s", e.args[0], e.args[1])
            return None
        return ad_init

    def download_ad(self, vodhash, vodurl):
        file_name = ad_sources_dir + '/' + vodhash + '.' + vodurl.split('.')[-1]
        log.info("downloading file: %s", file_name)
        u = urllib2.urlopen(vodurl)
        f = open(file_name, 'wb')
        meta = u.info()
        file_size = int(meta.getheaders("Content-Length")[0])
        file_size_dl = 0
        block_sz = 8192
        while True:
            buffer = u.read(block_sz)
            if not buffer:
                break
            file_size_dl += len(buffer)
            f.write(buffer)
        f.close()
        if (file_size != file_size_dl):
            log.error("Content-Length: [%d] != file size[%d]", file_size, file_size_dl)
        log.info("downloaded file: %s", file_name)
        return file_name


    def download_ad_list(self, init_ad_list):
        download_fn = list()
        for ad in init_ad_list:
            try:
                file_name = self.download_ad(ad['ad_hash'], ad['ad_downloadurl'])
                download_fn.append(file_name)
                conn = open_db_conn(server_ip, 'root', 'db', 'so_ads')
                cur = open_db_cur(conn)
                sql = "update ad_info set ad_prostatus=%d where ad_id=%d" %(ad_pro_status['downloaded'], ad['ad_id'])
                cur.execute(sql)
                conn.commit()
                close_db_cur(cur)
                close_db_conn(conn)
            except Exception,e:
                log.exception(e)
                continue
        return download_fn



    def get_downloaded_ad_list(self, ad_provider):
        ad_downloaded = list()
        try:
            conn = open_db_conn(server_ip, 'root', 'db', 'so_ads')
            cur = open_db_cur(conn)
            sql = "select ad_id, ad_hash, ad_downloadurl from ad_info where ad_prostatus='%d' and ad_provider='%s'"%(ad_pro_status['downloaded'], ad_provider)
            cur.execute(sql)
            conn.commit()
            data = cur.fetchall()
            if 0 == len(data):
                return None
            else:
                for a in data:
                    keys = ('ad_id', 'ad_hash', 'ad_downloadurl')
                    ad_downloaded.append(dict(zip(keys, a)))
            close_db_cur(cur)
            close_db_conn(conn)
        except MySQLdb.Error,e:
            log.info("Mysql Error %d: %s", e.args[0], e.args[1])
            return None
        return ad_downloaded

    def transcode_ad(self, ad, live_type):
        ad_name_src = ad_sources_dir + '/' + ad['ad_hash'] + '.' + ad['ad_downloadurl'].split('.')[-1]
        log.info("transcoding %s ", ad_name_src)
        ad_name_trsd = ad_transcode_dir + '/' + ad['ad_hash'] + '_'  + live_type['name'] + '.ts'
        transcode_cmd   = ('%s -y -i %s -vcodec libx264 -streamid 1:257 -streamid 0:256 -s %s '
                          '-r %s -aspect %s -b:v %s -c:a libfdk_aac '
                          '-profile:a aac_low -ar %s -b:a %s -vol 80 %s'
                          '-vf movie=/opt/logo/logo.png[logo]\;[in][logo]overlay=main_w-overlay_w-100:0[out]'
                           %(ffmpeg_bin, ad_name_src, live_type['reselution'], live_type['framerate'], live_type['aspect'],
                             live_type['bitrate'] , live_type['audiosample'], live_type['audiorate'], ad_name_trsd))

        # if live_type == g_live_type[0]:
        #     ad_name_trsd    = ad_transcode_dir + '/' + ad['ad_hash'] + '_type0.ts'
        #     transcode_cmd   = '''%s -y -i %s -vcodec libx264 -streamid 1:257 -streamid 0:256 -s 1280x720 \
        #                         -r 25.00 -aspect 16:9 -b:v 1000k -c:a libfdk_aac \
        #                         -profile:a aac_low -ar 44100 -b:a 42k -vol 80 %s'''%(ffmpeg_bin, ad_name_src, ad_name_trsd)
        # elif live_type == g_live_type[1]:
        #     ad_name_trsd    = ad_transcode_dir + '/' + ad['ad_hash'] + '_type1.ts'
        #     transcode_cmd   = '''%s -y -i %s -vcodec libx264 -streamid 1:257 -streamid 0:256 -s 1280x720 \
        #                         -r 25.00 -aspect 16:9 -b:v 2000k -c:a libfdk_aac \
        #                         -profile:a aac_low -ar 44100 -b:a 42k -vol 80 %s'''%(ffmpeg_bin, ad_name_src, ad_name_trsd)

        #print transcode_cmd
        (status, output) = commands.getstatusoutput(transcode_cmd)
        if (0 == status):
            log.info("transcode %s----->%s success", ad_name_src, ad_name_trsd)
        else:
            log.error("transcode may have error, should check it, cmd[%s], status %d", transcode_cmd, status)
        commands.getstatusoutput('cp %s %s'%(ad_name_trsd, ads_dir))
        return ad_name_trsd

    def transcode_ad_list(self, downloaded_ad_list):
        transcode_ad_list = list()
        for ad in downloaded_ad_list:
            for chnl_type in g_chnl_type:
                ad_name_trsd = self.transcode_ad(ad, chnl_type)
                transcode_ad_list.append(ad_name_trsd)
            try:
                conn = open_db_conn(server_ip, 'root', 'db', 'so_ads')
                cur = open_db_cur(conn)
                sql = "update ad_info set ad_prostatus=%d where ad_id=%d" %(ad_pro_status['transcoded'], ad['ad_id'])
                cur.execute(sql)
                conn.commit()
                close_db_cur(cur)
                close_db_conn(conn)
            except MySQLdb.Error,e:
                log.info("Mysql Error %d: %s", e.args[0], e.args[1])
                return None
        return transcode_ad_list

    def get_transcoded_ad_list(self, ad_provider):
        ad_transcoded = list()
        try:
            conn = open_db_conn(server_ip, 'root', 'db', 'so_ads')
            cur = open_db_cur(conn)
            sql = "select ad_id, ad_hash from ad_info where ad_prostatus='%d' and ad_provider='%s'"%(ad_pro_status['transcoded'], ad_provider)
            cur.execute(sql)
            conn.commit()
            data = cur.fetchall()
            if 0 == len(data):
                return None
            else:
                for a in data:
                    keys = ('ad_id', 'ad_hash')
                    ad_transcoded.append(dict(zip(keys, a)))
            close_db_cur(cur)
            close_db_conn(conn)
        except MySQLdb.Error,e:
            log.info("Mysql Error %d: %s", e.args[0], e.args[1])
            return None
        return ad_transcoded

    def ingest_xml(self, src_file, guid):
        XML_DATA=xml_ingest%(src_file, guid)
        log.info("ingesting src[%s], guid[%s]", src_file, guid)
        try:
            url = urlparse(upload_mf % (server_ip, int(self.port)))
            xml_data = urllib.urlencode({'dataContent': XML_DATA, 'dataType': 'xml'})
            headers = {'Content-type': 'application/x-www-form-urlencoded'}
            conn = httplib.HTTPConnection(url[1])
            conn.request('POST', url[2], xml_data, headers)
            response = conn.getresponse()
            sta = response.status
            data = response.read()
            conn.close()
            time.sleep(45)
        except Exception, e:
            log.info(e)
        else:
            return guid

    def check_ingest(self, ad, src_file, guid):
        try:
            check_cmd='%s/bin/cns-walk -a | grep %s'%(root, guid)
            status,output = commands.getstatusoutput(check_cmd)
            log.info("check cmd [%s]\nstatus [%d], output [%s]", check_cmd, status, output)

            if 0 != status or 0 == len(output):
                log.error("ingest src[%s], guid[%s] failed", src_file, guid)
                return None
            log.info("ingest src[%s], guid[%s] success", src_file, guid)
            return output
        except Exception,e:
            log.exception(e)
            return None

    def ingest_ad(self, ad, conn, cur, chnl_type):
        try:
            src_file    = vod_source % (server_ip, int(self.port), ad['ad_hash'] + '_' + chnl_type['name'] + '.ts')
            # guid        = 'ad_' + ad['ad_hash'] + '_' + chnl_type['reselution'] + '_' + chnl_type['bitrate'] + '_' + chnl_type['name']
            guid        = 'ad_' + ad['ad_hash'] + '_' + chnl_type['name']
            self.ingest_xml(src_file, guid)
            output      = self.check_ingest(ad, src_file, guid)
            if None == output:
                return None
            sql='''insert into ad2vod_ingestion \
                (ad_id, ad2vod_guid, ad2vod_codec, ad2vod_url, ad_hash, ad_type) \
                values('%d','%s','x264','%s','%s','%d')''' \
                % (ad['ad_id'], guid, output, ad['ad_hash'], chnl_type['type'])
            cur.execute(sql)
            conn.commit()
        except MySQLdb.Error,e:
            log.info("Mysql Error %d: %s", e.args[0], e.args[1])
        else:
            return guid


    def ingest_ad_list(self, transcode_ad_list):
        conn = open_db_conn(server_ip, 'root', 'db', 'so_ads')
        cur = open_db_cur(conn)
        ingest_ad_list = list()
        for ad in transcode_ad_list:
            try:
                for chnl_type in g_chnl_type:
                    guid = self.ingest_ad(ad, conn, cur, chnl_type)
                    if None == guid:
                        continue
                    else:
                        ingest_ad_list.append(guid)

                sql = "update ad_info set ad_prostatus=%d where ad_id=%d" %(ad_pro_status['ingested'], ad['ad_id'])
                cur.execute(sql)
                conn.commit()
            except MySQLdb.Error,e:
                log.info("Mysql Error %d: %s", e.args[0], e.args[1])
                continue
        close_db_cur(cur)
        close_db_conn(conn)
        return ingest_ad_list


    def get_imcomplete_ad_list(self, ad_provider):
        ad_transcoded = list()
        try:
            conn = open_db_conn(server_ip, 'root', 'db', 'so_ads')
            cur = open_db_cur(conn)
            sql = "select * from ad_info where ad_prostatus = 0 or ad_prostatus = 1 or ad_prostatus = 2 and ad_provider='%s'" % (ad_provider)
            cur.execute(sql)
            conn.commit()
            data = cur.fetchall()
            if 0 == len(data):
                return None
            else:
                for a in data:
                    keys = ('ad_id', 'ad_hash')
                    ad_transcoded.append(dict(zip(keys, a)))
            close_db_cur(cur)
            close_db_conn(conn)
        except MySQLdb.Error,e:
            log.info("Mysql Error %d: %s", e.args[0], e.args[1])
            return None
        return ad_transcoded

    def transcode_ingest(self, ad_provider):
        if False == os.path.exists(ad_sources_dir):
            os.makedirs(ad_sources_dir)

        if False == os.path.exists(ad_transcode_dir):
            os.makedirs(ad_transcode_dir)

        if False == os.path.exists(ads_dir):
            os.makedirs(ads_dir)

        log.info("="*30+"getting ad list needed to download"+"="*30)
        init_ad_list = self.get_init_ad_list(ad_provider)
        if (None == init_ad_list):
            log.info("no ad list needed to download")
        else:
            log.info("ad list needed to download: [%d]\n%s\n\n", len(init_ad_list), init_ad_list)
            log.info("="*30+"starting download file"+"="*30)
            downloaded_ad_list = self.download_ad_list(init_ad_list)
            log.info("downloaded ad list: [%d]\n%s", len(downloaded_ad_list), downloaded_ad_list)
            log.info("="*30+"download file over"+"="*30+"\n\n")

        log.info("="*30+"getting ad list needed to transcode"+"="*30)
        downloaded_ad_list = self.get_downloaded_ad_list(ad_provider)
        if (None == downloaded_ad_list):
            log.info("no ad list needed to transcode")
        else:
            log.info("ad list needed to transcode: [%d]\n%s\n\n", len(downloaded_ad_list), downloaded_ad_list)
            log.info("="*30+"starting transcode file"+"="*30)
            transcode_ad_list = self.transcode_ad_list(downloaded_ad_list)
            log.info("transcode ad list: [%d]\n%s", len(transcode_ad_list), transcode_ad_list)
            log.info("="*30+"transcode file over"+"="*30+"\n\n")

        log.info("="*30+"getting ad list needed to ingest"+"="*30)
        transcoded_ad_list = self.get_transcoded_ad_list(ad_provider)
        if (None == transcoded_ad_list):
            log.info("no ad list needed to ingest")
        else:
            log.info("ad list needed to ingest: [%d]\n%s\n\n", len(transcoded_ad_list), transcoded_ad_list)
            log.info("="*30+"starting ingest file"+"="*30)
            ingest_ad_list = self.ingest_ad_list(transcoded_ad_list)
            log.info("ingest ad list: [%d]\n%s", len(ingest_ad_list), ingest_ad_list)
            log.info("="*30+"ingest file over"+"="*30+"\n\n")

        incomplete_ad_list = self.get_imcomplete_ad_list(ad_provider)
        if None == incomplete_ad_list:
            log.info("all the ad have been ingested, %s and %s will be deleted", ad_transcode_dir, ads_dir)
            #commands.getstatusoutput('rm -rf %s'%(ad_sources_dir))
            commands.getstatusoutput('rm -rf %s'%(ad_transcode_dir))
            commands.getstatusoutput('rm -rf %s'%(ads_dir))

    def delete_ad_from_vdn(self, guid):
        for g in guid:
            log.info("deleting guid[%s]", g)
            XML_DATA=xml_delete % (g)
            try:
                url = urlparse(upload_mf % (server_ip, int(self.port)))
                xml_data = urllib.urlencode({'dataContent': XML_DATA, 'dataType': 'xml'})
                headers = {'Content-type': 'application/x-www-form-urlencoded'}
                conn = httplib.HTTPConnection(url[1])
                conn.request('POST', url[2], xml_data, headers)
                response = conn.getresponse()
                sta = response.status
                data = response.read()
                conn.close()
                time.sleep(15)
                check_cmd='%s/bin/cns-walk -a|grep %s'%(root, g)
                output = commands.getoutput(check_cmd)
                log.info("check cmd[%s], output[%s]", check_cmd, output)
                if 0 == len(output):
                    log.info("delete guid[%s] success", g)
                else:
                    log.info("delete guid[%s] failed", g)
            except MySQLdb.Error, e:
                log.info("Mysql Error %d: %s", e.args[0], e.args[1])


if __name__=="__main__":
    obj = Ad_Transcode_Ingest()
    obj.transcode_ingest()
