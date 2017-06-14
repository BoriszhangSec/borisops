#!/usr/bin/env python
# -*- coding: utf-8 -*-

import tornado.ioloop
import tornado.web
import MySQLdb
import json
import ad_db_conn
import ad_db


import sys

reload(sys)
sys.setdefaultencoding('utf-8')


class MainHandler(tornado.web.RequestHandler):
    
    def get(self):
        self.render("index.html")
   
    def post(self):
        #self.set_header("Content-Type", "text/json")
        #self.write("You wrote " + self.get_argument("message"))
        epg_str = str(self.get_argument("data"))
    		f = open('/opt/so_ads/jstv_epg.txt','a')
        f.write(epg_str)
        f.write("\n")
        f.close()
        #print "type(epg_str):%s\n" %type(epg_str)
        #print "epg_st:%s" % epg_str
        epg_list = json.loads(epg_str)
        ad_db.add_update_epg_info(epg_list)
        self.write("You wrote " + self.get_argument("data"))

    
application = tornado.web.Application([
    (r"/", MainHandler),
])

if __name__ == "__main__":
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()
