#!/usr/bin/python26

import socket, sys, json


def getRawData(duration, port=3126):
    cmd = ["hsp", "hsv", duration]
    sock = socket.socket()
    try:
        sock.connect(("127.0.0.1", 3126))
        sock.sendall(json.dumps(cmd) + "\r\n")
        buff = ""
        idx = 0
        while idx <= 0:
            data = sock.recv(4096)
            if data is None or data == "":
                return None
            buff += data
            idx = buff.find("\r\n")
        return json.loads(buff[:idx])
    except:
        return None
    finally:
        sock.close()

def dataCheck(data):
    if data is None:
        return 4
    elif isinstance(data, list):
        return 0
    elif isinstance(data, int):
        return data
    else:
        return 0

def getPercent(duration, state):
    data = getRawData(duration)
    ret = dataCheck(data)
    if ret == 0:
        total = 0
        num = 0
        for s, n in data:
            if int(s) == state:
                num = n
            total += n
        if total > 0:
            print "%.02f" % (float(num) / float(total) * 100)
        else:
            print "0.00"
        return 0
    else:
        return ret
                

def getNumber(duration, state):
    data = getRawData(duration)
    ret = dataCheck(data)
    if ret == 0:
        for s, n in data:
            if int(s) == state:
                print n
                return 0
        else:
            print 0
    else:
        return ret

def getRaw(duration):
    data = getRawData(duration)
    ret = dataCheck(data)
    if ret == 0:
        for s, n in data:
            print "% 03d\t%d" % (s, n)
    else:
        print "Error: error number is", ret
        return ret
    
def usage(msg=""):
    if msg != "":
        print msg
    print """Usage: python26 http_state.py mode duration state
    mode       Should be percent or number or raw.
    duration   Only the log accessed in the last duration seconds will be returned.
    state      The HTTP state you want to query.
    """
    sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) not in (3, 4):
        usage()
        
    mode = sys.argv[1]

    try:
        duration = int(sys.argv[2])
        if duration <= 0:
            raise Exception()
    except:
        usage("duration MUST be a positive integer!") 
    
    if mode == "raw":
        sys.exit(getRaw(duration))
        
    try:
        state = int(sys.argv[3])
        if state not in (200, 403, 404, 500, 503):
            raise Exception()
    except:
        usage("Unsupported state %s", sys.argv[3])
        
    
    if mode == "percent":
        ret = getPercent(duration, state)
    elif mode == "number":
        ret = getNumber(duration, state)
    else:
        usage("mode %s is unknown!" % mode)
        
    sys.exit(ret)
        