#!/usr/bin/python2.4
import sys, os

ROOT=os.environ.get("CALIDUS_ROOT_DIR", "/SO")
LIBS=os.path.join(ROOT, "lib")

sys.path.insert(0, LIBS)

files = os.listdir(LIBS)
for name in files:
    if name.endswith("zip"):
        file_path = os.path.join(LIBS, name)
        sys.path.insert(0, file_path)

from cnsdb import CnsDB, DBError
import libpyccgdb as cnsdb

class LengthException(Exception):pass
class FormatException(Exception):pass

def check(token):
    if len(token) != 32:
        raise LengthException("Unexcepted length %d of %s" % (len(token), token))
    try:
        token.decode("hex")
    except:
        raise FormatException("Unknown format of %s" % token)
    return True


def insert(db, presid, owners):
    mids = "".join(owners)
    db.updatebycid(presid, mids)

def get_owner(db, presid):
    rc = cnsdb.db_get(presid)
    if rc == -1:
        raise DBError("DB GET failed, guid=%s, rc=%d" % (guid, rc))
    elif rc is None:
        return set()
    else:
        return set([rc[i:i+32] for i in range(0, len(rc), 32)])

def main():
    if len(sys.argv) < 3:
        print "Usage:\n\t%s UUID presid_list_file" % sys.argv[0]
        return 1

    uuid = sys.argv[1].upper()
    try:
        check(uuid)
    except Exception, e:
        print "UUID is not correct: %s" % str(e)
        return 2 
    try:
        f = open(sys.argv[2])
    except:
        print "Open file %s failed." % sys.argv[2]
        return 3

    if ROOT == "/SO":
        DB_PATH = "/SO_db/ccg_cns_db"
    else:
        DB_PATH = "/root/Calidus.tmp/ccg_cns_db"
    
    db = CnsDB(DB_PATH)

    for line in f:
        presid = line.strip().upper()
        if len(presid) < 1:
            continue
        try:
            check(presid)
        except Exception, e:
            print "Incorrect record: %s" % str(e)
            continue
        else:
            owners = get_owner(db, presid)
            if uuid not in owners:
                owners.add(uuid)
                insert(db, presid, owners)
                print "Insert record %s on %s to ccg cns db." % (presid, uuid)
            else:
                print "Record %s on %s is already in the db." % (presid, uuid)

    del db
    f.close()
    return 0

if __name__ == "__main__":
    ret = main()
    if ret == 0:
        print "Done!"
    else:
        print "Failed!"
