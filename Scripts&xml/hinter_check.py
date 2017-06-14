#!/usr/bin/env python

import sys, os, struct, re
from time import strftime, localtime

PATTERN = re.compile("^([0-9a-fA-F]{32})-([0-9a-fA-F]{32})$")


def usage(msg=None):
    if msg:
        print msg
    print "Usage:"
    print "\t %s hinter_dir_path" % sys.argv[0]
    sys.exit(0)

def str2num(s):
    data = s.decode("hex")
    a, b = struct.unpack("QQ", data)
    return float(a) + float(b) / 1e9

if len(sys.argv) < 2:
    usage()
path = sys.argv[1]
if not os.path.isdir(path):
    usage("%s is not a dir!" % path)

hinters = list()
files = os.listdir(path)
for f in files:
    p = os.path.join(path, f)
    if not os.path.isfile(p):
        continue
    m = PATTERN.match(f)
    if not m:
        continue
    start = str2num(m.group(1))
    end = str2num(m.group(2))
    hinters.append((start, end))

hinters.sort()
def range_print(rng):
    s,e = rng
    print "[%s - %s][%.3f - %.3f][%.3f]" % tuple(
        map(lambda s:strftime("%Y%m%d %H:%M:%S", localtime(s)), rng)
        + list(rng) + [e - s]
    )

def check(curr, next):
    start = curr[1]
    end = next[0]
    gap = end - start
    range_print(curr)
    if 0 < gap <= 2:
        pass
    elif gap < 0:
        # overlap range
        print "!!Overlap %.3f sec." % -gap
    elif gap == 0:
        print "!!Duplicated %.3f" % curr[0]
    else:
        print "!!Missed %.3f sec." % gap
    return next
        
ret = reduce(check, hinters)
range_print(ret)

