#!/usr/bin/env python3
"""The phone replaces the vanilla GPS in players' SAVED loadouts too (user, 2026-10-21: "should players' saved PAC
loadouts be cleaned of the old GPS too? ... yes"). tools/pac_devices_gps.py did the arsenals and the role defaults;
this does what each player stored for himself.

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_saved_loadouts_gps.py            dry run: what would change
    python tools/pac_saved_loadouts_gps.py --apply    write, the document saved first

The store is the JMSB document: players.<uid>.loadouts is {roleKey: [stamp, getUnitLoadout]} (FUNC(loadoutStore)).
Each loadout gets the same change as a role default (pac_devices_gps.fix_loadout): GPS slot -> jmfsb_devices_phone,
ItemGPS out of the uniform, vest and backpack, a JMSB device already in the slot left alone. The stamp is kept.
Write it while no server has the store loaded - a running server saves its own copy over this one.
Backup: D:/Git/_jmsb_db_backup_<date>/JMSB_before_saved_loadouts_gps.json.
"""
import argparse
import datetime
import json
import os
import sys

from pymongo import MongoClient

from pac_devices_gps import BACKUP, DB, fix_loadout

COLLECTION = "pac"
STORE_ID = "JMSB"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    coll = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB][COLLECTION]
    doc = coll.find_one({"_id": STORE_ID})
    if doc is None:
        sys.exit("no %s document in %s.%s" % (STORE_ID, DB, COLLECTION))

    upd = {}
    for uid, rec in (doc.get("players") or {}).items():
        for key, entry in ((rec or {}).get("loadouts") or {}).items():
            if not (isinstance(entry, list) and len(entry) == 2):
                print("%s %-20s not [stamp, loadout] - left alone" % (uid, key))
                continue
            fixed, notes = fix_loadout(entry[1])
            if fixed != entry[1]:
                upd["players.%s.loadouts.%s" % (uid, key)] = [entry[0], fixed]
            if notes:
                print("%s %-20s %s" % (uid, key, "; ".join(notes)))

    print("\n%d saved loadout(s) to change" % len(upd))
    if not upd:
        return
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return
    os.makedirs(BACKUP, exist_ok=True)
    with open(os.path.join(BACKUP, "%s_before_saved_loadouts_gps.json" % STORE_ID), "w", encoding="utf-8") as f:
        json.dump(doc, f, default=str, indent=1)
    coll.update_one({"_id": STORE_ID}, {"$set": upd})
    print("written; the document as it was is in %s" % BACKUP)


if __name__ == "__main__":
    main()
