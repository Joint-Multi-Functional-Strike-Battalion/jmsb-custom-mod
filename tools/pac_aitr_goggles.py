#!/usr/bin/env python3
"""The AiTR goggles into the TAC//PAC database (user, 2026-10-17):

    "make jmsb versions and add to the arsenals remove all other glasses, leave the nbc masks in the arsenal"
    "then add SOF_G_TacticalGoggles_rgr to every role"
    "remove the other nvg's"

Every arsenal document (JMSB.arsenal and its qual_ add-ons):
  * itemsNvgs      - the 21 AiTR goggles (compatibility/aitr_goggles_*) on JMSB.arsenal, nothing else anywhere
  * itemsFacewear  - only the NBC masks (respirators, APRs, M50s) stay
Every role (JMSB.role.*):
  * defaultLoadout - the NVG slot is jmfsb_nvg_SOF_G_TacticalGoggles_rgr (the green tactical goggles, AiTR); a
                     facewear item that is not an NBC mask is taken off (it is no longer in the arsenal)
  * its own arsenal lists - any facewear or NVG the arsenals just dropped is dropped there too

Every document it would change is printed; nothing is written without --apply, and with --apply each one is
saved first to D:\\Git\\_jmsb_db_backup_<date>\\ as it was.

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_aitr_goggles.py              dry run
    python tools/pac_aitr_goggles.py --apply      write
"""
import argparse
import datetime
import json
import os
import re
import sys

from pymongo import MongoClient

DB = "jmsb"
GOGGLES = ["jmfsb_nvg_" + c for c in [
    "SOF_G_TacticalGoggles_rgr", "SOF_G_TacticalGoggles_blk", "SOF_G_TacticalGoggles_snd",
    "SOF_G_TwillBalaclava_Goggles_blk", "SOF_G_TwillBalaclava_Goggles_khk", "SOF_G_TwillBalaclava_Goggles_oli",
    "JCA_G_Goggles_01_tinted_sand_F", "JCA_G_Goggles_01_tinted_olive_F", "JCA_G_Goggles_01_tinted_black_F",
    "JCA_G_Goggles_01_clear_black_F", "JCA_G_Goggles_01_clear_olive_F", "JCA_G_Goggles_01_clear_sand_F",
    "JCA_G_shemagh_01_goggles_black_F", "JCA_G_shemagh_01_goggles_olive_F", "JCA_G_shemagh_01_goggles_sand_F",
    "JCA_G_balaclava_01_goggles_black_F", "JCA_G_balaclava_01_goggles_olive_F", "JCA_G_balaclava_01_goggles_sand_F",
    "JCA_G_FaceMask_01_goggles_black_F", "JCA_G_FaceMask_01_goggles_olive_F", "JCA_G_FaceMask_01_goggles_sand_F",
]]
ROLE_NVG = "jmfsb_nvg_SOF_G_TacticalGoggles_rgr"
MAIN_ARSENAL = "JMSB.arsenal"
NBC = re.compile(r"(?i)respirator|purif|_apr|apr_|m50|nbc|cbrn|regulator|gasmask|gas_mask|mopp")
# getUnitLoadout: index 7 the facewear, index 9 the assigned items with the NVG last
FACEWEAR, ASSIGNED, NVG_SLOT = 7, 9, 5
BACKUP = r"D:\Git\_jmsb_db_backup_%s" % datetime.date.today().isoformat()


def collections_with(db, pattern):
    for name in db.list_collection_names():
        for doc in db[name].find({"_id": {"$regex": pattern}}):
            yield db[name], doc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write the changes (default: dry run)")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    db = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB]

    arsenals = list(collections_with(db, r"^JMSB\.arsenal"))
    roles = list(collections_with(db, r"^JMSB\.role\."))
    if not arsenals:
        sys.exit("no JMSB.arsenal documents in database %s" % DB)

    # what the arsenals drop - so the roles' own lists drop the same
    dropped = set()
    for _, doc in arsenals:
        lists = doc.get("lists", {})
        dropped |= {x for x in lists.get("itemsFacewear", []) if not NBC.search(x)}
        dropped |= {x for x in lists.get("itemsNvgs", []) if x not in GOGGLES}

    changes = []
    for coll, doc in arsenals:
        lists = doc.get("lists", {})
        new = dict(lists)
        if "itemsFacewear" in lists:
            new["itemsFacewear"] = [x for x in lists["itemsFacewear"] if NBC.search(x)]
        if "itemsNvgs" in lists or doc["_id"] == MAIN_ARSENAL:
            new["itemsNvgs"] = list(GOGGLES) if doc["_id"] == MAIN_ARSENAL else []
        for key, items in lists.items():
            if key not in ("itemsFacewear", "itemsNvgs") and isinstance(items, list):
                new[key] = [x for x in items if x not in dropped]
        if new != lists:
            kept = new.get("itemsFacewear", [])
            print("%-40s facewear %3d -> %3d (kept: %s)" % (doc["_id"], len(lists.get("itemsFacewear", [])), len(kept), ", ".join(kept) or "none"))
            print("%-40s nvgs     %3d -> %3d" % ("", len(lists.get("itemsNvgs", [])), len(new.get("itemsNvgs", []))))
            changes.append((coll, doc, {"lists": new}))

    for coll, doc in roles:
        role = doc.get("role", {})
        upd = {}
        load = role.get("defaultLoadout")
        if isinstance(load, list) and len(load) > ASSIGNED:
            load = json.loads(json.dumps(load))
            assigned = load[ASSIGNED] if isinstance(load[ASSIGNED], list) else []
            assigned = (assigned + [""] * 6)[:6]
            before = (assigned[NVG_SLOT], load[FACEWEAR])
            assigned[NVG_SLOT] = ROLE_NVG
            load[ASSIGNED] = assigned
            if isinstance(load[FACEWEAR], str) and load[FACEWEAR] and not NBC.search(load[FACEWEAR]):
                load[FACEWEAR] = ""
            if (assigned[NVG_SLOT], load[FACEWEAR]) != before:
                upd["role.defaultLoadout"] = load
                print("%-40s nvg %s -> %s, facewear %s -> %s" % (doc["_id"], before[0] or "-", ROLE_NVG, before[1] or "-", load[FACEWEAR] or "-"))
        for key in ("arsenalItems", "arsenalWhitelist", "arsenalWeapons"):
            items = role.get(key)
            if isinstance(items, list) and any(isinstance(x, str) and x in dropped for x in items):
                upd["role." + key] = [x for x in items if not (isinstance(x, str) and x in dropped)]
                print("%-40s %s: dropped %d" % (doc["_id"], key, len(items) - len(upd["role." + key])))
        if upd:
            changes.append((coll, doc, upd))

    print("\n%d document(s) to change" % len(changes))
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return

    os.makedirs(BACKUP, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for coll, doc, upd in changes:
        with open(os.path.join(BACKUP, "%s_before_aitr_goggles.json" % doc["_id"]), "w", encoding="utf-8") as f:
            json.dump(doc, f, default=str, indent=1)
        upd = dict(upd, updatedAt=stamp, **{"from": "tools/pac_aitr_goggles.py"})
        coll.update_one({"_id": doc["_id"]}, {"$set": upd})
    print("written; the documents as they were are in %s" % BACKUP)


if __name__ == "__main__":
    main()
