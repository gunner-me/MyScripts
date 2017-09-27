#!/usr/bin/python
# -*- #coding:cp936

import os

filename = raw_input('Enter filname:')
lines = raw_input('Enter the number of rows you want:')
lines = int(lines)
block_size = 1024
block = ''
nl_count = 0
start = 0
newfile = filename + '_last_' + str(lines) + '_lines' + '.txt'
newfsock = open(newfile, 'w')
fsock = file(filename, 'rU')
try:
    fsock.seek(0, 2)
    curpos = fsock.tell()
    while(curpos > 0):
        curpos = curpos - (block_size + len(block));
        if curpos < 0:
             curpos = 0
        fsock.seek(curpos)
        block = fsock.read()
        nl_count = block.count('\n')
        if nl_count >= lines:
             break
    for n in range(nl_count-lines+1):
        start = block.find('\n', start)+1 
finally:
    fsock.close()
newfsock.write(block[start:])
newfsock.close()
