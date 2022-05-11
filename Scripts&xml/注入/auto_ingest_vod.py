import httplib
import sys
import urllib
from urlparse import urlparse

UPLOAD_MF = 'http://localhost:8080/upload_mf.php'
guid = 'mp4_'
x = sys.argv[1]
XML_DATA = x
try:
    url = urlparse(UPLOAD_MF)
    xml_data = urllib.urlencode({'dataContent': XML_DATA, 'dataType': 'xml'})
    headers = {'Content-type': 'application/x-www-form-urlencoded'}
    conn = httplib.HTTPConnection(url[1])
    conn.request('POST', url[2], xml_data, headers)
    response = conn.getresponse()
    print
    '>>>>>>Ingest', response.status, response.reason, UPLOAD_MF
    data = response.read()
    # print data
    conn.close()
except Exception, e:
    print
    e
