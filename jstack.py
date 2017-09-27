#!/usr/bin/python

import commands
import os
import sys
import string
import datetime

def main():
    pid = os.popen("ps -ef|grep 'Dpinpoint.applicationName=pay_web'|grep -v 'grep'|awk '{print $2}'").read().rstrip()
    if pid != "":
        dumpThread(pid)
    else:
       print "Can't find pay_web Process"


def dumpThread(pid):
    try:
        filename = "/var/log/thread_dump/pay_web_"+datetime.datetime.strftime(datetime.datetime.today(),'%y%m%d_%H%M')+".txt"
        os.system("su - sre -c \" jstack " + pid + "  > " + filename + "\"")
        print filename+" has created!"
    except Exception, ex:
        print str(ex)
        pass

main()
