#!/usr/bin/env python3
"""The MEDEVAC card of the report deck as the NATO 9-line (user, 2026-10-30: "there is a medevac, it is just not
9 lines, in the templates for messages").

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_medevac_9line.py                dry run: the card as it is and as it would be
    python tools/pac_medevac_9line.py --apply        write, the document saved first
    python tools/pac_medevac_9line.py --id casevac   name the card when the guess is wrong

The deck is the JMSB.templates document (items: id -> {title, short, lines, options}, the shape
jmfsb_messaging_fnc_registerTemplate takes; DIVINER wiki, config_messaging). The card is found by id - medevac,
then casevac - or by EVAC in its title; its lines are replaced with the nine lines plus REMARKS, its title and short
are set, its anchor is Line 1 and its subject names the pick-up grid. Every other option (priority, replies, routing)
is left as it is. Line names are field keys (Line1.A ...), so the reader's and the anchor's keys stay Line1.A.
Backups: D:/Git/_jmsb_db_backup_<date>/JMSB.templates_before_medevac_9line.json.
"""
import argparse
import datetime
import json
import os
import sys

from pymongo import MongoClient

DB = "jmsb"
DOC = "JMSB.templates"
IDS = ["medevac", "casevac"]
TITLE = "9-LINE MEDEVAC"
SHORT = "MEDEVAC"
ANCHOR = "Line1.A"
SUBJECT = "MEDEVAC - {Line1.A}"


def count(prefix, hint):
    return [prefix, hint, "number", [["min", 0]]]


def choice(choices, required=True):
    opts = [["required", True]] if required else []
    return ["", "", "choice", opts + [["choices", choices]]]


LINES = [
    ["Line 1", "LINE 1 - PICK-UP SITE LOCATION", [
        ["", "Grid of the pick-up site", "grid", [["required", True], ["source", "mapClick"]]]]],
    ["Line 2", "LINE 2 - RADIO FREQUENCY, CALL SIGN AND SUFFIX", [
        ["", "Net and call sign at the pick-up site", "text", [["required", True], ["autoFill", "ownCallsign"]]]]],
    ["Line 3", "LINE 3 - PATIENTS BY PRECEDENCE", [
        count("A URGENT", "Within 1 hour"),
        count("B URGENT-SURGICAL", "Within 1 hour, needs surgery"),
        count("C PRIORITY", "Within 4 hours"),
        count("D ROUTINE", "Within 24 hours"),
        count("E CONVENIENCE", "Not time critical")]],
    ["Line 4", "LINE 4 - SPECIAL EQUIPMENT REQUIRED", [
        choice(["A NONE", "B HOIST", "C EXTRACTION EQUIPMENT", "D VENTILATOR"])]],
    ["Line 5", "LINE 5 - PATIENTS BY TYPE", [
        count("L LITTER", "Carried"),
        count("A AMBULATORY", "Walking")]],
    ["Line 6", "LINE 6 - SECURITY AT PICK-UP SITE", [
        choice(["N NO ENEMY TROOPS IN AREA", "P POSSIBLE ENEMY - APPROACH WITH CAUTION",
                "E ENEMY IN AREA - APPROACH WITH CAUTION", "X ENEMY IN AREA - ARMED ESCORT REQUIRED"])]],
    ["Line 7", "LINE 7 - METHOD OF MARKING PICK-UP SITE", [
        choice(["A PANELS", "B PYROTECHNIC SIGNAL", "C SMOKE SIGNAL", "D NONE", "E OTHER"]),
        ["", "Colour or detail", "text", []]]],
    ["Line 8", "LINE 8 - PATIENT NATIONALITY AND STATUS", [
        choice(["A US MILITARY", "B US CIVILIAN", "C NON-US MILITARY", "D NON-US CIVILIAN", "E EPW"])]],
    ["Line 9", "LINE 9 - NBC CONTAMINATION / TERRAIN", [
        choice(["NONE", "N NUCLEAR", "B BIOLOGICAL", "C CHEMICAL"], required=False),
        ["", "Terrain and obstacles at the site", "text", []]]],
    ["Remarks", "REMARKS", [
        ["", "MIST, anything the crew must know", "text", []]]],
]


def find_card(items, wanted):
    if wanted:
        return wanted if wanted in items else None
    for tid in IDS:
        if tid in items:
            return tid
    hits = [tid for tid, t in items.items() if "EVAC" in str(t.get("title", "")).upper()]
    return hits[0] if len(hits) == 1 else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--id", default="", help="the card's id when the guess is wrong")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    db = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB]

    found = [(db[n], d) for n in db.list_collection_names() for d in db[n].find({"_id": DOC})]
    if len(found) != 1:
        sys.exit("expected one %s document, found %d (a deck that lives in the mission config has none)" % (DOC, len(found)))
    coll, doc = found[0]
    items = doc.get("items", {})
    tid = find_card(items, a.id)
    if tid is None:
        sys.exit("no MEDEVAC card found among %s - name it with --id" % ", ".join(sorted(items)))
    card = items[tid]

    options = [o for o in card.get("options", []) if isinstance(o, list) and o and o[0] not in ("anchor", "subject")]
    options += [["anchor", ANCHOR], ["subject", SUBJECT]]
    then = {"id": tid, "title": TITLE, "short": SHORT, "lines": LINES, "options": options}

    print("card: %s" % tid)
    print("now:  %s" % json.dumps(card, indent=1))
    print("then: %s" % json.dumps(then, indent=1))
    if card == then:
        print("already the 9-line, nothing to do")
        return
    if not a.apply:
        print("dry run - add --apply to write")
        return

    backup_dir = "D:/Git/_jmsb_db_backup_%s" % datetime.date.today().isoformat()
    os.makedirs(backup_dir, exist_ok=True)
    with open(os.path.join(backup_dir, "%s_before_medevac_9line.json" % DOC), "w", encoding="utf-8") as f:
        json.dump(doc, f, indent=1, default=str)
    coll.update_one({"_id": DOC}, {"$set": {"items.%s" % tid: then}})
    print("written; backup in %s" % backup_dir)


if __name__ == "__main__":
    main()
