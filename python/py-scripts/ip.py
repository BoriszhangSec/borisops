#!bin/env python  
# -*- coding: utf8 -*-
import os

# 用只读的方式打开文件
f = open("./iplist.txt", "r")

# 遍历文件f的每一行，并使用ping命令加上每一行的内容在command中执行
for line in f.readlines():
    os.system("ping " + line + " -c 2")
f.close()
