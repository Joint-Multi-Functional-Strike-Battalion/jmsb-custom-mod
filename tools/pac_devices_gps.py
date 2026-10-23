#!/usr/bin/env python3
"""The phone replaces the vanilla GPS in TAC//PAC's data (user, 2026-10-21: "remove the gps from all load outs and
the arsenals, side devices and phones should act as a gps, add the phone to all role load outs", then "the
arsenal changes need to be done in mongo").

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_devices_gps.py            dry run: what would change
    python tools/pac_devices_gps.py --apply    write, each document saved first

- Every JMSB.arsenal* document: ItemGPS out of every list. The common arsenals (the ones with an itemsTools list
  that are not a qualification's: JMSB.arsenal, JMSB.arsenal.testing, ...) get the phone and both side devices in
  itemsTools if they lack them.
- Every JMSB.role.* document: ItemGPS out of the role's own arsenal lists; in its default loadout the GPS slot
  (getUnitLoadout index 9, slot 1) becomes jmfsb_devices_phone - replacing ItemGPS or filling an empty slot - and any
  ItemGPS carried in the uniform, vest or backpack is taken out. A slot already holding a JMSB device is left alone.
The devices inherit ItemGPS in config, so the engine treats them as the GPS.
Backups: D:/Git/_jmsb_db_backup_<date>/<id>_before_devices_gps.json.
"""
import argparse
import copy
import datetime
import json
import os
import sys

from pymongo import MongoClient

DB = "jmsb"
BACKUP = r"D:\Git\_jmsb_db_backup_%s" % datetime.date.today().isoformat()
GPS = "ItemGPS"
PHONE = "jmfsb_devices_phone"
DEVICES = [PHONE, "jmfsb_devices_side", "jmfsb_devices_side2"]
COMMON_TOOLS = "itemsTools"
QUAL_PREFIX = "JMSB.arsenal.qual_"
ROLE_LISTS = ("arsenalWeapons", "arsenalMagazines", "arsenalItems", "arsenalBackpacks", "arsenalWhitelist")
# getUnitLoadout: 3 uniform, 4 vest, 5 backpack - each [class, [[item, count, ...], ...]]; 9 the linked items,
# [map, gps, radio, compass, watch, nvg].
CONTAINERS = (3, 4, 5)
LINKED, GPS_SLOT = 9, 1


def fix_loadout(loadout):
    """The loadout with the phone in the GPS slot and no ItemGPS in the containers; notes on what changed."""
    out, notes = copy.deepcopy(loadout), []
    if not isinstance(out, list) or len(out) <= LINKED:
        return out, ["loadout is not a getUnitLoadout array - left alone"]
    linked = out[LINKED]
    if isinstance(linked, list) and len(linked) > GPS_SLOT:
        slot = linked[GPS_SLOT]
        if slot not in DEVICES:
            linked[GPS_SLOT] = PHONE
            notes.append("GPS slot %r -> %s" % (slot, PHONE))
    for i in CONTAINERS:
        box = out[i] if len(out) > i else []
        if isinstance(box, list) and len(box) == 2 and isinstance(box[1], list):
            kept = [x for x in box[1] if not (isinstance(x, list) and x and x[0] == GPS)]
            if len(kept) != len(box[1]):
                box[1] = kept
                notes.append("ItemGPS out of %s" % box[0])
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
            lists = doc.get("lists", {})
            for key, items in lists.items():
                if isinstance(items, list) and GPS in items:
                    upd["lists." + key] = [x for x in items if x != GPS]
                    notes.append("lists.%s -ItemGPS" % key)
            if COMMON_TOOLS in lists and not doc["_id"].startswith(QUAL_PREFIX):
                tools = upd.get("lists." + COMMON_TOOLS, list(lists[COMMON_TOOLS]))
                missing = [d for d in DEVICES if d not in tools]
                if missing:
                    upd["lists." + COMMON_TOOLS] = tools + missing
                    notes.append("lists.%s +%s" % (COMMON_TOOLS, ", ".join(missing)))
            if upd:
                changes.append((coll, doc, upd))
                print("%-34s %s" % (doc["_id"], "; ".join(notes)))
        for doc in coll.find({"_id": {"$regex": r"^JMSB\.role\."}}):
            role, upd, notes = doc.get("role", {}), {}, []
            for key in ROLE_LISTS:
                items = role.get(key)
                if isinstance(items, list) and GPS in items:
                    upd["role." + key] = [x for x in items if x != GPS]
                    notes.append("role.%s -ItemGPS" % key)
            if "defaultLoadout" in role:
                fixed, lnotes = fix_loadout(role["defaultLoadout"])
                if fixed != role["defaultLoadout"]:
                    upd["role.defaultLoadout"] = fixed
                notes += lnotes
            if upd:
                changes.append((coll, doc, upd))
            if notes:
                print("%-34s %s" % (doc["_id"], "; ".join(notes)))

    print("\n%d document(s) to change" % len(changes))
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return
    os.makedirs(BACKUP, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for coll, doc, upd in changes:
        with open(os.path.join(BACKUP, "%s_before_devices_gps.json" % doc["_id"]), "w", encoding="utf-8") as f:
            json.dump(doc, f, default=str, indent=1)
        coll.update_one({"_id": doc["_id"]}, {"$set": dict(upd, updatedAt=stamp, **{"from": "tools/pac_devices_gps.py"})})
    print("written; the documents as they were are in %s" % BACKUP)


if __name__ == "__main__":
    main()
