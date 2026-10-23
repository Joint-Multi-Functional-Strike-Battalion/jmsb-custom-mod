#!/usr/bin/env python3
"""The common arsenals' backpack lists, as asked on 2026-10-19: base-game and DLC bags out, the vanilla MTP
bags that ax_vanillaocp re-skins to OCP kept, the mod's own radio bags in.

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_backpacks_ocp.py            dry run: what would change
    python tools/pac_backpacks_ocp.py --apply    write, each document saved first

Touches JMSB.arsenal and JMSB.arsenal.testing only (the two common versions). Three base-game bags with no
replacement in the mod are deliberately LEFT IN - the two UAV bags and the steerable parachute - and are
listed in KEEP_FUNCTIONAL; delete them from that list to drop them too.
Backups: D:/Git/_jmsb_db_backup_<date>/<id>_before_backpacks.json.
"""
import argparse
import datetime
import json
import os
import sys

from pymongo import MongoClient

DB = "jmsb"
DOCS = ["JMSB.arsenal", "JMSB.arsenal.testing"]
KEEP_FUNCTIONAL = ["B_UAV_01_backpack_F", "B_UAV_06_backpack_F", "B_Parachute"]
REMOVE = [
    "B_AA_01_Weapon_grn_F",
    "B_AT_01_Weapon_grn_F",
    "B_AssaultPackSpec_mcamo",
    "B_AssaultPack_Enh_tna_F",
    "B_AssaultPack_blk",
    "B_AssaultPack_cbr",
    "B_AssaultPack_khk",
    "B_AssaultPack_rgr",
    "B_AssaultPack_sgg",
    "B_AssaultPack_tna_F",
    "B_Bergen_blk_F",
    "B_Bergen_rgr_F",
    "B_Bergen_tna_F",
    "B_Carryall_cbr",
    "B_Carryall_khk",
    "B_Carryall_oli",
    "B_Carryall_tna_F",
    "B_DuffleBag_Black_NoLogo_RF",
    "B_DuffleBag_MTP_RF",
    "B_DuffleBag_Olive_NoLogo_RF",
    "B_DuffleBag_Sand_NoLogo_RF",
    "B_FieldPack_cbr",
    "B_FieldPack_oli",
    "B_GMG_01_A_Weapon_grn_F",
    "B_GMG_01_A_weapon_F",
    "B_GMG_01_Weapon_grn_F",
    "B_GMG_01_high_Weapon_grn_F",
    "B_GMG_01_high_weapon_F",
    "B_HMG_01_A_Weapon_grn_F",
    "B_HMG_01_A_weapon_F",
    "B_HMG_01_Weapon_grn_F",
    "B_HMG_01_high_Weapon_grn_F",
    "B_HMG_01_high_weapon_F",
    "B_HMG_01_support_grn_F",
    "B_HMG_01_support_high_F",
    "B_HMG_01_support_high_grn_F",
    "B_HMG_02_Weapon_grn_F",
    "B_HMG_02_high_Weapon_grn_F",
    "B_HMG_02_high_weapon_F",
    "B_HMG_02_support_grn_F",
    "B_HMG_02_support_high_F",
    "B_HMG_02_support_high_grn_F",
    "B_Kitbag_cbr",
    "B_Kitbag_khk",
    "B_Kitbag_rgr",
    "B_Kitbag_sgg",
    "B_Kitbag_tna_F",
    "B_Mortar_01_Weapon_grn_F",
    "B_Mortar_01_support_grn_F",
    "B_Respawn_RallyPoint_01_bag_F",
    "B_Respawn_RallyPoint_01_bag_grn_F",
    "B_T_Static_Designator_01_Weapon_F",
    "B_TacticalPack_khk",
    "B_TacticalPack_rgr",
    "B_TacticalPack_tna_F",
    "B_W_Static_Designator_01_weapon_F",
    "I_E_Static_Designator_01_weapon_F",
    "I_Static_Designator_01_weapon_F",
    "O_R_Static_Designator_02_weapon_F",
    "O_Static_Designator_02_weapon_F",
    "O_T_Static_Designator_02_weapon_F"
]
ADD = [
    "jmfsb_backpack_B_RadioBag_01_Multicam",
    "jmfsb_backpack_B_RadioBag_01_Multicam_Snow",
    "jmfsb_backpack_B_RadioBag_01_Multicam_Woodland",
    "jmfsb_backpack_B_RadioBag_01_Solid_CoyoteBrown",
    "jmfsb_backpack_B_RadioBag_01_Solid_Olive",
    "jmfsb_backpack_B_RadioBag_01_Solid_Ranger_Green",
    "jmfsb_backpack_B_RadioBag_01_Solid_Tan",
    "jmfsb_backpack_B_RadioBag_01_Solid_White",
    "jmfsb_backpack_kitbag_black_west",
    "jmfsb_backpack_kitbag_coyote_west",
    "jmfsb_backpack_kitbag_khaki_west",
    "jmfsb_backpack_kitbag_winter_west"
]
BACKUP = r"D:\Git\_jmsb_db_backup_%s" % datetime.date.today().isoformat()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    coll = MongoClient(uri, serverSelectionTimeoutMS=15000)[DB]["pac"]
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for _id in DOCS:
        doc = coll.find_one({"_id": _id})
        if doc is None:
            print("%s: not found" % _id)
            continue
        before = doc.get("lists", {}).get("backpacks", [])
        gone = [c for c in before if c in REMOVE]
        new = [c for c in ADD if c not in before]
        after = sorted(set(c for c in before if c not in REMOVE) | set(ADD))
        print("%s: %d -> %d (-%d, +%d)" % (_id, len(before), len(after), len(gone), len(new)))
        if not a.apply:
            continue
        os.makedirs(BACKUP, exist_ok=True)
        with open(os.path.join(BACKUP, "%s_before_backpacks.json" % _id), "w", encoding="utf-8") as f:
            json.dump(doc, f, default=str, indent=1)
        coll.update_one({"_id": _id}, {"$set": {"lists.backpacks": after, "updatedAt": stamp, "from": "tools/pac_backpacks_ocp.py"}})
        print("  written")
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
    else:
        print("the documents as they were are in %s" % BACKUP)


if __name__ == "__main__":
    main()
