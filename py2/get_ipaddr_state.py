#!/usr/bin/env python3
# coding:utf-8

'''
@Author: cnak47
@Date: 2018-04-30 23:59:11
@LastEditors  : cnak47
@LastEditTime : 2020-01-11 18:02:25
@Description: 
'''
# coding:utf-8
import sys
import socket
import json

if sys.version_info[0] == 2:
    import urllib2 as request
else:
    import urllib.request as request

try:
    socket.setdefaulttimeout(5)
    if len(sys.argv) == 1:
        apiurl = "http://ip-api.com/json"
    elif len(sys.argv) == 2:
        apiurl = "http://ip-api.com/json/%s" % sys.argv[1]
    content = request.urlopen(apiurl).read().decode('utf-8')
    content = json.JSONDecoder().decode(content)
    if content['status'] == 'success':
        print(content['countryCode'])
    else:
        print("CN")
except:
    print("Usage:%s IP" % sys.argv[0])

