#!/usr/bin/env python3
"""No man packs (user, 2026-10-21: "no manpacks"): the long-range sets carried on the back, and the radio bags that
were them, out of TAC//PAC's arsenals and role loadouts.

RUN ONLY FOR A UNIT ON GAME VOICE WITH NO TFAR OR ACRE: the user then ruled "for game voip no manpacks, tfar and
acre yes they can have them" - it was run once on 2026-10-21 and reversed from its backups the same day.

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_no_manpacks.py            dry run: what would go, and from where
    python tools/pac_no_manpacks.py --apply    write, each document saved first

Out of every JMSB.arsenal* list and each role's own arsenal lists: the MPU5 manpack, ACRE's PRC-117F and PRC-77,
TFAR's long-range backpacks, and every radio bag (vanilla's and ours - with no radio in them any more they would be
packs that look like radios). Out of each role's default loadout: those classes carried in the uniform, vest or
backpack. A role WEARING one as its backpack is reported, not changed - which bag replaces it is a loadout decision.
Backups: D:/Git/_jmsb_db_backup_<date>/<id>_before_no_manpacks.json.
"""
import argparse
import copy
import datetime
import json
import os
import re
import sys

from pymongo import MongoClient

DB = "jmsb"
MANPACK = re.compile(r"mpu5_lr$|^ACRE_PRC117F$|^ACRE_PRC77$|^TFAR_(rt1523g|mr3000|mr6000l|bussole|anprc155|anarc164|anarc210)|RadioBag", re.I)
ROLE_LISTS = ("arsenalWeapons", "arsenalMagazines", "arsenalItems", "arsenalBackpacks", "arsenalWhitelist")
CONTAINERS, BACKPACK = (3, 4, 5), 5


def fix_loadout(loadout):
    out, notes = copy.deepcopy(loadout), []
    if not isinstance(out, list):
        return out, notes
    for i in CONTAINERS:
        box = out[i] if len(out) > i else []
        if isinstance(box, list) and len(box) == 2:
            if i == BACKPACK and isinstance(box[0], str) and MANPACK.search(box[0]):
                notes.append("WEARS %s as its backpack - left for a decision" % box[0])
            if isinstance(box[1], list):
                kept = [x for x in box[1] if not (isinstance(x, list) and x and isinstance(x[0], str) and MANPACK.search(x[0]))]
                if len(kept) != len(box[1]):
                    gone = sorted({x[0] for x in box[1] if x not in kept})
                    box[1] = kept
                    notes.append("%s out of %s" % (", ".join(gone), box[0]))
    return out, notes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    db = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB]

    changes = []
    for name in db.list_collection_names():
        coll = db[name]
        for doc in coll.find({"_id": {"$regex": r"^JMSB\.arsenal"}}):
            upd, notes = {}, []
            for key, items in doc.get("lists", {}).items():
                if isinstance(items, list):
                    gone = [x for x in items if isinstance(x, str) and MANPACK.search(x)]
                    if gone:
                        upd["lists." + key] = [x for x in items if x not in gone]
                        notes.append("lists.%s -%s" % (key, ", ".join(gone)))
            if upd:
                changes.append((coll, doc, upd))
                print("%-30s %s" % (doc["_id"], "; ".join(notes)))
        for doc in coll.find({"_id": {"$regex": r"^JMSB\.role\."}}):
            role, upd, notes = doc.get("role", {}), {}, []
            for key in ROLE_LISTS:
                items = role.get(key)
                if isinstance(items, list):
                    gone = [x for x in items if isinstance(x, str) and MANPACK.search(x)]
                    if gone:
                        upd["role." + key] = [x for x in items if x not in gone]
                        notes.append("role.%s -%s" % (key, ", ".join(gone)))
            if "defaultLoadout" in role:
                fixed, lnotes = fix_loadout(role["defaultLoadout"])
                if fixed != role["defaultLoadout"]:
                    upd["role.defaultLoadout"] = fixed
                notes += lnotes
            if upd:
                changes.append((coll, doc, upd))
            if notes:
                print("%-30s %s" % (doc["_id"], "; ".join(notes)))

    print("\n%d document(s) to change" % len(changes))
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return
    backup = r"D:\Git\_jmsb_db_backup_%s" % datetime.date.today().isoformat()
    os.makedirs(backup, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for coll, doc, upd in changes:
        with open(os.path.join(backup, "%s_before_no_manpacks.json" % doc["_id"]), "w", encoding="utf-8") as f:
            json.dump(doc, f, default=str, indent=1)
        coll.update_one({"_id": doc["_id"]}, {"$set": dict(upd, updatedAt=stamp, **{"from": "tools/pac_no_manpacks.py"})})
    print("written; the documents as they were are in %s" % backup)


if __name__ == "__main__":
    main()
