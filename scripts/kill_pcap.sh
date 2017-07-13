#!/bin/bash
kill -9 `ps -ef |grep pcapsipdump |grep -v grep |head -1 |awk '{print$2}'`
