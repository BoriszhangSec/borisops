#!/usr/bin/python2.4
import os, re, sys

db = None

def init():
    root = os.getenv("CALIDUS_ROOT_DIR", "/SO")
    if root == "/SO":
        path = "/SO_db/ccg_cns_db"
    else:
        path = "/root/Calidus.tmp/ccg_cns_db"
    
    global db
    db = CnsDB(path)

def get(guid):
    mids = db.get(guid)
    if mids is None:
        print "Didn't find any record match guid", guid
        return
    print "Those machined have content", guid
    for mid in mids:
        print "\t", mid

def set(guid, mids):
    if len(mids) == 0:
        print "Mid list is empty, nothing to do."
        return
    for mid in mids:
        if not re.match("[0-9a-fA-F]{32}", mid):
            print "Mid %s is not correct, it must be 32 bytes hex string.", mid
            return
    db.update(guid, mids)
    print "Set successed."
    get(guid)

def delete(guid):
    db.delete(guid)
    print "Delete successed."

def usage():
    print "Usage: %s {get|set} guid [mid] ... " % sys.argv[0]
    sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        usage()
    
    root = os.getenv("CALIDUS_ROOT_DIR", "/SO")
    sys.path.append(os.path.join(root, "lib"))
    sys.path.append(os.path.join(root, "lib/libtaskmgr.zip"))
    
    from cnsdb import CnsDB

    init()
    if sys.argv[1] == "get":
        get(sys.argv[2])
    elif sys.argv[1] == "set":
        set(sys.argv[2], sys.argv[3:])
    elif sys.argv[1] == "del":
        delete(sys.argv[1])
    else:
        usage()

