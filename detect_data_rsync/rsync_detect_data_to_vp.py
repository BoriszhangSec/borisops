#!/usr/bin/env python2.6
#! -*- coding: utf-8 -*-

import tornado.ioloop
import tornado.web
import tornado.httpserver
import os

class RsyncHandler(tornado.web.RequestHandler):
    def get(self):
		data = "data123"
		output = os.popen('sh /opt/adsyn/rsync_addtect_to_vp.sh')
		#print output.read()
		self.write("Status: " + output.read())

    def post(self):
        '''
        self.set_header("Content-Type", "text/plain")
        self.write("You wrote " + self.get_argument("message"))
        '''  

settings = {
        "static_path":os.path.join(os.path.dirname(__file__), ""),
}

application = tornado.web.Application([
    (r"/", RsyncHandler),
], **settings)

if __name__ == "__main__":
    http_server = tornado.httpserver.HTTPServer(application)
    http_server.listen(8888)
    tornado.ioloop.IOLoop.instance().start()

