#!/usr/bin/env python3
"""Put classes into every COMMON TAC//PAC arsenal (the JMSB.arsenal* documents that are not a qualification's
JMSB.arsenal.qual_*), into one list - the counterpart of tools/pac_remove_items.py.

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_add_items.py <list> <classes.json>            dry run: what would be added, and where
    python tools/pac_add_items.py <list> <classes.json> --apply    write, each document saved first

<list> is the arsenal list key - magazines, weapons, backpacks, itemsTools, itemsOptics, ...; <classes.json> a JSON
array of class names. Classes already in the list are left where they are; new ones are appended in the file's order.
First use (user, 2026-10-21): the SPS PMAG 40 / Surefire 60 and Aegis 60Rnd 7N44 magazines into every common arsenal.
Backups: D:/Git/_jmsb_db_backup_<date>/<id>_before_add_<list>.json.
"""
import argparse
import datetime
import json
import os
import sys

from pymongo import MongoClient

DB = "jmsb"
QUAL_PREFIX = "JMSB.arsenal.qual_"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("list", help="arsenal list key, e.g. magazines")
    ap.add_argument("classes", help="JSON file with an array of class names")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    wanted = json.load(open(a.classes, encoding="utf-8"))
    if not isinstance(wanted, list) or not all(isinstance(x, str) for x in wanted):
        sys.exit("%s is not a JSON array of class names" % a.classes)
    db = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB]

    changes = []
    for name in db.list_collection_names():
        coll = db[name]
        for doc in coll.find({"_id": {"$regex": r"^JMSB\.arsenal"}}):
            if doc["_id"].startswith(QUAL_PREFIX):
                continue
            have = doc.get("lists", {}).get(a.list, [])
            if not isinstance(have, list):
                print("%-28s lists.%s is not a list - skipped" % (doc["_id"], a.list))
                continue
            new = [x for x in dict.fromkeys(wanted) if x not in have]
            print("%-28s lists.%-12s +%d (had %d)" % (doc["_id"], a.list, len(new), len(have)))
            if new:
                changes.append((coll, doc, have + new))

    print("\n%d document(s) to change" % len(changes))
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return
    backup = r"D:\Git\_jmsb_db_backup_%s" % datetime.date.today().isoformat()
    os.makedirs(backup, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for coll, doc, items in changes:
        with open(os.path.join(backup, "%s_before_add_%s.json" % (doc["_id"], a.list)), "w", encoding="utf-8") as f:
            json.dump(doc, f, default=str, indent=1)
        coll.update_one({"_id": doc["_id"]}, {"$set": {"lists." + a.list: items, "updatedAt": stamp, "from": "tools/pac_add_items.py"}})
    print("written; the documents as they were are in %s" % backup)


if __name__ == "__main__":
    main()
