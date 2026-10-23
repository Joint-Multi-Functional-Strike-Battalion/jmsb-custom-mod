#!/usr/bin/env python3
"""Game voice's comm plan in TAC//PAC's radio document, next to the ACRE and TFAR ones (user, 2026-10-21: "the game
voip should be a comm plan like acre and tfar"; "add c2 to all tl's and atl's and all of the hcc, a2g to all with
the jfo skill").

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_von_plan.py            dry run: the rows as they are and as they would be
    python tools/pac_von_plan.py --apply    write, the document saved first

Writes items.vonNets of JMSB.radio, rows [net, "c2" | "a2g", [squads], [role ids], [skill ids]] (jmfsb_pac_fnc_netPlanUnit):
a man is on the first row of each kind naming his squad, his role (a "<id>_t" testing copy answers to its base id) or
a skill he holds. Squads keep their own name as their TEAM net (no vonTeamNets rows). The TFAR and ACRE keys are left
alone. Edit the rows on the website afterwards (ORBAT > radio > VON).
Backups: D:/Git/_jmsb_db_backup_<date>/<id>_before_von_plan.json.
"""
import argparse
import datetime
import json
import os
import sys

from pymongo import MongoClient

DB = "jmsb"
DOC = "JMSB.radio"
HQ_SQUADS = ["OVERLORD 6"]
LEADER_ROLES = [
    "teamleadGhost", "atlGhost",
    "teamleadRaider", "atlRaider",
    "teamleadSupport", "atlSupport",
    "tcNomad", "driverNomad",
]
VON_NETS = [
    ["C2", "c2", HQ_SQUADS, LEADER_ROLES, []],
    ["A2G", "a2g", [], [], ["jfo"]],
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    db = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB]

    found = [(db[n], d) for n in db.list_collection_names() for d in db[n].find({"_id": DOC})]
    if len(found) != 1:
        sys.exit("expected one %s document, found %d" % (DOC, len(found)))
    coll, doc = found[0]
    items = doc.get("items", {})
    roles = {d["_id"].split(".", 2)[2] for d in coll.find({"_id": {"$regex": r"^JMSB\.role\."}}, {"_id": 1})}
    unknown = [r for r in LEADER_ROLES if r not in roles]
    if unknown:
        sys.exit("roles not in the database: %s" % ", ".join(unknown))

    print("now:  vonNets %s" % json.dumps(items.get("vonNets", [])))
    print("then: vonNets %s" % json.dumps(VON_NETS))
    if items.get("vonNets") == VON_NETS:
        print("already so - nothing to do")
        return
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return
    backup = r"D:\Git\_jmsb_db_backup_%s" % datetime.date.today().isoformat()
    os.makedirs(backup, exist_ok=True)
    with open(os.path.join(backup, "%s_before_von_plan.json" % DOC), "w", encoding="utf-8") as f:
        json.dump(doc, f, default=str, indent=1)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    coll.update_one({"_id": DOC}, {"$set": {"items.vonNets": VON_NETS, "updatedAt": stamp, "from": "tools/pac_von_plan.py"}})
    print("written; the document as it was is in %s" % backup)


if __name__ == "__main__":
    main()
