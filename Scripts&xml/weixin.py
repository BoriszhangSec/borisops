#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import sys
import urllib
import urllib2

reload(sys)
sys.setdefaultencoding("utf-8")


class WeChat(object):
    __token_id = ''

    def __init__(self, url):
        self.__url = url.rstrip('/')
        self.__corpid = 'wx9254b18589b95cd4'
        self.__secret = '4OgBBNVqKvS9gPILsExoyvl0QfvptmLZN69Btlmw4nQesF4UttOrPFk4WN0PIUbM'

    def authID(self):
        params = {'corpid': self.__corpid, 'corpsecret': self.__secret}
        data = urllib.urlencode(params)
        content = self.getToken(data)
        try:
            self.__token_id = content['access_token']
        except KeyError:
            raise KeyError

    def getToken(self, data, url_prefix='/'):
        url = self.__url + url_prefix + 'gettoken?'
        try:
            response = urllib2.Request(url + data)
        except KeyError:
            raise KeyError
        result = urllib2.urlopen(response)
        content = json.loads(result.read())
        return content

    def postData(self, data, url_prefix='/'):
        url = self.__url + url_prefix + 'message/send?access_token=%s' % self.__token_id
        request = urllib2.Request(url, data)
        try:
            result = urllib2.urlopen(request)
        except urllib2.HTTPError as e:
            if hasattr(e, 'reason'):
                print
                'reason', e.reason
            elif hasattr(e, 'code'):
                print
                'code', e.code
            return 0
        else:
            content = json.loads(result.read())
        return content

    def sendMessage(self, touser, message):
        self.authID()

        data = json.dumps({
            'touser': touser,
            'toparty': "1",
            'msgtype': "text",
            'agentid': "0",
            'text': {
                'content': message
            },
            'safe': "0"
        }, ensure_ascii=False)

        response = self.postData(data)
        print
        response


if __name__ == '__main__':
    a = WeChat('https://qyapi.weixin.qq.com/cgi-bin')
    a.sendMessage(sys.argv[1], sys.argv[3])
