#!/usr/bin/env python3
"""The MPU5 is the default radio of every role (user, 2026-10-22: "make sure the default radio for all roles is
the MPU5").

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_default_radio.py            dry run: what would change
    python tools/pac_default_radio.py --apply    write, each document saved first

The mod never picks a radio: what a man spawns with is data, in three places that have to agree (the 2026-10-22
survey of addons/groups fnc_setupPlayer, addons/pac fnc_loadoutSend / fnc_buildArsenal and ACE's arsenal):

- Every JMSB.role.* document: the radio slot of role.defaultLoadout (getUnitLoadout index 9, slot 2) becomes
  jmfsb_mpu5, whatever it held. Radios carried in the uniform, vest or backpack (the ACRE sets for ACRE nights)
  are left alone. A role whose arsenalWhitelist is non-empty gets jmfsb_mpu5 in it, or fnc_loadoutSend would blank
  the radio out of a kept loadout.
- The common arsenals (JMSB.arsenal*, not a qualification's) get jmfsb_mpu5 in itemsTools if they lack it, or
  ACE's Default Loadouts row would blank it and the radio tab could not give it back.
- The store (the JMSB document): a player's kept loadout overrides the role default on every spawn, so an EMPTY
  radio slot in players.<uid>.loadouts.<role> is filled with jmfsb_mpu5; a radio he chose himself stays. A slot
  holding what a radio mod linked there on its own night - ACRE's ItemRadioAcreFlagged, a numbered TFAR instance
  such as jmfsb_mpu5_12 - counts as empty: nobody chose those, and they are not radios on a game-voice night.
- JMSB.radio items.tfarActiveRadio becomes jmfsb_mpu5: on a TFAR night that is the handheld the plan puts in
  hand (jmfsb_adapter_tfar fnc_activeRadio), and TFAR_pnr1000a, which it named, is one nobody will carry now.
Under ACRE the MPU5 is not an ACRE radio and ACRE links its own flag item over the slot; under TFAR the compat patch
makes it a PRC-152-class set; under game voice it is the handheld jmfsb_rf_fnc_carriedSets reads.
Write it while no server has the store loaded - a running server saves its own copy over this one.
Backups: D:/Git/_jmsb_db_backup_<date>/<id>_before_default_radio.json.
"""
import argparse
import copy
import datetime
import json
import os
import re
import sys

from pymongo import MongoClient

from pac_devices_gps import BACKUP, COMMON_TOOLS, DB, LINKED, QUAL_PREFIX

COLLECTION = "pac"
STORE_ID = "JMSB"
RADIO = "jmfsb_mpu5"
RADIO_SLOT = 2
RADIO_DOC = "JMSB.radio"
TFAR_ACTIVE = "tfarActiveRadio"
TAG = "tools/pac_default_radio.py"
# What a radio mod links into the slot on its own night, which no player chose.
BACKEND_SLOT = re.compile(r"ItemRadioAcreFlagged|(jmfsb_mpu5|jmfsb_tw950|TFAR_\w+?)_\d+")


def set_radio(loadout, only_empty):
    """The loadout with the MPU5 in the radio slot, and a note - None when nothing changes."""
    if not isinstance(loadout, list) or len(loadout) <= LINKED:
        return None, "not a getUnitLoadout array - left alone"
    linked = loadout[LINKED]
    if not (isinstance(linked, list) and len(linked) > RADIO_SLOT):
        return None, "no linked items - left alone"
    was = linked[RADIO_SLOT]
    if was == RADIO:
        return None, None
    if only_empty and was and not BACKEND_SLOT.fullmatch(str(was)):
        return None, "radio slot %r kept (chosen by the player)" % was
    out = copy.deepcopy(loadout)
    out[LINKED][RADIO_SLOT] = RADIO
    return out, "radio slot %r -> %s" % (was, RADIO)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    coll = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB][COLLECTION]

    changes = []

    for doc in coll.find({"_id": {"$regex": r"^JMSB\.role\."}}):
        role, upd, notes = doc.get("role"), {}, []
        if not isinstance(role, dict):
            continue
        fixed, note = set_radio(role.get("defaultLoadout"), only_empty=False)
        if fixed is not None:
            upd["role.defaultLoadout"] = fixed
        if note:
            notes.append(note)
        whitelist = role.get("arsenalWhitelist")
        if isinstance(whitelist, list) and whitelist and RADIO not in whitelist:
            upd["role.arsenalWhitelist"] = whitelist + [RADIO]
            notes.append("arsenalWhitelist +%s" % RADIO)
        if upd:
            changes.append((doc, upd))
        if notes:
            print("%-34s %s" % (doc["_id"], "; ".join(notes)))

    for doc in coll.find({"_id": {"$regex": r"^JMSB\.arsenal"}}):
        if doc["_id"].startswith(QUAL_PREFIX):
            continue
        tools = (doc.get("lists") or {}).get(COMMON_TOOLS)
        if isinstance(tools, list) and RADIO not in tools:
            changes.append((doc, {"lists." + COMMON_TOOLS: tools + [RADIO]}))
            print("%-34s lists.%s +%s" % (doc["_id"], COMMON_TOOLS, RADIO))

    radio = coll.find_one({"_id": RADIO_DOC})
    if radio is not None and (radio.get("items") or {}).get(TFAR_ACTIVE) != RADIO:
        changes.append((radio, {"items." + TFAR_ACTIVE: RADIO}))
        print("%-34s items.%s %r -> %s" % (RADIO_DOC, TFAR_ACTIVE, (radio.get("items") or {}).get(TFAR_ACTIVE), RADIO))

    store = coll.find_one({"_id": STORE_ID})
    if store is not None:
        upd = {}
        for uid, rec in (store.get("players") or {}).items():
            if not isinstance(rec, dict):
                continue
            for key, entry in (rec.get("loadouts") or {}).items():
                if not (isinstance(entry, list) and len(entry) == 2):
                    continue
                fixed, note = set_radio(entry[1], only_empty=True)
                if fixed is not None:
                    upd["players.%s.loadouts.%s" % (uid, key)] = [entry[0], fixed]
                if note:
                    print("%s %-20s %s" % (uid, key, note))
        if upd:
            changes.append((store, upd))

    print("\n%d document(s) to change" % len(changes))
    if not changes:
        return
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return
    os.makedirs(BACKUP, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for doc, upd in changes:
        with open(os.path.join(BACKUP, "%s_before_default_radio.json" % doc["_id"]), "w", encoding="utf-8") as f:
            json.dump(doc, f, default=str, indent=1)
        if doc["_id"] == STORE_ID:
            coll.update_one({"_id": doc["_id"]}, {"$set": upd})
        else:
            coll.update_one({"_id": doc["_id"]}, {"$set": dict(upd, updatedAt=stamp, **{"from": TAG})})
    print("written; the documents as they were are in %s" % BACKUP)


if __name__ == "__main__":
    main()
