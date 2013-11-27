#!/usr/local/bin/python
# -*- coding: utf-8 -*-
import os,urllib2,urllib
path = '~/download/'
name = 'banner.jpg'
name = os.path.join(path,name)
url = "http://www.cnscn.com.cn/company/skin/default/banner.jpg"
urllib.urlretrieve(url,name)
