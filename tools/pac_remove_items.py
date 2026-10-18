#!/usr/bin/env python3
"""Take items out of every TAC//PAC arsenal and role - by class-name pattern.

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_remove_items.py "<regex>"             dry run: what would go, and from where
    python tools/pac_remove_items.py "<regex>" --apply     write, each document saved first

First use (user, 2026-10-17: "remove all convd from the arsenal"): the SPS scopes with the clip-on night vision
device - "CoNVD" in their names, _PVS24LR in their classes - and the SPS_PVS24LR itself:

    python tools/pac_remove_items.py "PVS24LR$" --apply

The pattern is matched (case-insensitive) against whole class names. It is removed from every list of every
JMSB.arsenal document, and from each role's own arsenal lists. A role whose default loadout carries one is only
REPORTED - taking a scope off a weapon or a device off a man is a loadout decision, not a list edit.
Backups: D:\\Git\\_jmsb_db_backup_<date>\\<id>_before_remove.json.
"""
import argparse
import datetime
import json
import os
import re
import sys

from pymongo import MongoClient

DB = "jmsb"
BACKUP = r"D:\Git\_jmsb_db_backup_%s" % datetime.date.today().isoformat()
ROLE_LISTS = ("arsenalWeapons", "arsenalMagazines", "arsenalItems", "arsenalBackpacks", "arsenalWhitelist")


def strings(v):
    if isinstance(v, str):
        yield v
    elif isinstance(v, list):
        for x in v:
            yield from strings(x)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pattern", help="regex on class names, e.g. \"PVS24LR$\"")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    pat = re.compile(a.pattern, re.I)
    db = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB]

    changes, removed = [], set()
    for name in db.list_collection_names():
        coll = db[name]
        for doc in coll.find({"_id": {"$regex": r"^JMSB\.arsenal"}}):
            upd = {}
            for key, items in doc.get("lists", {}).items():
                if isinstance(items, list):
                    gone = [x for x in items if isinstance(x, str) and pat.search(x)]
                    if gone:
                        upd["lists." + key] = [x for x in items if x not in gone]
                        removed |= set(gone)
                        print("%-34s lists.%-20s -%d" % (doc["_id"], key, len(gone)))
            if upd:
                changes.append((coll, doc, upd))
        for doc in coll.find({"_id": {"$regex": r"^JMSB\.role\."}}):
            role, upd = doc.get("role", {}), {}
            for key in ROLE_LISTS:
                items = role.get(key)
                if isinstance(items, list):
                    gone = [x for x in items if isinstance(x, str) and pat.search(x)]
                    if gone:
                        upd["role." + key] = [x for x in items if x not in gone]
                        removed |= set(gone)
                        print("%-34s role.%-20s -%d" % (doc["_id"], key, len(gone)))
            worn = [x for x in strings(role.get("defaultLoadout")) if pat.search(x)]
            if worn:
                print("%-34s DEFAULT LOADOUT carries %s - left alone" % (doc["_id"], ", ".join(worn)))
            if upd:
                changes.append((coll, doc, upd))

    print("\n%d class(es) out of %d document(s): %s" % (len(removed), len(changes), ", ".join(sorted(removed))))
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return
    os.makedirs(BACKUP, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for coll, doc, upd in changes:
        with open(os.path.join(BACKUP, "%s_before_remove.json" % doc["_id"]), "w", encoding="utf-8") as f:
            json.dump(doc, f, default=str, indent=1)
        coll.update_one({"_id": doc["_id"]}, {"$set": dict(upd, updatedAt=stamp, **{"from": "tools/pac_remove_items.py"})})
    print("written; the documents as they were are in %s" % BACKUP)


if __name__ == "__main__":
    main()
