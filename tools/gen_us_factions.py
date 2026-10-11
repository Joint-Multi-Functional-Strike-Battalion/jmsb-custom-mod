"""Build the faction addons as NEW classes beside the originals.

NEW CLASSES, NOT OVERRIDES - the faction_jmsb pattern. BLU_F and the rest are
left exactly as their mods ship them; this declares `jmfsb_US` and friends
alongside, each fielding its own `jmfsb_US_*` units built by inheritance from
the original. Nothing anybody else depends on changes, and a load order without
the source mod gets inert classes rather than a config that refuses to build.

    addon                new faction      from
    (the base-game US rows - faction_us, _tna, _wdl, _des - were replaced by the
    JTF on 2026-08-27 and their addons deleted)
    faction_marine_des   jmfsb_Marine_des EF_B_MJTF_Des
    faction_marine_wdl   jmfsb_Marine_wdl EF_B_MJTF_Wdl
    faction_csat         jmfsb_CSAT       OPF_F
    faction_csat_tna     jmfsb_CSAT_tna   OPF_T_F
    faction_insurgents   jmfsb_Insurgents OPF_IND_I_F
    faction_syndikat     jmfsb_Syndikat   IND_C_F
    faction_aaf          jmfsb_AAF        IND_F
    faction_ldf          jmfsb_LDF        IND_E_F
    faction_fia          jmfsb_FIA        BLU_G_F
    faction_fia_ind      jmfsb_FIA_ind    IND_G_F

MODS THAT LEFT THE LOAD ORDER ARE FILTERED OUT - see DROP_MODS. The dump is
taken with everything loaded, so a source faction's roster holds whatever
each mod bolted onto it; a class from a dropped mod is not built, not put in
a group, and not named as a crew. faction_himf, built from Atlas_BLU_H_F,
had nothing left once Atlas went and is now built by tools/gen_himf.py from
base-game parents instead.

THE ROSTER IS SCOPE 2 PLUS WHATEVER THE GROUPS FIELD. B_soldier_AR_F is scope 1
- unplaceable in the editor - but BLU_F's squads are built out of it, so a
scope-2-only roster leaves half of every squad pointing at classes this faction
does not own. Any class a group names gets built too, at its original scope.

Source data is the in-game dump in the RPT: run tools/dump_orbat.sqf in the
debug console, then this. See tools/gen_orbat_from_rpt.py, whose reader this
shares. While no dump is on disk, tools/strip_faction_mods.py (removals) and
tools/apply_faction_extras.py (additions) apply the same rules to what was
last generated.

    python tools/gen_us_factions.py --rpt <file>
"""
import os, io, re, sys, argparse, collections

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_orbat_from_rpt as R

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDONS = os.path.join(ROOT, "addons")

# THE PLA MOD'S VEHICLES, FROM ITS CONFIGS. The dump on hand was taken without
# the mod loaded; tools/gen_pla_index.py reads D:\work\pla instead and the
# records are merged into the dump's tables at read time (see main), so
# ROSTER_ADD, crews, camo and CfgPatches treat them like anything dumped.
PLA_INDEX_PATH = os.path.join(ROOT, "work", "pla_vehicles.json")


def load_pla_index():
    if not os.path.exists(PLA_INDEX_PATH):
        return {}
    import json as _json
    return _json.load(io.open(PLA_INDEX_PATH, encoding="utf-8"))


PLA_INDEX = load_pla_index()
PLA_CLASSES = set(k.lower() for k in PLA_INDEX)

# QAV'S VEHICLES, FROM ITS CONFIGS - the same trick as PLA_INDEX, for the same
# reason. A dump is a snapshot and QAV's MV-35 Phantom shipped after the one on
# hand was taken (QAV_MV35*.pbo are dated 2026-09-01, the dump 2026-08-30), so
# the airframe is read out of D:\work\qav by tools/gen_qav_index.py instead
# and merged into the dump's tables at read time.
#
# ONLY WHAT THE DUMP LACKS. The merge below keeps the dump's record wherever it
# has one, so of the 39 classes indexed exactly the 8 VTOL_03s are new; the 31
# Marshalls, AbramsXs and Ripsaws were dumped on 30 August and stay as dumped.
# Re-dump the ORBAT and the gap closes on its own - nothing here needs removing.
QAV_INDEX_PATH = os.path.join(ROOT, "work", "qav_vehicles.json")


def load_qav_index():
    if not os.path.exists(QAV_INDEX_PATH):
        return {}
    import json as _json
    return _json.load(io.open(QAV_INDEX_PATH, encoding="utf-8"))


QAV_INDEX = load_qav_index()
PLA_FACTIONS = ("jmfsb_PLA_ard", "jmfsb_PLA_wdl")

# THE PLA'S PACKS. tools/gen_pla_kit.py re-declares every loaded pack OPF_F's
# men carry as a child of itself in the Xingkong skin (contents and all) and
# lists them in work/pla_packs.json; the man is pointed at the child. A pack
# not in the list (drone bags, weapon bags, parachutes) stays as issued.
# 2040 IRAN'S PACKS ARE TAN (user, 2026-08-30: "find them some just tan or
# sand covered backpacks"). CSAT issues the same rucksack in several skins;
# every one of them becomes the coyote-brown build of the SAME pack, so a man
# keeps the pack he was given and only its colour changes.
_IRAN_PACKS = {}
for _kind in ("B_AssaultPack", "B_Carryall", "B_Kitbag", "B_FieldPack", "B_TacticalPack"):
    for _skin in ("_ocamo", "_oucamo", "_oli", "_khk", "_rgr", "_blk", "_mcamo", "_ghex_F"):
        _IRAN_PACKS[_kind + _skin] = _kind + "_cbr"


def load_pack_swap():
    p = os.path.join(ROOT, "work", "pla_packs.json")
    if not os.path.exists(p):
        return {"jmfsb_Iran": dict(_IRAN_PACKS)}
    import json as _json
    packs = _json.load(io.open(p, encoding="utf-8"))
    return {"jmfsb_PLA_ard": dict((o, v["A"]) for o, v in packs.items() if "A" in v),
            "jmfsb_PLA_wdl": dict((o, v["W"]) for o, v in packs.items() if "W" in v),
            "jmfsb_Iran": dict(_IRAN_PACKS)}


PACK_SWAP = load_pack_swap()

# addon dir, COMPONENT_BEAUTIFIED, new faction class, 3DEN name, source faction
#
# ONLY THE US, HIMF, SYNDIKAT (AND THE MARINES / 1st JMSB) REMAIN (user, 2026-08-29,
# late: "all 2040 factions except the US need to be backed up and removed",
# then "do not remove himf", "keep faction_syndikat"). The other nine (the Gendarmerie came back 2026-08-30) -
# both CSATs, Insurgents, AAF, LDF, both FIAs, both PLAs - are
# COMMENTED OUT below, not deleted, and their addons live in
# backup/factions_removed_2026-08-29/. Uncomment a line and re-run to bring
# one back; the mission's OPFOR wiring (mission.sqm ALiVE modules) was
# re-pointed from jmfsb_PLA_wdl to the base game's OPF_F the same night.
TARGETS = [
    # THE US ARMY ON THE BASE GAME'S OWN ROSTERS (user, 2026-08-29: E22 left
    # the load order; "everything that was dependent on any E22 mod needs to
    # look to Aegis or these mods"). The four theatres keep their addon, faction
    # and display names - the mission's motor pool names jmfsb_US_JTF_tna - but
    # their SOURCES are BLU_W_F (woodland), Western Sahara's BLU_NATO_lxWS
    # (desert, and the OCP theatre through KIT_SWAP) and BLU_T_F (tropical).
    # Aegis extends those very rosters in the load order, so a dump taken with
    # the new preset brings its additions in through the same door.
    ("faction_us_jtf_wdl", "US Army JTF (Woodland)", "jmfsb_US_JTF_wdl", "2040 US Army JTF (Woodland)", "blu_w_f"),
    ("faction_us_jtf_des", "US Army JTF (Desert)",   "jmfsb_US_JTF_des", "2040 US Army JTF (Desert)",   "blu_nato_lxws"),
    ("faction_us_jtf_tna", "US Army JTF (Tropical)", "jmfsb_US_JTF_tna", "2040 US Army JTF (Tropical)", "blu_t_f"),
    ("faction_us_jtf_ocp", "US Army JTF (OCP)",      "jmfsb_US_JTF_ocp", "2040 US Army JTF (OCP)",      "blu_nato_lxws"),
    # 2040 GENDARMERIE (user, 2026-08-29): the base game's BLU_GEN_F, whole.
    # It is the one source faction that declares NO groups at all, so all four
    # of its groups are ours - see EXTRA_GROUPS - and its men are kitted by
    # hand rather than swapped, see FORCE_LOADOUT.
    ("faction_gen", "Gendarmerie", "jmfsb_GEN", "2040 Gendarmerie", "blu_gen_f"),   # restored 2026-08-30
    # THE EUDF, REBUILT (user, 2026-08-31: "lets [make] some eu factions from
    # BLU_F, CF_BLU_F, BLU_NATO_lxWS, BLU_T_F, BLU_W_F"). One theatre per
    # source. No Marshall and no Badger anywhere in them - see NOT_FIELDED -
    # the armour is the Nyx and the Luchs, and the air arm is European.
    # Three EU factions (user, 2026-09-19: "green and arid are all wee are doing", "and artic for russia and the
    # eu"): the woodland is the fullest roster (blu_f), the arid and the arctic beside it. The blu_w_f and blu_t_f
    # mirrors were deleted that day.
    ("faction_eudf",     "EUDF (Woodland)",  "jmfsb_EUDF",     "2040 EUDF (Woodland)",  "blu_f"),
    ("faction_eudf_des", "EUDF (Arid)",      "jmfsb_EUDF_des", "2040 EUDF (Arid)",      "blu_nato_lxws"),
    ("faction_eudf_arc", "EUDF (Arctic)",    "jmfsb_EUDF_arc", "2040 EUDF (Arctic)",    "cf_blu_f"),
    # 2040 TURKEY (user, 2026-08-31), on Athena's Pacific OPFOR. The source
    # ships 73 units and NO groups at all, so the order of battle is the base
    # game's Pacific CSAT - see GROUP_TEMPLATE - resolved into Athena's men.
    # TURKEY IS BUILT TWICE (user, 2026-09-01: "should be an east and ind
    # factions not west"). One roster, one set of rules, two sides - so the
    # same army can be the enemy in one mission and a third party in the next.
    # The side each one takes is in FACTION_SIDE; everything else about the
    # independent twin is copied from the east one by FACTION_TWIN.
    # Turkey: both camos on both sides (user, 2026-09-21) - arid and tropical, east and independent
    ("faction_turkey", "Turkey", "jmfsb_Turkey", "2040 Turkey (Arid)", "athena_opf_t_f"),
    ("faction_turkey_tna", "Turkey", "jmfsb_Turkey_tna", "2040 Turkey (Tropical)", "athena_opf_t_f"),
    ("faction_turkey_ind", "Turkey (Independent)", "jmfsb_Turkey_ind",
     "2040 Turkey (Tropical)", "athena_opf_t_f"),
    ("faction_turkey_ind_ard", "Turkey (Independent)", "jmfsb_Turkey_ind_ard",
     "2040 Turkey (Arid)", "athena_opf_t_f"),
    ("faction_marine_des", "Marine (Desert)", "jmfsb_Marine_des", "2040 Marine (Desert)", "ef_b_mjtf_des"),
    ("faction_marine_wdl", "Marine (Wdl)",    "jmfsb_Marine_wdl", "2040 Marine (Woodland)", "ef_b_mjtf_wdl"),
    # NO EUDF (user, 2026-08-29: "remove faction_eudf's"). EUDF35 left the load
    # order with E22; the three addons were deleted the same day.
    # faction_himf is built by tools/gen_himf.py - base-game bodies, Atlas's
    # HIMF textures - not from a dump.
    # TWO CSATs (2026-08-27): the base game's own pair, each in the SOF
    # hex or green-hex set - see KIT_SWAP. Both peer+ (TIER).
    #     ("faction_csat",       "CSAT Iran",       "jmfsb_CSAT",       "2040 CSAT Iran",       "opf_f"),
    #     ("faction_csat_tna",   "CSAT Iran (Pacific)", "jmfsb_CSAT_tna", "2040 CSAT Iran (Pacific)", "opf_t_f"),
    # INSURGENTS ON THE BASE GAME (2026-08-27): the Opf mod that was their
    # source left the load order, so they are the FIA's independent roster
    # (IND_G_F) at tier 1 with the insurgents' own kit on top - SwitchBlade,
    # IED Pelican, the RKSL IND package (EXTRA_UNITS). Same roster as
    # faction_fia_ind, different faction, different reach.
    #     ("faction_insurgents", "Insurgents",      "jmfsb_Insurgents", "2040 Insurgents",      "ind_g_f"),
    ("faction_syndikat",   "Syndikat",        "jmfsb_Syndikat",   "2040 Syndikat",        "ind_c_f"),
    # 2040 CHINA (user, 2026-08-30). The base game's Pacific CSAT is "China" in
    # this load order and Aegis adds "China (Desert)"; both become ours, in the
    # JAM SOF green-hex and hex sets the user specified. Peer+ like every CSAT
    # (TIER), the CTAR family by unit type (RIFLE_SWAP) and the 5.8 round at
    # tier 4 (the FA map). The desert faction is the thin one - see
    # GROUP_TEMPLATE and ROSTER_TEMPLATE, which is what makes the two equal.
    # 2040 IRAN (user, 2026-08-30: "the Iranian faction class currently is
    # OPF_F"). The base game's CSAT, kitted in Aegis Gear Overhaul's Iranian
    # digital set and re-armed on the AK-103 - see KIT_SWAP and RIFLE_SWAP.
    ("faction_iran",       "Iran",              "jmfsb_Iran",      "2040 Iran",              "opf_f"),
    # 2040 Iran (Tropical): the same roster in the base game's green hex (user, 2026-09-20)
    ("faction_iran_tna",   "Iran (Tropical)",   "jmfsb_Iran_tna",  "2040 Iran (Tropical)",   "opf_f"),
    # 2040 RUSSIA (user, 2026-08-30: "copy those three factions over as is,
    # except give them drones for 2040 and future ammo"). No kit swap and no
    # rifle swap on purpose - as is means as is; what they get is the 2040
    # label, the east drone allocation and the future rounds their magazines
    # map to.
    ("faction_russia",     "Russia",            "jmfsb_Russia",    "2040 Russia",            "opf_r_f"),
    ("faction_russia_ard", "Russia (Arid)",     "jmfsb_Russia_ard", "2040 Russia (Arid)",    "opf_r_ard_f"),
    ("faction_russia_arc", "Russia (Arctic)",   "jmfsb_Russia_arc", "2040 Russia (Arctic)",  "cf_opf_r_a_f"),
    ("faction_china",      "China",             "jmfsb_China",     "2040 China",             "opf_t_f"),
    ("faction_china_ard",  "China (Desert)",    "jmfsb_China_ard", "2040 China (Desert)",    "opf_cd_f"),
    # THE INDEPENDENTS (2026-08-27): AAF and LDF near-peer at t2, the FIA
    # pair at t1 - the base game's own rosters, from the dump.
    #     ("faction_aaf",        "AAF",             "jmfsb_AAF",        "2040 AAF",             "ind_f"),
    #     ("faction_ldf",        "LDF",             "jmfsb_LDF",        "2040 LDF",             "ind_e_f"),
    #     ("faction_fia",        "FIA",             "jmfsb_FIA",        "2040 FIA",             "blu_g_f"),
    #     ("faction_fia_ind",    "FIA (Ind)",       "jmfsb_FIA_ind",    "2040 FIA (Independent)", "ind_g_f"),
    # RUSSIA IS PENDING A DUMP (2026-08-29). E22's RAF went with E22; the
    # replacement is Russia 2035 (lk_russia, "Russia 2035" on the Workshop) with
    # Aegis Russia Alternate Loadouts on top, and neither is in any dump on
    # disk. Run tools/dump_orbat.sqf with the new preset, then add:
    #   ("faction_raf_wdl", "Russia (Woodland)", "jmfsb_RAF_wdl", "2040 Russia (Woodland)", "lk_russia"),
    # and its theatres once the dump shows what lk_russia fields.
    # THE PLA (user, 2026-08-28): OPF_F's order of battle in Chinese identities and
    # ACP's Xingkong camo (addons/uniform_pla), on the PLA mod's vehicles - read
    # from its configs, not the dump (PLA_INDEX). t4, Katiba line, Type 115 on the
    # leaders and recon; CSAT's boats, statics, quads and drones stay.
    #     ("faction_pla_ard",    "PLA (Arid)",        "jmfsb_PLA_ard",  "2040 PLA (Arid)",        "opf_f"),
    #     ("faction_pla_wdl",    "PLA (Woodland)",    "jmfsb_PLA_wdl",  "2040 PLA (Woodland)",    "opf_f"),
]


# Where a mod files its CfgGroups under a name that is not its
# CfgFactionClasses name: source faction (lower) -> CfgGroups faction (lower).
GROUP_ALIAS = {
    # the base game files BLU_G_F's groups under "Guerilla"
    "blu_g_f": "guerilla",
}


# ---------------------------------------------------------------------------
# MODS THAT ARE OUT OF THE LOAD ORDER
# ---------------------------------------------------------------------------
# The RPT dump was taken with every mod loaded, so a source faction's roster
# holds whatever each mod bolted onto it: Aegis fills BLU_T_F and BLU_W_F out
# with its own Ghost Hawks, F-35s and CQ riflemen under plain B_T_/B_W_ names,
# Atlas adds the JSOC sub-roster, and neither can be told from the base game
# by its name alone. Dropping a mod from the load order means dropping every
# class that came from it.
#
# THREE TESTS, IN ORDER:
#   1. A class prefixed with a dropped mod's tag is that mod's.  Aegis_B_...
#   2. A class the base game defines is vanilla - work/vanilla_vehicles.json,
#      written by tools/gen_vanilla_vehicles.py from the unpacked A3 tree.
#   3. Anything else is some mod's. If it matches a KEEP_MODS test - a CDLC
#      or a mod still in the load order - it stays; otherwise it is taken to
#      be a dropped mod's plain-named addition and goes.
#
# THE THIRD TEST IS THE ONE THAT CAN BE WRONG, in both directions: a mod
# missing from KEEP_MODS has its classes dropped, and a KEEP test that is too
# wide keeps a dropped mod's class. So nothing is dropped in silence - every
# run prints what went - and a new mod in the load order gets a KEEP line.
# E22 (Northstar, its JTF and its RAF) left the load order on 2026-08-29;
# Aegis and Atlas came back the same day and are KEEP_MODS now.
DROP_MODS = ("E22",)


def E22_JC_AD(c):
    """E22's Joint Command air defence - the one part of it still loaded."""
    return c.startswith("e22_") and "_jc_" in c and any(
        k in c for k in ("sam_system", "aaa_system", "radar_system"))

# Dropped mods whose classes carry no prefix of their own - B_KVN_AP is a
# NATO-looking name from the KVN drone mod. (what the report calls it, test
# on the lower-cased class name). Checked before the vanilla index, so a
# test that is too wide would drop base-game classes: keep them tight.
DROP_TESTS = [
    # EUDF35 (out 2026-08-29) - its classes carry the tag inside the name
    ("EUDF35 (out 2026-08-29)",      lambda c: "eudf35" in c),
    ("KVN drones (out 2026-08-27)", lambda c: "_kvn_" in c or c.endswith("_kvn")),
    # The GX vehicle drones are US kit (see KEEP_MODS); the OPFOR and
    # Independent copies the mod ships are not anybody's.
    ("GX drones, OPFOR/IND copies",  lambda c: c.startswith(("gx_o_", "gx_i_"))),
    # Orion/Orlan (out 2026-08-27 - dropped from the load order, and with it
    # from Russia, the last faction that fielded them)
    ("Orion / Orlan (out 2026-08-27)", lambda c: c.startswith(("orion_", "orlan_"))),
    # Crocus FPV (out 2026-08-28 - the mod is no longer loaded; the 09:11 RPT
    # filled with "No entry I_Crocus_AP.*" from the Syndikat's copy)
    ("Crocus FPV (out 2026-08-28)",   lambda c: "crocus" in c),
]

# IN THE LOAD ORDER, BUT NOT FOR THE AI. The hand-launched GX drones - Raven,
# Black Hornet, Drone40 - are the players' kit (2026-08-27): a faction that
# fields them hands the AI the thing the players are meant to be special
# for. Same shape as DROP_TESTS and treated the same way by every faction;
# what differs is the reason, so it is its own list. The GX VEHICLE drones
# are a different matter - see KEEP_MODS.
GX_HAND = ("rq11b", "blackhornet", "drone40")
PLAYER_ONLY = [
    ("GX hand-launched drones (players only)",
     lambda c: c.startswith("gx_") and any(k in c for k in GX_HAND)),
]

# Still in the load order: (what the run report calls it, test on the
# lower-cased class name). Order does not matter; the first hit names it.
KEEP_MODS = [
    # THE AEGIS FAMILY, BACK IN THE LOAD ORDER (user, 2026-08-29): Aegis and
    # Atlas, Atlas - Opposing Forces, Athena, AddGis, the Aegis Gear Overhaul
    # (stc_), the Vanilla & Aegis OCP retextures, and Russia 2035 (lk_) with
    # Aegis Russia Alternate Loadouts.
    ("Aegis",                       lambda c: "aegis" in c),
    ("Atlas",                       lambda c: c.startswith("atlas_")),
    ("Atlas - Opposing Forces",     lambda c: c.startswith("opf_")),
    ("Athena",                      lambda c: "athena" in c),
    ("AddGis",                      lambda c: "addgis" in c),
    ("Aegis Gear Overhaul",         lambda c: c.startswith("stc_")),
    ("Vanilla & Aegis OCP",         lambda c: "2035_ocp" in c or c.startswith("ocp_")),
    ("Russia 2035",                 lambda c: c.startswith("lk_")),
    ("JAM SOF equipment",           lambda c: c.startswith("sof_")),
    # THE ARCTIC FACTIONS (2026-08-30). 338 classes in the load order under a
    # CF_ prefix - "US (Arctic)" (CF_BLU_F) and "Russia (Arctic)"
    # (CF_OPF_R_A_F) - and not being on this list meant every one of them was
    # classified as a dropped mod's. 2040 Russia (Arctic) was then built almost
    # entirely out of BORROWED WOODLAND MEN, its own arctic roster refused.
    ("Arctic factions (CF)",        lambda c: c.startswith("cf_")),
    # CONTACT (DLC), THE RUSSIANS. Base game, not a mod - but work/
    # vanilla_vehicles.json is built from an unpacked a3 tree that does not
    # carry them, and a base-game class the index has never heard of is
    # indistinguishable from a dropped mod's. The parent-chain fallback in
    # class_origin catches most; it cannot catch one whose parent is scope 0,
    # because the dump only logs scope > 0. Naming the prefix here is the
    # honest fix until the index is rebuilt from a complete tree: it cost
    # 2040 Russia its mechanised squads and its diver team.
    ("Contact (DLC) Russians",      lambda c: c.startswith("o_r_")),
    ("Western Sahara (CDLC)",       lambda c: "lxws" in c),
    ("Reaction Forces (CDLC)",      lambda c: c.endswith("_rf")),
    ("Expeditionary Forces (CDLC)", lambda c: c.startswith("ef_") or c.endswith("_ef")),
    # the PLA mod (Lurker1011) - its classes carry no common prefix; the index knows them
    ("PLA (LK)",                    lambda c: c in PLA_CLASSES),
    # The GX vehicle drones - Fire Scout, Themis, Honeybadger, Magura, RWS
    # Defender, Hunter-SP - are US forces kit (2026-08-27): the motorpool
    # fields them crewed, so the US faction must own them. BLUFOR copies
    # only; the O_/I_ ones are in DROP_TESTS.
    ("GX vehicle drones (US)",      lambda c: c.startswith("gx_b_") and any(
        k in c for k in ("mq8b", "themis", "honeybadger", "magura", "rws_defnder", "hunter_sp",
                         "uav_ai"))),   # the drones' own AI crew, not a man
    ("RKSL",                        lambda c: c.startswith("rksla3_")),
    ("QAV",                         lambda c: "qav" in c),
    ("ACE",                         lambda c: c.startswith("ace_")),
    ("JK",                          lambda c: c.startswith("jk_")),
    ("ALiVE",                       lambda c: c.endswith("_alive")),
    ("Rev drones",                  lambda c: "_rev_" in c),
    ("SwitchBlade loitering munition", lambda c: "switchblade" in c),
    # The Opf mod (OPF_IND_I_F, the old insurgents' source) is out of the
    # load order since the 2026-08-27 dump; the insurgents are IND_G_F now.
    ("ours",                        lambda c: c.startswith("jmfsb_")),
]

# BASE-GAME DRONES THE US DOES NOT FIELD (2026-08-27). Of the base game's
# drones only three are US and player kit: the UCAV Sentinel, the ED-1D
# Pelter and IDAP's demining Pelican. The Darter, Greyhawk, Falcon, Pelican
# (cargo and medical), Stomper and Roller are out of the US factions - the
# airframes, the bags, and through the bags the men who carried them (a UAV
# operator without his Darter is a rifleman, and the roster has those).
# Keyed by faction. Applied to any class, base game or mod, so the CDLC and
# mod copies of the same airframes go the same way where a test catches
# them; what a test does not catch is reported by the run.
#
# THE REST OF THE SIDE ALLOCATION (2026-08-27), by the same mechanism:
#   base-game SAM and radar     EAST only
#   MQ-4A Greyhawk              EAST only
#   MQ-12 Falcon                EAST too (an east version, see EXTRA_UNITS)
#   KH-3A Fenghuang             EAST
#   SwitchBlade 300/600         EAST and IND, never US
#   RKSL Aeroshark, Watchkeeper EAST (and Aeroshark IND)
#   RKSL Rapier, Shadow, Hermes IND only
#   IED Pelican                 IND / low tier (jmfsb_uas builds it)
US_FACTIONS = ("jmfsb_US_JTF_wdl", "jmfsb_US_JTF_des", "jmfsb_US_JTF_tna", "jmfsb_US_JTF_ocp")
# FIVE EUDF THEATRES, ONE PER SOURCE (user, 2026-08-31). The mod that gave
# the old three their B_EUDF35_ classes left the load order on 29 August, so
# these are built the way the JTFs are: the base game's own NATO rosters, one
# per camo, with European armour and air written over the top.
EU_FACTIONS = ("jmfsb_EUDF", "jmfsb_EUDF_wdl", "jmfsb_EUDF_des",
               "jmfsb_EUDF_tna", "jmfsb_EUDF_arc")
# "uav_01" (the Darter) LEFT THIS LIST 2026-08-28: the squad drone table gives every
# tier-3 west squad a Darter (SQUAD_DRONES), so the airframe is fielded again.
_US_NOT = ("uav_02_dynamicloadout", "uav_03", "uav_06", "ugv_01", "ugv_02_science")
# THE WEST'S DRONE RULES - the US and, since 2026-08-27, the EU (user: "same
# as the US"). EUDF35's Patriot, radar, Darter, Milvus, Pelican and Stomper go
# the way BLU_F's did.
_WEST_DRONE_RULES = [
    ("base-game drones the west does not field",
     lambda c: any(k in c for k in _US_NOT) and "antimine" not in c),
    # the Rev mod's "deployable" wrappers of the same airframes - the
    # Darter, Pelican, Roller and Bustard by another door
    ("Rev deployables of drones the west does not field",
     lambda c: c.startswith("b_rev_") and any(k in c for k in ("darter", "pelican", "roller", "bustard", "uav_ied"))),
    ("SAM and radar are east",       lambda c: "sam_system" in c or "radar_system" in c),
    ("SwitchBlade is east and ind",  lambda c: "switchblade" in c),
    ("RKSL UAVs are east and ind",   lambda c: c.startswith("rksla3_")),
]
NOT_FIELDED = {
    US_FACTIONS: _WEST_DRONE_RULES + [
        # NO PICKUPS (2026-08-27). is_ram catches the Ram 1500s by display
        # name; this catches anything else calling itself a pickup.
        ("no pickups",                   lambda c: "pickup" in c),
        # THE AH-99 BLACKFOOT IS THE EU'S (2026-08-27): B_Heli_Attack_01_* go
        # to the EUDF factions; E22 gives the JTF the AH-80 Sparrowhawk instead.
        ("the Blackfoot is the EU's",     lambda c: "heli_attack_01" in c),
        # NO STRIDERS (user, 2026-08-28): E22's M-ATVs take their group slots -
        # see _JTF_STRIDER_SUB. THE POLARIS DAGOR FOR THE MANTIS (user, same
        # day): the base game's Prowlers come in through _JTF_LSV, painted by
        # jtf_paint(); the LSV MK.II goes.
        ("no Striders",                  lambda c: "mrap_03" in c),
        ("the Polaris for the Mantis",   lambda c: "lsv_02" in c),
        # NO NEMMERA (user, 2026-08-31). The recovery vehicle goes from all
        # four theatres - they are one order of battle in four paints, so a
        # vehicle refused in the desert is refused in the other three. The
        # armour groups never lose it: GROUP_SUB already puts QAV's APC in the
        # CRV's slot (see _US_ARMOUR_SUB*), and gsub runs before the roster
        # test that would otherwise drop the group.
        ("no CRV",                       lambda c: "apc_tracked_01_crv" in c),
        # THE EF M-ATVS ARE THE ONES ALL FOUR SHARE (2026-08-31). BLU_W_F is
        # the only source with M-ATVs of its own, so the woodland theatre drew
        # Aegis's copies beside the EF ones _JTF_GREEN gives every theatre.
        ("the EF M-ATV is the JTFs'",    lambda c: c.startswith("aegis_b_w_mrap_01")),
        # An arctic XM307A rode in on a borrowed group; the theatres have their
        # own and no JTF is arctic.
        ("no arctic twins",              lambda c: c.startswith("cf_b_")),
    ],
    # THE TROPIC MARSHALLS ARE FOR THE THEATRES WITH NONE (2026-08-31).
    # _JTF_COMMON hands every theatre the tropical AMV-7 pair, which woodland
    # needs - BLU_W_F has no cannon Marshall - but the two tan theatres have
    # their own lxWS_v2 pair, so they were drawing a green Marshall beside a
    # desert one under the same name.
    ("jmfsb_US_JTF_des", "jmfsb_US_JTF_ocp"): [
        ("the tan theatres have their own Marshall",
         lambda c: c in ("b_t_apc_wheeled_01_cannon_f", "b_t_apc_wheeled_01_atgm_lxws")),
    ],
    # Woodland keeps the tropical CANNON Marshall - it is the only one it has -
    # but BLU_W_F ships the ATGM in its own paint, so that half is a double.
    ("jmfsb_US_JTF_wdl",): [
        ("woodland has its own ATGM Marshall",
         lambda c: c == "b_t_apc_wheeled_01_atgm_lxws"),
    ],
    # ONE MEDEVAC, AND IT IS OURS (2026-08-31) - the base game's medevac JMSB
    # Hawk wears one fixed livery in every theatre; EXTRA_UNITS builds the
    # replacement on the unarmed transport, in the theatre's paint.
    US_FACTIONS + EU_FACTIONS: [
        ("the medevac is built, not inherited",
         lambda c: "heli_transport_01_medevac" in c),
    ],
    EU_FACTIONS: _WEST_DRONE_RULES + [
        # NO MARSHALL AND NO BADGER (user, 2026-08-31). The AMV-7 family is
        # the US Army's; the EU drives the Nyx and the Luchs.
        ("no AMV-7 - the EU has the Nyx",  lambda c: "apc_wheeled_01" in c),
        # NO EF M-ATV SPECIAL VARIANTS (user, 2026-09-25): keep the AT, FSV
        # and LAAD versions out of every EU theatre.
        ("no EF M-ATV AT/FSV/LAAD", lambda c: any(role in c for role in ("_mrap_01_at_", "_mrap_01_fsv_", "_mrap_01_laad_"))),
        # NO MV-35 (user, 2026-09-01: "EUDF is not the fucking us no mv 35's").
        # The Phantom was never in a table for the EU - QAV files its four
        # reskins under BLU_F / BLU_T_F / BLU_W_F / BLU_NATO_lxWS, which are
        # exactly the four sources the EUDF theatres are built from, so the
        # roster scan pulled them in on its own. This is what refuses them.
        # The Army JTFs keep theirs; they are named in _JTF_VTOL_*.
        ("the MV-35 is the US Army's",     lambda c: "vtol_03" in c),
        # the Blackfoot is the EU's - it is in _EU_HELI - and so is nothing
        # else the JTFs refuse, so the JTF rules do not apply here.
    ],
    # THE M3A1 TAKES THE MERKAVAS' SLOT (user, 2026-08-31: "replace
    # jmfsb_Marine_wdl_EF_B_MBT_01_cannon_MJTF_Wdl [and]
    # jmfsb_Marine_wdl_EF_B_MBT_01_TUSK_MJTF_Wdl in the us mariens with an
    # m3a1"). EF's two Merkava Mk IVs go; QAV's AbramsX comes in through
    # ROSTER_ADD and GROUP_SUB puts it in their eight group slots. The MLRS on
    # the same hull is artillery, not a tank, and stays.
    ("jmfsb_Marine_wdl", "jmfsb_Marine_des"): [
        ("the M3A1 replaces the Merkavas",
         lambda c: c.startswith("ef_b_mbt_01_") and ("_cannon_" in c or "_tusk_" in c)),
    ],
    # NO WEST RUSSIA (user, 2026-08-28). E22 ships the RAF three times over - west,
    # east and independent - and its alpine CfgGroups name the WEST classes; 27 of
    # them leaked into 2040 Russia (Alpine). The east twins take the slots
    # (see the group loop) and the west ones are refused here.
    ("jmfsb_RAF_wdl", "jmfsb_RAF_ard", "jmfsb_RAF_alp"): [
        ("west RAF classes",             lambda c: c.startswith("e22_b_raf")),
        ("independent RAF classes",      lambda c: c.startswith("e22_i_raf")),
    ],
    ("jmfsb_CSAT", "jmfsb_CSAT_tna", "jmfsb_RAF_wdl", "jmfsb_RAF_ard", "jmfsb_RAF_alp", "jmfsb_PLA_ard", "jmfsb_PLA_wdl"): [
        ("Hermes 450 is ind",            lambda c: c.startswith("rksla3_") and "h450" in c),
    ],
    # tier 0 has no air arm (NOT_FIELDED_VCLASS), so no pilot either
    ("jmfsb_Syndikat",): [
        ("no aircraft, no pilot",        lambda c: "pilot" in c),
        # NO ARTILLERY, ONE MORTAR. The rule (user, 2026-08-28) took out the Ram
        # 1500 (MRL) and everything else that shoots indirect; on 2026-08-30 the
        # user asked for the Mk6 back by name, so that one class is excepted
        # rather than the rule loosened - a mortar tube a bandit crew can carry
        # is a different thing from a rocket battery.
        ("no artillery at tier 0",       lambda c: c != "i_g_mortar_01_f"
                                         and ("_mrl" in c or "arty" in c or "mortar" in c)),
        # NO UGVs (user, 2026-08-30). Aegis puts two Stompers on IND_C_F and
        # the Syndikat inherited them from its source; a tracked armed robot is
        # not what a tier 0 bandit network drives. Named exactly rather than by
        # a "ugv" test - the IED quad is a UAV and stays.
        # NO UGVs AND NO AA GUN (user, 2026-08-30). Aegis puts two Stompers and
        # a ZU-23 on IND_C_F and the Syndikat inherited all three from its
        # source; a tracked armed robot and a towed AA gun are not what a tier
        # 0 bandit network runs. Named exactly rather than by a "ugv" / "aa"
        # test - the IED quad is a UAV and stays, and "aa" would catch half
        # the roster by accident.
        ("no UGVs or AA gun at tier 0",  lambda c: c in ("aegis_i_c_ugv_01_f",
                                                        "aegis_i_c_ugv_01_rcws_f",
                                                        "aegis_i_c_zu23_lxws_f")),
    ],
}

# WHOLE CATEGORIES A FACTION DOES NOT FIELD, by the dump's vehicleClass.
# Tier 0 has no air arm: the Syndikat's Caesar BTT, its Mohawk and its Taru
# are bought or stolen airframes a bandit network could not keep flying, so
# the whole "Air" category goes - drones are "Autonomous" and stay.
# {faction: (vehicleClasses, unless)} - `unless` is a test on the lower-cased
# class name that keeps a class the category would have dropped.
#
# THE US ARMY HAS NO TANKS AND NO APCs EXCEPT QAV's (2026-08-27): the M3A
# Knights (QAV's AbramsX) and QAV's Marshalls, which ROSTER_ADD pulls in and
# GROUP_SUB puts into the armour and mech groups in place of E22's.
#
# THE US ARMY'S ARMOUR IS QAV's; ITS ARTILLERY AND AIRCRAFT ARE NATO's (user,
# 2026-08-28): E22's air arm - Sparrowhawk, Blackfish, its F-181s - goes,
# and the base game's Little Birds, Ghost Hawks, Hurons, A-10Ds and Black
# Wasps come in through ROSTER_ADD (_NATO_AIR), with the Sholef, the Seara
# and RF's mortars (_NATO_ARTY). The `unless` lets exactly those through
# the two categories; the Blackfoot is still refused by NOT_FIELDED.
_JTF_NOT_FIELDED = (("Armored", "Air"),
                    lambda c: "qav" in c or "_arty_" in c or "_mlrs_" in c
                    or "apc_wheeled_01" in c or c.startswith("b_t_vtol_01")
                    or c.startswith("b_heli_") or c.startswith("b_plane_"))
NOT_FIELDED_VCLASS = {
    "jmfsb_Syndikat":   (("Air",), None),
    # THE PLA DRIVES AND FLIES ITS OWN (user, 2026-08-28): CSAT's armour, cars,
    # trucks and aircraft go; the PLA mod's come in (ROSTER_ADD). CSAT's boats,
    # statics, quad bikes and drones stay - the mod has none of those.
    "jmfsb_PLA_ard":    (("Armored", "Car", "Air", "Support"), lambda c: c in PLA_CLASSES or "quadbike" in c),
    "jmfsb_PLA_wdl":    (("Armored", "Car", "Air", "Support"), lambda c: c in PLA_CLASSES or "quadbike" in c),
    "jmfsb_US_JTF_wdl": _JTF_NOT_FIELDED,
    "jmfsb_US_JTF_des": _JTF_NOT_FIELDED,
    "jmfsb_US_JTF_tna": _JTF_NOT_FIELDED,
    "jmfsb_US_JTF_ocp": _JTF_NOT_FIELDED,
}

# CLASSES PULLED INTO A FACTION'S ROSTER FROM THE DUMP that its source faction
# does not list - built exactly like the roster's own (crew, kit, tier), not
# as extras. They must be in the dump and on the faction's side. The US Army
# gets QAV's Knights and Marshalls, the Ripsaw, and the GX vehicle drones
# (US kit - see KEEP_MODS) that used to ride in on BLU_F's roster.
# NO M3E1 KNIGHT (B_qav_abramsx_zeus) - user, 2026-08-28: the M3A1/A2/A3 only.
_QAV_ARMOUR = ["B_qav_abramsx", "B_qav_abramsx_templar", "B_qav_abramsx_tusk",
               "APC_Wheeled_01_apc_qav", "APC_Wheeled_01_mgs_QAV", "APC_Wheeled_01_mgs_up_QAV",
               "APC_Wheeled_01_shorad_QAV"]
# THE M6C BULLFROG JOINS THE FLEET (user, 2026-09-01: "make sure all the drones
# are in the jtf factions"). It was the only vehicle drone in the GX/QAV set
# that reached no JTF: QAV files it as faction qav_vehicles rather than BLU_F,
# so unlike qav_b_ripsaw_Mk44 beside it the roster scan never saw it and no
# table named it. One class, no camo variants, so all four theatres take it.
_US_DRONES = ["qav_b_ripsaw_Mk44", "qav_ripsaw_c",
              "GX_B_MQ8B_UAV_RECON", "GX_B_MQ8B_UAV_RECON_SEATED", "GX_B_MQ8B_UAV_ARMED",
              "GX_B_THEMIS_UGV_CARGO", "GX_B_THEMIS_UGV_DEFNDER_MEDIUM", "GX_B_THEMIS_UGV_HUNTER_LAUNCHER",
              "GX_B_HONEYBADGER_UGV_AT_GREEN", "GX_B_HONEYBADGER_UGV_AT_DESERT",
              "GX_B_HONEYBADGER_UGV_AT_BLACK", "GX_B_HONEYBADGER_UGV_AT_HEX",
              "GX_B_MAGURA_V5_USV", "GX_B_RWS_DEFNDER_MEDIUM", "GX_B_HUNTER_SP_LAUNCHER", "GX_B_HUNTER_SP_UAV"]
# THE BOATS ARE CREWED BY THE NAVY (2026-08-27): E22's Naval JTF has no
# groups and was dropped as a faction, but its Naval Infantry crew every
# JTF boat - see BOAT_CREW. Pulled into the roster so the crew class exists.
_US_NAVY = []   # E22 is gone (2026-08-29); the boats take the usual crew
# NATO'S AIRCRAFT AND ARTILLERY (user, 2026-08-28) - the same set in every
# theatre. The dynamic-loadout airframes; the legacy fixed-loadout twins
# (B_Heli_Light_01_armed_F, B_Plane_CAS_01_F) are the same aircraft twice.
# No Blackfoot - it is the EU's. The Naval JTF's fighter pilot comes along
# so the jets are not flown by a helicopter pilot (pick_crew).
_NATO_AIR = ["B_Heli_Light_01_F", "B_Heli_Light_01_stripped_F", "B_Heli_Light_01_dynamicLoadout_F",
             # THE FIVE TRANSPORTS IN EVERY JTF, PAINTED FOR THE THEATRE (user,
             # 2026-08-28) - see jtf_paint(); the camo, black and green twins are out.
             "B_Heli_Transport_01_F", "B_Heli_Transport_01_unarmed_F", "B_Heli_Transport_01_pylons_F",
             "B_Heli_Transport_03_F", "B_Heli_Transport_03_unarmed_F",
             "B_Plane_CAS_01_dynamicLoadout_F", "B_Plane_CAS_01_Cluster_F",
             "B_Plane_Fighter_01_F", "B_Plane_Fighter_01_Stealth_F", "B_Plane_Fighter_01_Cluster_F"]
# NOT BLU_F'S PILOT (2026-08-31). He was pulled in on 28 August so the jets
# were not flown by a helicopter crewman; every theatre has had its own plane
# pilot AND its own fighter pilot since the sources changed on the 29th, so
# this only drew a second "Pilot" in the list. The Marines, who have no pilot
# of their own at all, still take him - see _MARINE_AIR.
# THE ARTILLERY IS THE THEATRE'S OWN (user, 2026-08-31: "in jtf some arty
# seems duplicated"). This list was written on 2026-08-28, when the JTFs came
# off E22 rosters that had no artillery. Since 29 August their sources are the
# base game's own, and every one of them ships the Sholef, the Seara, the Mk6
# and RF's two mortars in the theatre's paint - so pulling BLU_F's plain twins
# in put every gun in the editor twice under the same name. The template's
# groups name B_T_ classes and resolve BY ROLE (see ROLE_PREFIXES), so
# `B_T_MBT_01_arty_F` finds `B_D_MBT_01_arty_lxWS` on its own.
_NATO_ARTY = []
# MARSHALLS AND BLACKFISH IN EVERY THEATRE (user, 2026-08-28): the tropic AMV-7 and
# Western Sahara's ATGM Marshall, and NATO Pacific's three V-44 X Blackfish - the
# only Blackfish there are (BLU_F has none).
# JK'S CLAM SHELL RADAR (user, 2026-08-28) - every JTF, both Marines and every
# east faction. It is a west class; the emitter gives it the faction's side
# and the faction's side's UAV AI as crew.
_CLAMSHELL = []   # the 76N6 Clam Shell radar, taken out of every faction (user, 2026-10-06)
# THE STATICS, THE MK6 AND THE DARTER LEFT THIS LIST (2026-08-31), for the
# reason the artillery and the Polaris did: BLU_F's plain XM307s, XM312s, Mk6
# and AR-2 are the same weapons every theatre already fields in its own paint,
# so pulling them in drew each one twice in the editor. What stays is what no
# source has a twin of - the Patriot and its radar, GX's Hunter-SP, the tropic
# Marshalls and Blackfish (user, 2026-08-28) and the Clam Shell.
_JTF_COMMON = ["B_T_APC_Wheeled_01_cannon_F", "B_T_APC_Wheeled_01_atgm_lxWS",
               "B_T_VTOL_01_armed_F", "B_T_VTOL_01_infantry_F", "B_T_VTOL_01_vehicle_F",
               "B_SAM_System_03_F", "B_Radar_System_01_F",
               # QAV'S MV-35 IS NOT HERE - it is per theatre, in _JTF_VTOL_*.
               "GX_B_HUNTER_SP_LAUNCHER"] + _CLAMSHELL
# PER THEATRE (user, 2026-08-28): EF's M-ATV LAAD / AT / FSV in the NATO tropic
# scheme for the green theatres and Western Sahara's NATO desert scheme for the
# tan ones; E22's JC air defence - NASAMS, Skynex, Sentinel - green (JC_W) or tan
# (JC_D); the base game's Prowlers (Polaris DAGOR), painted olive or sand by
# jtf_paint(), the Pacific ones for the tropical JTF.
# E22's JC air defence went with E22 (2026-08-29); the base game's Praetorian
# stands in beside the Patriot and radar already in _JTF_COMMON.
_JTF_GREEN = ["EF_B_MRAP_01_LAAD_NATO_T", "EF_B_MRAP_01_AT_NATO_T", "EF_B_MRAP_01_FSV_NATO_T",
              "B_AAA_System_01_F"]
# THE MEDEVAC MARSHALL (user, 2026-08-31: "add the medical one to jtf's").
# Woodland and tropical get theirs from their own source; Western Sahara has
# no B_D_ medical AMV-7 at all, so the two tan theatres take Aegis's MJTF
# desert one - the same vehicle, already in desert paint, rather than the
# base game's green medevac parked in a desert order of battle.
_JTF_TAN = ["EF_B_MRAP_01_LAAD_NATO_Des", "EF_B_MRAP_01_AT_NATO_Des", "EF_B_MRAP_01_FSV_NATO_Des",
            "B_AAA_System_01_F", "Aegis_B_MJTF_D_APC_Wheeled_01_medical_F"]
# THE POLARIS IS THE THEATRE'S OWN TOO (user, 2026-08-31: "in jtf the
# polorases seem doubled as well"). Same story as _NATO_ARTY: BLU_W_F has the
# four B_W_ Prowlers, Western Sahara the four Aegis_B_D_ ones and BLU_T_F the
# four B_T_ ones - each including the light variant the plain list never had -
# so the three BLU_F twins were a second Polaris under every name. The Marines
# have none of their own and get a set of their theatre's, below.
_JTF_LSV = []
_JTF_LSV_TNA = []
_MARINE_LSV_WDL = ["B_W_LSV_01_armed_F", "B_W_LSV_01_unarmed_F", "B_W_LSV_01_AT_F", "B_W_LSV_01_light_F"]
_MARINE_LSV_DES = ["Aegis_B_D_LSV_01_armed_F", "Aegis_B_D_LSV_01_unarmed_F",
                   "Aegis_B_D_LSV_01_AT_F", "Aegis_B_D_LSV_01_light_F"]
# THE SAME FIXED WING AS THE JTF (user, 2026-08-31: "marines need the same
# planes as jtf") - the A-10D pair and the three Black Wasps, with NATO's pilot
# so a jet is not flown by a helicopter crewman (see pick_crew). The Marines'
# own EF helicopters stay; this is the plane list only.
_MARINE_AIR = [c for c in _NATO_AIR if c.startswith("B_Plane_")] + ["B_Pilot_F"]
# THE MV-35 FOR THE MARINES TOO (user, 2026-09-01), per theatre the way
# _MARINE_LSV_* and the JC air defence already are.
#
# QAV_MV35_EF.pbo ships three Marine-and-Navy reskins of the MV-35 - MJTF_Wdl,
# MJTF_Des and Navy - and their factions are EF_B_MJTF_Wdl / EF_B_MJTF_Des /
# EF_B_MJTF_Navy, which are the very sources the two Marine addons are built
# from (see TARGETS). So each Marine faction takes the airframe painted for it
# rather than one of them taking the other's.
#
# EF_B_VTOL_03_unarmed_Navy_QAV is deliberately not fielded here: there is no
# jmfsb Navy faction for it to belong to.
_MARINE_VTOL_WDL = ["EF_B_VTOL_03_unarmed_MJTF_Wdl_QAV"]
_MARINE_VTOL_DES = ["EF_B_VTOL_03_unarmed_MJTF_Des_QAV"]
# QAV'S MV-35 TO THE FOUR ARMY JTFs (user, 2026-09-01), one airframe each and
# in its own theatre's paint. It sits beside the Blackfish in _JTF_COMMON
# rather than replacing it: the Blackfish carries vehicles, the MV-35 carries
# people further.
#
# THE ASK NAMED B_VTOL_03_unarmed_QAV, the plain BLU_F one. QAV ships the same
# airframe four times - BLU_F black, _T_ tropical olive, _W_ woodland olive and
# _D_ Western Sahara sand - and each JTF theatre is built from exactly the
# source faction one of those three reskins belongs to, so naming the plain one
# for all four would have put a black aircraft in every order of battle AND
# drawn a second Phantom in the three theatres whose own source carries one.
# Split the way _JTF_GREEN and _JTF_TAN are; say the word and it goes back to
# one class for all four.
#
# The plain B_VTOL_03_unarmed_QAV still reaches jmfsb_EUDF, which is built from
# BLU_F - not from this table, but because the roster scan finds it there.
_JTF_VTOL_WDL = ["B_W_VTOL_03_unarmed_QAV"]
_JTF_VTOL_TNA = ["B_T_VTOL_03_unarmed_QAV"]
_JTF_VTOL_TAN = ["B_D_VTOL_03_unarmed_QAV"]
# THE M3A1 IN PLACE OF THE MERKAVAS (user, 2026-08-31). QAV's AbramsX - the
# same tank the JTFs field as the M3A1 Knight.
_MARINE_ARMOUR = ["B_qav_abramsx"]
# THE TROPICAL JTF IS GREEN (user, 2026-08-28): NATO Pacific's Scorcher and
# Sandstorm, QAV's Pacific Knight and olive Marshalls (no tropic TUSK or Templar
# exists), the camo Ghost Hawk, the green Hurons and the green Honeybadger take
# the place of the tan, grey and black ones. Little Birds, the A-10 and the
# Black Wasp have no green scheme and stay as they are.
# THE TEMPLAR AND THE TUSK JOIN THE TROPICAL ROSTER ANYWAY (user, 2026-09-01:
# "make sure plt 2 has access to all abramsx"). QAV paints neither of them
# green - there is no B_T_ twin, only the plain scheme - so this is knowingly
# two tanks in the wrong camo for Tanoa, taken because 2nd PLT is a tank platoon
# and a tank platoon that can only draw one turret is not one.
#
# ROSTER ONLY. The GROUPS still fold both onto the tropical Knight (_TNA_QAV
# below), so no order of battle spawns a plain-scheme tank into the tropics;
# these two are here to be DRAWN - from the motorpool, by a crew that asked for
# them - and nothing else pulls them.
_QAV_ARMOUR_TNA = ["B_T_qav_abramsx", "B_qav_abramsx_templar", "B_qav_abramsx_tusk",
                   "B_T_APC_Wheeled_01_apc_QAV", "B_T_APC_Wheeled_01_mgs_QAV",
                   "B_T_APC_Wheeled_01_mgs_up_QAV", "B_T_APC_Wheeled_01_shorad_QAV"]
_NATO_ARTY_TNA = []   # BLU_T_F ships all four - see _NATO_ARTY
_NOT_GREEN = ("B_Heli_Transport_01_F", "B_Heli_Transport_01_unarmed_F", "B_Heli_Transport_01_pylons_F",
              "B_Heli_Transport_03_black_F", "B_Heli_Transport_03_unarmed_F")
# (_NOT_GREEN is history: the transports are painted per theatre by jtf_paint().)
_NATO_AIR_TNA = list(_NATO_AIR)
_US_DRONES_TNA = [x for x in _US_DRONES if "HONEYBADGER" not in x or x.endswith("_GREEN")]
_EU_BLACKFOOT = ["B_Heli_Attack_01_dynamicLoadout_F", "B_Heli_Attack_01_pylons_dynamicLoadout_F"]
# THE EU'S ARMOUR AND AIR (user, 2026-08-31), named class by class. The Nyx is
# Atlas's German LT_01 - the desert theatre takes its _ard_F twin, the other
# four the green one; there is no white Nyx, so the arctic theatre keeps green.
_EU_NYX = ["Atlas_B_G_LT_01_AT_F", "Atlas_B_G_LT_01_AA_F",
           "Atlas_B_G_LT_01_cannon_F", "Atlas_B_G_LT_01_scout_F"]
_EU_NYX_ARD = ["Atlas_B_G_LT_01_AT_ard_F", "Atlas_B_G_LT_01_AA_ard_F",
               "Atlas_B_G_LT_01_cannon_ard_F", "Atlas_B_G_LT_01_scout_ard_F"]
_EU_TANK = ["Atlas_B_G_MBT_03_cannon_F"]          # Luchs 3A5
# The helicopters: RF's two Super Cougars, the Comanche pair and EF's naval
# one, Atlas's Merlin, and the three Ghost Hawk transports. The American
# designations are renamed for these factions only - see EU_RENAME.
_EU_HELI = ["B_Heli_EC_03_RF", "B_Heli_EC_04_military_RF",
            "B_Heli_Attack_01_dynamicLoadout_F", "B_Heli_Attack_01_pylons_dynamicLoadout_F",
            "EF_B_AH99J_NATO", "Aegis_B_A_Heli_Transport_02_wdl_F",
            "B_Heli_Transport_01_unarmed_F", "B_Heli_Transport_01_pylons_F",
            "B_Heli_Transport_01_F"]
# The fixed wing: Atlas's arid Peregrine, NATO Pacific's two Samsons and
# Revolucion's Gryphon.
_EU_PLANE = ["Atlas_B_A_Plane_Fighter_05_ard_F",
             "B_A_Plane_Transport_01_infantry_tna_F", "B_A_Plane_Transport_01_vehicle_tna_F",
             "rev_B_Plane_Fighter_04_F"]
# STILL TO COME - the mods are installed but not in the load order, so the
# 30 August dump has none of their classes: the FV510 Warrior, the Pandur II
# and QAV's Challenger 2 (qav_challenger2, qav_challenger2_e). Load them, run
# tools/dump_orbat.sqf, and add them to _EU_TANK / a new _EU_IFV here.
_EU_ARMOUR = _EU_NYX + _EU_TANK
_EU_ARMOUR_ARD = _EU_NYX_ARD + _EU_TANK
# THE EUDF'S EXTRAS (user, 2026-08-28): NATO's Cheetah and RF's Ram 1500 (AA),
# painted for the theatre by eu_paint() where the base game has the paint; EF's
# combat boats in NATO's scheme; and the drones aligned with the JTFs - the GX
# fleet (_US_DRONES) beside EUDF35's own Darters.
_EU_EXTRA = ["B_APC_Tracked_01_AA_F", "B_Pickup_aat_rf",
             "EF_B_CombatBoat_Unarmed_NATO", "EF_B_CombatBoat_HMG_NATO", "EF_B_CombatBoat_AT_NATO",
             # QAV's Ripsaws, the plain ones (user, 2026-08-28): the M6A (Mk44) and the M6C Bullfrog
             "qav_ripsaw_Mk44", "qav_ripsaw_c"]
# E22's JC air defence for the EUDF too (user, 2026-08-28): green for the
# temperate theatre, tan for the arid one - and for the arctic one, where tan
# is the lighter of the two paints E22 ships.
_JC_GREEN = ["B_AAA_System_01_F"]
_JC_TAN = ["B_AAA_System_01_F"]
# THE ANTI-SHIP BATTERY (user, 2026-08-30: "does China, Russia and Iran have
# anti-ship missile systems - if not add them"). addons/antiship declares its
# launcher and its surface-search radar under OPF_F, so IRAN INHERITS THEM WITH
# ITS SOURCE and needs no entry below; the two Chinas (OPF_T_F / OPF_CD_F) and
# the three Russias never see them and are named.
_ANTISHIP = ["jmfsb_antiship_launcher", "jmfsb_antiship_radar"]

# E22'S JOINT COMMAND AIR DEFENCE, BY COLOUR (user, 2026-08-30: "sort by
# colour, to all US factions"). ADS-1 NASAMS, ADS-2 Skynex and the JC radar -
# W on the green theatres, D on the tan ones. They sit BESIDE the base-game
# Praetorian the JTFs already field rather than replacing it.
_JC_AD_W = ["E22_B_JC_W_SAM_system_01_F", "E22_B_JC_W_AAA_System_01_F",
            "E22_B_JC_W_Radar_system_01_F"]
_JC_AD_D = ["E22_B_JC_D_SAM_system_01_F", "E22_B_JC_D_AAA_System_01_F",
            "E22_B_JC_D_Radar_system_01_F"]

ROSTER_ADD = {
    "jmfsb_US_JTF_wdl": _QAV_ARMOUR + _US_DRONES + _US_NAVY + _NATO_ARTY + _NATO_AIR + _JTF_COMMON + _JTF_GREEN + _JTF_LSV + _JC_AD_W + _JTF_VTOL_WDL,
    "jmfsb_US_JTF_des": _QAV_ARMOUR + _US_DRONES + _US_NAVY + _NATO_ARTY + _NATO_AIR + _JTF_COMMON + _JTF_TAN + _JTF_LSV + _JC_AD_D + _JTF_VTOL_TAN,
    "jmfsb_US_JTF_tna": _QAV_ARMOUR_TNA + _US_DRONES_TNA + _US_NAVY + _NATO_ARTY_TNA + _NATO_AIR_TNA + _JTF_COMMON + _JTF_GREEN + _JTF_LSV_TNA + _JC_AD_W + _JTF_VTOL_TNA,
    "jmfsb_US_JTF_ocp": _QAV_ARMOUR + _US_DRONES + _US_NAVY + _NATO_ARTY + _NATO_AIR + _JTF_COMMON + _JTF_TAN + _JTF_LSV + _JC_AD_D + _JTF_VTOL_TAN,
    # THE EUDF (user, 2026-08-31). Its own armour and air in every theatre;
    # the desert one takes the arid Nyx.
    # the JC air defence on the EU as well (user, 2026-09-21: "add to the eu make sure to add the ai crew")
    "jmfsb_EUDF":     _EU_ARMOUR + _EU_HELI + _EU_PLANE + _JC_AD_W,
    "jmfsb_EUDF_wdl": _EU_ARMOUR + _EU_HELI + _EU_PLANE,
    "jmfsb_EUDF_tna": _EU_ARMOUR + _EU_HELI + _EU_PLANE,
    "jmfsb_EUDF_arc": _EU_ARMOUR + _EU_HELI + _EU_PLANE,
    "jmfsb_EUDF_des": _EU_ARMOUR_ARD + _EU_HELI + _EU_PLANE,
    # the Marines are US too, and take the JC set in their own camo, the
    # JTF's fixed wing, a Polaris troop in their theatre's paint and the M3A1
    # that replaced their Merkavas (all user, 2026-08-31)
    "jmfsb_Marine_wdl": _JC_AD_W + _MARINE_AIR + _MARINE_LSV_WDL + _MARINE_ARMOUR + _MARINE_VTOL_WDL,
    "jmfsb_Marine_des": _JC_AD_D + _MARINE_AIR + _MARINE_LSV_DES + _MARINE_ARMOUR + _MARINE_VTOL_DES,
    # every vehicle the PLA mod ships, both theatres - painted per theatre by pla_camo()
    "jmfsb_PLA_ard":  sorted(PLA_INDEX),
    "jmfsb_PLA_wdl":  sorted(PLA_INDEX),
    # 2040 CHINA'S HERMES (user, 2026-08-30: "and this to china factions -
    # rksla3_uav_h450_2"). RKSL's east-painted Hermes 450; it is filed under
    # OPF_F in the dump, so neither China source lists it and it has to be
    # named here. The "Hermes 450 is ind" rule in NOT_FIELDED refuses it to
    # CSAT, Russia and the PLA - the two Chinas are deliberately not on that
    # list.
    "jmfsb_China":      ["rksla3_uav_h450_2"] + _ANTISHIP,
    "jmfsb_China_ard":  ["rksla3_uav_h450_2"] + _ANTISHIP,
    # QAV'S T-90A FOR THE THREE RUSSIAS, AND THE T-72A AS WELL FOR IRAN
    # (user, 2026-08-31). The OPFOR Vehicles Pack is installed but not in the
    # load order, so the 30 August dump has neither and both are skipped with
    # a note - load the mod, re-dump, and they appear.
    "jmfsb_Russia":     _ANTISHIP + ["OPF_F_QAV_T90A"],
    "jmfsb_Russia_ard": _ANTISHIP + ["OPF_F_QAV_T90A"],
    "jmfsb_Russia_arc": _ANTISHIP + ["OPF_F_QAV_T90A"],
    "jmfsb_Iran":       ["OPF_F_QAV_T90A", "OPF_F_QAV_T72A"],
    # 2040 TURKEY (user, 2026-08-31). EF's four Gyras, the Guerrilla Marid,
    # NATO's HEMTT family and its Hunters - west classes the emitter re-sides
    # to east, the way the Clam Shell already is - and Athena's own F-35 pair
    # and Apache, which are the airframes of the mod the faction comes from.
    "jmfsb_Turkey": ["EF_O_Gyra_OPF", "EF_O_Gyra_HMG_OPF", "EF_O_Gyra_Armed_OPF",
                     "EF_O_Gyra_Antiair_OPF", "O_G_APC_Wheeled_03_cannon_F",
                     "B_Truck_01_mover_F", "B_Truck_01_ammo_F", "B_Truck_01_cargo_F",
                     "B_Truck_01_box_F", "B_Truck_01_flatbed_F", "B_Truck_01_fuel_F",
                     "B_Truck_01_medical_F", "B_Truck_01_Repair_F",
                     "B_Truck_01_transport_F", "B_Truck_01_covered_F",
                     "B_MRAP_01_F", "B_MRAP_01_gmg_F", "B_MRAP_01_hmg_F",
                     "Athena_B_G_Plane_Fighter_05_F", "Athena_B_G_Plane_Fighter_05_Stealth_F",
                     "Athena_B_G_Heli_Attack_03_F"] + _ANTISHIP,
    # THE SYNDIKAT'S LOW-END DRONES (user, 2026-08-28): the UAV_02 quad and its
    # IED twin - crude, daylight, bought - for the squads (SQUAD_DRONES) - and
    # ITS STATICS (user, 2026-08-30): ACE's Super-Dragon, the guerrillas' Mk6
    # mortar and the independents' two SwitchBlade launch tubes. All four are
    # emplaced weapons a bandit crew can carry to a roof and leave, which is
    # what tier 0 has instead of vehicles.
    "jmfsb_Syndikat": ["I_UAV_02_lxWS", "I_G_UAV_02_IED_lxWS",
                       "ace_dragon_staticAssembled", "I_G_Mortar_01_F",
                       "I_SwitchBlade_300_LaunchTube_Woodland",
                       "I_SwitchBlade_600_LaunchTube_Woodland"],
}
# THE CLAM SHELL EVERYWHERE ELSE IT GOES - see _CLAMSHELL.
for _f in ("jmfsb_Marine_wdl", "jmfsb_Marine_des",
           "jmfsb_CSAT", "jmfsb_CSAT_tna", "jmfsb_PLA_ard", "jmfsb_PLA_wdl"):
    ROSTER_ADD[_f] = list(ROSTER_ADD.get(_f, [])) + _CLAMSHELL

# {faction: dumped man class} - the crew written for every vehicle whose
# vehicleClass is "Ship". Submarines (the SDV) keep their divers. The man
# must be in the roster (ROSTER_ADD); if it is not, the usual crew stands.
BOAT_CREW = {}   # E22's naval infantry went with E22 (2026-08-29)

# GROUP SLOT SUBSTITUTION: {faction: {source class: class that takes its
# slot}}. Applied wherever a group names the source class - the group keeps
# its shape and its category, with QAV's vehicle where E22's was. The
# substitute must be in the roster (ROSTER_ADD).
_JTF_ARMOUR_SUB = {
    "APC_Wheeled_03_cannon_F":    "APC_Wheeled_01_mgs_QAV",
    "APC_Wheeled_03_cannon_AA_F": "APC_Wheeled_01_shorad_QAV",
    "APC_Wheeled_03_unarmed_F":   "APC_Wheeled_01_apc_qav",
    "MBT_03_cannon_F":            "B_qav_abramsx",
    "MBT_03_cannon_UP_F":         "B_qav_abramsx_tusk",
}
_PLA_SUB = {
    "O_MBT_02_cannon_F": "O_ZTZ96B", "O_MBT_02_arty_F": "O_PLZ05",
    "O_MBT_04_cannon_F": "O_ZTZ99A", "O_MBT_04_command_F": "O_ZTZ99A",
    "O_APC_Tracked_02_cannon_F": "O_ZBD04A", "O_APC_Tracked_02_AA_F": "O_PGZ09_AA",
    "O_APC_Wheeled_02_rcws_F": "O_ZBL09", "O_APC_Wheeled_02_rcws_v2_F": "O_ZBL09",
    "O_MRAP_02_F": "CSK181", "O_MRAP_02_hmg_F": "CSK181", "O_MRAP_02_gmg_F": "CSK181",
    "O_Truck_02_covered_F": "SX2316", "O_Truck_02_transport_F": "SX2316",
    "O_Truck_03_transport_F": "SX2220", "O_Truck_03_covered_F": "SX2220",
    "O_Heli_Attack_02_F": "Z10", "O_Heli_Attack_02_dynamicLoadout_F": "Z10",
    "O_Heli_Light_02_F": "Z11WA", "O_Heli_Light_02_dynamicLoadout_F": "Z19", "O_Heli_Light_02_unarmed_F": "Z11WA",
    "O_Heli_Transport_04_F": "Z8L", "O_Heli_Transport_04_bench_F": "Z8L", "O_Heli_Transport_04_covered_F": "Z8L",
    "O_Plane_CAS_02_dynamicLoadout_F": "PLAAF_Fighter_J10", "O_Plane_Fighter_02_F": "PLAAF_Fighter_J20",
    "O_Plane_Fighter_02_Stealth_F": "PLAAF_Fighter_J20",
    "EF_O_Gyra_OPF": "CSK181", "EF_O_Gyra_HMG_OPF": "CSK181", "EF_O_Gyra_Armed_OPF": "O_ZBL09",
    "EF_O_Gyra_Antiair_OPF": "O_PGZ09_AA", "EF_O_Gyra_Mortar_OPF": "O_PLL09",
    "O_LSV_02_armed_viper_F": "CSK181", "O_LSV_02_unarmed_viper_F": "CSK181",
}

# The tropic Knight and Marshalls for the Tropical JTF's groups; the TUSK and the
# Templar have no tropic twin and fold onto the plain Knight.
_TNA_QAV = {"APC_Wheeled_01_mgs_QAV": "B_T_APC_Wheeled_01_mgs_QAV", "APC_Wheeled_01_mgs_up_QAV": "B_T_APC_Wheeled_01_mgs_up_QAV",
            "APC_Wheeled_01_shorad_QAV": "B_T_APC_Wheeled_01_shorad_QAV", "APC_Wheeled_01_apc_qav": "B_T_APC_Wheeled_01_apc_QAV",
            "B_qav_abramsx": "B_T_qav_abramsx", "B_qav_abramsx_tusk": "B_T_qav_abramsx", "B_qav_abramsx_templar": "B_T_qav_abramsx"}
# NO STRIDERS (user, 2026-08-28): E22's own M-ATV of the same fit takes the
# slot, so the desert JTF's motorised groups keep their shape.
_JTF_STRIDER_SUB = {"MRAP_03_F": "MRAP_01_F", "MRAP_03_hmg_F": "MRAP_01_hmg_F", "MRAP_03_gmg_F": "MRAP_01_gmg_F"}


# THE BASE GAME'S ARMOUR IN THE US GROUPS (2026-08-29): BLU_F / BLU_W_F,
# Western Sahara's desert NATO, and NATO Pacific each name their own Slammers
# and Marshalls; QAV's Knight and Marshalls take the slots (the user's rule:
# US armour is QAV only, see _JTF_NOT_FIELDED).
# THE TEMPLATE'S ARMOUR (2026-08-30). With BLU_T_F's groups standing in for
# all four theatres (GROUP_TEMPLATE), every theatre is handed B_T_ armour class
# names - so every theatre needs them mapped, not just the tropical one, or the
# tank, mech-AA and mech-AT groups drop out of three factions and the four are
# not the same after all. The Rhino MGS joins the table here: it is a wheeled
# gun system and QAV's MGS is what the JTFs field in that slot.
_US_ARMOUR_SUB_TMPL = {
    "B_T_MBT_01_cannon_F": "B_qav_abramsx", "B_T_MBT_01_TUSK_F": "B_qav_abramsx_tusk",
    "B_T_APC_Wheeled_01_cannon_F": "APC_Wheeled_01_mgs_QAV",
    "B_T_APC_Tracked_01_rcws_F": "APC_Wheeled_01_apc_qav",
    "B_T_APC_Tracked_01_CRV_F": "APC_Wheeled_01_apc_qav",
    "B_T_APC_Tracked_01_AA_F": "APC_Wheeled_01_shorad_QAV",
    "B_T_AFV_Wheeled_01_cannon_F": "APC_Wheeled_01_mgs_QAV",
    "B_T_AFV_Wheeled_01_up_cannon_F": "APC_Wheeled_01_mgs_up_QAV",
}

_US_ARMOUR_SUB = {
    "B_MBT_01_cannon_F": "B_qav_abramsx", "B_MBT_01_TUSK_F": "B_qav_abramsx_tusk",
    "B_APC_Wheeled_01_cannon_F": "APC_Wheeled_01_mgs_QAV", "B_APC_Wheeled_03_cannon_F": "APC_Wheeled_01_mgs_QAV",
    "B_APC_Tracked_01_rcws_F": "APC_Wheeled_01_apc_qav", "B_APC_Tracked_01_CRV_F": "APC_Wheeled_01_apc_qav",
    "B_APC_Tracked_01_AA_F": "APC_Wheeled_01_shorad_QAV",
}
_US_ARMOUR_SUB_D = dict(_US_ARMOUR_SUB, **{
    "B_D_MBT_01_cannon_lxWS": "B_qav_abramsx", "B_D_MBT_01_TUSK_lxWS": "B_qav_abramsx_tusk",
    "B_D_APC_Wheeled_01_cannon_lxWS": "APC_Wheeled_01_mgs_QAV",
    "B_D_APC_Tracked_01_rcws_lxWS": "APC_Wheeled_01_apc_qav", "B_D_APC_Tracked_01_CRV_lxWS": "APC_Wheeled_01_apc_qav",
    "B_D_APC_Tracked_01_aa_lxWS": "APC_Wheeled_01_shorad_QAV",
})
# The tropical theatre's QAV wears the tropical paint, so it keeps its own
# table rather than the template one above.
_US_ARMOUR_SUB_T = {
    "B_T_MBT_01_cannon_F": "B_T_qav_abramsx", "B_T_MBT_01_TUSK_F": "B_T_qav_abramsx",
    "B_T_APC_Wheeled_01_cannon_F": "B_T_APC_Wheeled_01_mgs_QAV",
    "B_T_APC_Tracked_01_rcws_F": "B_T_APC_Wheeled_01_apc_QAV", "B_T_APC_Tracked_01_CRV_F": "B_T_APC_Wheeled_01_apc_QAV",
    "B_T_APC_Tracked_01_AA_F": "B_T_APC_Wheeled_01_shorad_QAV",
    "B_T_AFV_Wheeled_01_cannon_F": "B_T_APC_Wheeled_01_mgs_QAV",
    "B_T_AFV_Wheeled_01_up_cannon_F": "B_T_APC_Wheeled_01_mgs_up_QAV",
}
# The three non-tropical theatres: their own theatre's armour AND the
# template's, both pointed at the plain QAV.
_US_ARMOUR_SUB = dict(_US_ARMOUR_SUB, **_US_ARMOUR_SUB_TMPL)
_US_ARMOUR_SUB_D = dict(_US_ARMOUR_SUB_D, **_US_ARMOUR_SUB_TMPL)


def _jtf_sub(pfx, tna=False):
    d = dict((pfx + k, (_TNA_QAV.get(v, v) if tna else v)) for k, v in _JTF_ARMOUR_SUB.items())
    d.update((pfx + k, pfx + v) for k, v in _JTF_STRIDER_SUB.items())
    return d


# ONE ORDER OF BATTLE FOR THE FOUR JTF THEATRES (user, 2026-08-30: "make sure
# all the jtf factions have the same groups").
#
# WHAT WAS WRONG. A faction's groups come from its source faction, and the four
# sources are not comparable: BLU_T_F ships 49 groups, BLU_NATO_lxWS 38, and
# BLU_W_F six - all six infantry, no recon, no armour, no support. The woodland
# JTF was a rifle company and the tropical one was an army.
#
# {faction: template source faction}. The template's CfgGroups is used INSTEAD
# OF the faction's own, and each member is resolved into this faction's own
# roster by ROLE - `B_T_Soldier_AR_F` and `B_W_Soldier_AR_F` and
# `B_D_soldier_AR_lxWS` all reduce to `soldier_ar`. The map is primed into
# `gsub`, which the emitter already applies to every group member, so the
# groups come out identical in shape and named entirely in our own classes.
#
# BLU_T_F IS THE TEMPLATE because it is the complete one of the four sources
# and it is already one of ours - the tropical theatre's groups do not change
# at all, and the other three are levelled up to them rather than everything
# being levelled down to BLU_W_F's six.
#
# A MEMBER WITH NO EQUIVALENT IS BORROWED, NOT DROPPED: the class stays as the
# template names it and the existing roster loop adds it to this faction (the
# woodland theatre has no recon, no divers and no sniper of its own, so it
# borrows the tropical ones and KIT_SWAP re-dresses them - see the entries
# there). The run report prints every borrow. What `keep()` refuses - the
# vanilla armour the JTFs do not field, see NOT_FIELDED_VCLASS - is still
# refused, and GROUP_SUB puts QAV's armour in its place as before.
GROUP_TEMPLATE = {
    # 2040 China: the desert faction ships 9 groups to the tropical one's 64,
    # so both are built from the tropical order of battle (user, 2026-08-30:
    # "make sure both factions are equal in units and groups").
    "jmfsb_China": "OPF_T_F",
    "jmfsb_China_ard": "OPF_T_F",
    # 2040 Russia, all three (user, 2026-08-30: "so the Russian factions have
    # the same number of groups"). Woodland ships 60 groups, arid 41 and
    # arctic 38, so woodland is the order of battle for all three and each
    # resolves it into its own men - the arid faction's _ard_F twins and the
    # arctic faction's CF_ ones. This is groups only: their ROSTERS are still
    # their own, because "copy those three over as is" was the standing rule.
    "jmfsb_Russia": "OPF_R_F",
    "jmfsb_Russia_ard": "OPF_R_F",
    "jmfsb_Russia_arc": "OPF_R_F",
    "jmfsb_US_JTF_wdl": "BLU_T_F",
    "jmfsb_US_JTF_des": "BLU_T_F",
    "jmfsb_US_JTF_tna": "BLU_T_F",
    "jmfsb_US_JTF_ocp": "BLU_T_F",
    # The five EUDF sources are as unequal as the JTFs' were - BLU_W_F ships
    # six groups, BLU_F over a hundred - so they take the same template and
    # come out with one order of battle in five paints.
    "jmfsb_EUDF": "BLU_T_F",
    "jmfsb_EUDF_wdl": "BLU_T_F",
    "jmfsb_EUDF_des": "BLU_T_F",
    "jmfsb_EUDF_tna": "BLU_T_F",
    "jmfsb_EUDF_arc": "BLU_T_F",
    # Athena's Pacific OPFOR declares no groups of its own.
    "jmfsb_Turkey": "OPF_T_F",
}

# EQUAL IN UNITS, NOT ONLY IN GROUPS (user, 2026-08-30). A group template
# borrows the men and vehicles its GROUPS name; this borrows the whole roster,
# so the two factions field the same order of battle AND the same list of units.
# {faction: template source faction} - a unit the faction has an equivalent of
# by role is left alone, everything else is added.
ROSTER_TEMPLATE = {
    "jmfsb_China_ard": "OPF_T_F",
}

# A borrowed VEHICLE cannot be re-textured the way KIT_SWAP re-dresses a man,
# so the desert faction takes the base-game hex twin of a tropical vehicle
# where the load order has one: O_T_APC_Wheeled_02_rcws_ghex_F is
# O_APC_Wheeled_02_rcws_F in hex, same vehicle, right paint. Tried in order;
# the first that exists wins, and a vehicle with no twin stays as it is.
def _hex_twin(cls):
    """Hex-camo twins of a Pacific (ghex) class name, best first."""
    out = []
    c = cls
    if c.startswith("O_T_"):
        c = "O_" + c[len("O_T_"):]
    if c.endswith("_ghex_F"):
        out.append(c[:-len("_ghex_F")] + "_F")
    if "_ghex_" in c:
        out.append(c.replace("_ghex_", "_"))
    if c != cls:
        out.append(c)
    return out


VEHICLE_TWIN = {"jmfsb_China_ard": _hex_twin}

# Prefixes and suffixes stripped to get a role out of a class name, longest
# first - `B_D_soldier_AR_lxWS` -> `soldier_ar`.
# AEGIS AND ATLAS FILE A TROPICAL AND A WOODLAND ONE TOO (2026-08-31). Only
# their _B_D_ forms were listed, so Atlas_B_T_JSOC_F reduced to itself, matched
# nothing in a desert or woodland faction, and was BORROWED beside that
# faction's own Atlas_B_D_JSOC_F - the same operator twice, once in the wrong
# camo. Same for Aegis's light-mortar gunner.
ROLE_PREFIXES = ("Aegis_B_D_", "Atlas_B_D_", "Aegis_B_T_", "Atlas_B_T_",
                 "Aegis_B_W_", "Atlas_B_W_", "B_D_", "EF_B_", "B_T_", "B_W_", "B_",
                 # east, longest first: Aegis files its desert China under
                 # Aegis_O_C_D_ and the Pacific one is O_T_, so both have to
                 # come off before the bare O_ or the two never meet.
                 "Aegis_O_C_D_", "Atlas_O_C_D_", "Aegis_O_C_", "Atlas_O_C_",
                 "Aegis_O_T_", "Atlas_O_T_", "O_C_D_", "O_C_", "O_T_",
                 # Russia: the arctic faction files its men under CF_O_R_ and
                 # the other two under O_R_, so both come off before the bare
                 # O_ or a woodland rifleman never meets his arctic twin.
                 "CF_O_R_", "CF_O_", "O_R_", "O_")
ROLE_SUFFIXES = ("_lxWS_v2", "_lxWS", "_NATO_Des", "_olive_F", "_ghex_F", "_hex_F",
                 # Russia's arid roster is the woodland one with _ard on the end
                 "_ard_F", "_ard",
                 "_oicamo", "_ocamo", "_olive", "_ghex", "_hex", "_Des", "_RF", "_F")

# Where a theatre calls the same job something else. Western Sahara numbers its
# drone operators (`soldier_UAV01`) where the base game does not.
ROLE_ALIAS = {
    "soldier_uav": ("soldier_uav01",),
    "uav_02": ("soldier_uav02", "uav_02_dynamicloadout"),
}


def role_key(cls):
    """The job a class name describes, with the theatre stripped off."""
    c = cls or ""
    for p in ROLE_PREFIXES:
        if c.lower().startswith(p.lower()):
            c = c[len(p):]
            break
    for x in ROLE_SUFFIXES:
        if c.lower().endswith(x.lower()) and len(c) > len(x):
            c = c[:-len(x)]
            break
    return c.lower()


# The Marines' tank groups name the Merkava; NOT_FIELDED has refused it, so
# without this every one of them would be dropped for a missing vehicle.
_MARINE_ARMOUR_SUB_W = {"EF_B_MBT_01_cannon_MJTF_Wdl": "B_qav_abramsx",
                        "EF_B_MBT_01_TUSK_MJTF_Wdl":   "B_qav_abramsx"}
_MARINE_ARMOUR_SUB_D = {"EF_B_MBT_01_cannon_MJTF_Des": "B_qav_abramsx",
                        "EF_B_MBT_01_TUSK_MJTF_Des":   "B_qav_abramsx"}

GROUP_SUB = {
    "jmfsb_Marine_wdl": _MARINE_ARMOUR_SUB_W,
    "jmfsb_Marine_des": _MARINE_ARMOUR_SUB_D,
    "jmfsb_US_JTF_wdl": _US_ARMOUR_SUB,
    "jmfsb_US_JTF_des": _US_ARMOUR_SUB_D,
    "jmfsb_US_JTF_tna": _US_ARMOUR_SUB_T,
    "jmfsb_US_JTF_ocp": _US_ARMOUR_SUB_D,
    # CSAT's groups keep their shape with the PLA mod's vehicle in each slot:
    # T-100 -> ZTZ96B, T-140 -> ZTZ99A, Kamysh -> ZBD04A, Marid -> ZBL09, Ifrit ->
    # CSK181, Tempest -> SX2316/2220, Kajman -> Z10, Orca -> Z11/Z19, Taru -> Z8L,
    # Neophron -> J10, Shikra -> J20, EF Gyras -> the wheeled family.
    "jmfsb_PLA_ard": _PLA_SUB,
    "jmfsb_PLA_wdl": _PLA_SUB,
}

# A texture, icon or flag path into a dropped mod's PBO.
DROP_PATH = re.compile(r"\\A3_(?:%s)\\" % "|".join(DROP_MODS), re.I)

# The base game's side art, for a faction whose own lived in a dropped mod.
VANILLA_ART = {
    "icon": {0: r"\A3\Data_F\cfgFactionClasses_OPF_ca.paa",
             1: r"\A3\Data_F\cfgFactionClasses_BLU_ca.paa",
             2: r"\A3\Data_F\cfgFactionClasses_IND_ca.paa"},
    "flag": {0: r"\A3\Data_F\Flags\flag_CSAT_CO.paa",
             1: r"\A3\Data_F\Flags\flag_NATO_CO.paa",
             2: r"\A3\Data_F\Flags\flag_AAF_CO.paa"},
}


def load_vanilla():
    """Every class the base game defines, lower-cased -> {"backpack": ...};
    None if the index is absent. A dict, so `c in vanilla` still reads as a
    membership test and the backpack is there for NOT_FIELDED."""
    import json
    p = os.path.join(ROOT, "work", "vanilla_vehicles.json")
    if not os.path.exists(p):
        return None
    return dict((k.lower(), {"backpack": (e.get("backpack") or "").lower()})
                for k, e in json.load(io.open(p, encoding="utf-8")).items())


# THE DUMP'S OWN PARENT CHAIN, {class: parent}, filled in main(). The vanilla
# index is built from an unpacked a3 tree and that tree is not complete - it
# has no Apex classes in it at all - so a base-game class can be missing from
# the index and look exactly like a dropped mod's. Its PARENT gives it away.
DUMP_PARENT = {}


def _vanilla_by_parent(c, vanilla, depth=4):
    """Base-game after all? True when the parent chain reaches the index.

    Only the index counts as the answer - a parent that is itself unknown is
    followed, one that belongs to a mod is not, so a mod class inheriting from
    another mod class still comes out unknown.
    """
    if vanilla is None or not DUMP_PARENT:
        return False
    seen = set()
    while c and depth > 0:
        p = DUMP_PARENT.get(c) or DUMP_PARENT.get(c.lower())
        if not p or p.lower() in seen:
            return False
        seen.add(p.lower())
        if p.lower() in vanilla:
            return True
        for _name, test in KEEP_MODS:
            if test(p.lower()):
                return False
        c, depth = p, depth - 1
    return False


def class_origin(cls, vanilla, faction=None):
    """'dropped', 'vanilla', a KEEP_MODS name - or 'unknown' with no index.

    'dropped' covers a mod that left the load order, one the AI is not
    allowed to field (PLAYER_ONLY), and - given the faction - a base-game
    class that faction does not field (NOT_FIELDED): the faction treats
    them all the same.
    """
    c = cls.lower()
    if E22_JC_AD(c):
        # E22'S AIR DEFENCE IS STILL IN THE LOAD ORDER (2026-08-30). Northstar
        # went on 29 August and DROP_MODS still refuses the whole prefix, but
        # its Joint Command air-defence component did not go with it: the 30
        # August dump holds 36 E22 classes and all 36 are JC SAMs, AAA and
        # radars. The user asked for them back on the US factions, so they are
        # excepted here rather than by weakening the drop.
        return "vanilla"
    for m in DROP_MODS:
        if c.startswith(m.lower() + "_"):
            return "dropped"
    for _name, test in DROP_TESTS + PLAYER_ONLY:
        if test(c):
            return "dropped"
    if faction:
        # the class itself, or (base game) the bag it is issued with - a man
        # is dropped with the drone on his back
        bag = vanilla[c].get("backpack", "") if (vanilla is not None and c in vanilla) else ""
        for facs, tests in NOT_FIELDED.items():
            if faction in facs:
                for _name, test in tests:
                    if test(c) or (bag and test(bag)):
                        return "dropped"
    if vanilla is not None and c in vanilla:
        return "vanilla"
    for name, test in KEEP_MODS:
        if test(c):
            return name
    # NOT IN THE INDEX AND NOT A MOD WE KNOW - but the index is incomplete, so
    # ask the dump's parent chain before calling it dropped. See DUMP_PARENT.
    if _vanilla_by_parent(cls, vanilla):
        return "vanilla"
    return "dropped" if vanilla is not None else "unknown"


def is_dropped(cls, vanilla, faction=None):
    return class_origin(cls, vanilla, faction) == "dropped"


def pick_crew(orig, candidates):
    """Which of the faction's own men takes the seat a dropped mod's crew held.

    A Wipeout crewed by a tank crewman flies; it just looks wrong on the
    ramp. So the replacement is matched to what the source had - a pilot for
    a pilot, a helicopter pilot for a helicopter pilot, a boat crew for a
    boat crew - and only then falls back to the faction's crewman. None if
    the faction fields nobody fit for the seat.
    """
    o = orig.lower()
    if "uav_ai" in o:
        # A drone's crew is its autopilot. No man of ours takes that seat;
        # the line is left out and the parent's AI stands.
        return None

    def has(c, *ws):
        cl = c.lower()
        return all(w in cl for w in ws)

    def lacks(c, *ws):
        cl = c.lower()
        return not any(w in cl for w in ws)

    wants = []
    if "helipilot" in o or "helicrew" in o:
        # E22 has an attack-helicopter pilot as well as the plain one; a
        # Ghost Hawk gets the plain one first (alphabetical order put the
        # attack pilot in every NATO transport, 2026-08-28).
        wants = [lambda c: has(c, "helipilot") and lacks(c, "attack"),
                 lambda c: has(c, "helipilot"), lambda c: has(c, "pilot")]
    elif "pilot" in o:
        wants = [lambda c: has(c, "pilot") and lacks(c, "heli"), lambda c: has(c, "pilot")]
    elif "boatcrew" in o:
        wants = [lambda c: has(c, "boatcrew")]
    # "deck" keeps the carrier's deck crew off a tripod launcher
    wants.append(lambda c: has(c, "crew") and lacks(c, "heli", "boat", "pilot", "crewu", "deck"))
    for w in wants:
        hits = [c for c in candidates if w(c)]
        if hits:
            # THE PLAIN ONE FIRST: OPF_F has O_crew_F and Western Sahara's
            # O_A_crew_lxWS, and alphabetical order put the arid crewman in
            # every PLA tank. The shortest name is the unqualified one.
            return min(hits, key=lambda c: (len(c), c))
    return None


# ---------------------------------------------------------------------------
# PER-FACTION RIFLE SUBSTITUTION
# ---------------------------------------------------------------------------
# newfac -> [(match on the current weapon, replacement), ...] applied to
# weapons[] in order, first match wins. Putting a whole faction on one rifle
# is a small-arms decision, so it is expressed as a rule rather than a list of
# the spellings that happen to be in the roster today.
#
# GRENADIER LAUNCHERS WANT THEIR OWN RULE. Swapping a _GL_ rifle for a plain
# one takes the underbarrel launcher off the man and leaves him carrying 40mm
# he cannot fire. DMRs, LMGs, MMGs and SMGs are not rifles and are never
# matched: a 7.62 marksman handed a 5.56 rifle cannot feed it.
#
# CSAT IRAN (user, 2026-08-28): every rifle is Reaction Forces' ASh-12 -
# the presets RF's own QRF men carry (ACO, suppressor, flashlight; the GL
# with ACO and suppressor; the long-range one with the VRCO for whoever had
# a magnified optic) - and every machine gun is the Navid. Marksman rifles,
# the GM6, the SDAR and the SMGs are left alone, as the note above says.
_ASH, _ASH_GL, _ASH_LR = ("arifle_ash12_blk_aco_snd_flashlight_RF", "arifle_ash12_GL_blk_aco_snd_RF",
                          "arifle_ash12_LR_blk_vrco_snd_flashlight_RF")
_NAVID = "MMG_01_hex_ARCO_LP_F"


# THE PLA (user, 2026-08-28): the Katiba with the 6.2 round for the line - so
# anything OPF_F carries that is NOT a Katiba (CAR-95, RF's ASh-12, WS's SLR
# and Velko) becomes one - and the Type 115 for the leaders and the recon.
# Rules here get the man's class as well as the weapon: a team leader keeps
# his Katiba GL (the Type 115 has no launcher), so the 115 goes to the squad
# leaders, the recon (bar the JTAC's GL) and the officers; the Vipers have
# theirs already.
def is_115_man(c):
    cl = c.lower()
    return any(k in cl for k in ("_sl_", "recon", "officer")) and not any(k in cl for k in ("jtac", "_tl_"))


def _pla_rifles(arx):
    return [
        (lambda w, c: w.startswith("arifle_ARX") or w.startswith("arifle_SDAR"),      None),
        (lambda w, c: w.startswith("arifle_") and "_GL_" in w and "Katiba" not in w, "arifle_Katiba_GL_ACO_F"),
        (lambda w, c: w.startswith("arifle_") and "_GL_" in w,                        None),
        (lambda w, c: w.startswith("arifle_") and is_115_man(c),                      arx),
        (lambda w, c: w.startswith("arifle_") and "Katiba" not in w,                  "arifle_Katiba_ACO_pointer_F"),
    ]


_ARX_MAG = "20Rnd_650x39_Cased_Mag_F"
_PLA_MAGS = [
    # the 115 men's Katiba magazines become 6.5 cased (no FA round for it yet)
    (lambda m, c: m.startswith("30Rnd_65x39_caseless_green") and is_115_man(c), _ARX_MAG),
    # everyone else's foreign rifle magazine becomes the Katiba's 6.2 (tiered by the map)
    (lambda m, c: m.startswith(("30Rnd_580x42", "20Rnd_127x55", "10Rnd_127x55", "35Rnd_556x45_Velko",
                                "30Rnd_762x51_slr", "20Rnd_762x51_slr")), "30Rnd_65x39_caseless_green"),
]
_CSAT_RIFLES = [
    (lambda w: w.startswith("arifle_ash12"),                                 None),      # already one
    (lambda w: w.startswith("arifle_SDAR"),                                  None),      # the diver's
    (lambda w: w.startswith("arifle_") and "_GL_" in w,                      _ASH_GL),
    (lambda w: w.startswith("arifle_CTARS") or w.startswith("LMG_"),         _NAVID),    # CAR-95-1, Zafir, S77
    (lambda w: w.startswith("arifle_") and any(k in w for k in ("ARCO", "DMS")), _ASH_LR),
    (lambda w: w.startswith("arifle_"),                                      _ASH),
]
# 2040 CHINA (user, 2026-08-30: "keep that family of weapons, change it by
# unit type"). The family is the CTAR - the base game's black presets for the
# tropical force, Aegis's tan ones for the desert - and the unit type decides
# which member: the grenadier's is the GL, the crews and the men in a vehicle
# carry the short CTARS, the machine gunners the 5.8 LMG, and special forces
# get the suppressed preset of whichever they carry. Anything the roster
# carries that is NOT in the family - the SPARs Aegis issues its Chinese
# riflemen, Western Sahara's rifles - becomes the plain rifle. Marksman
# rifles, the GM6, the SDAR and pistols are left alone: the family has no
# member for those jobs.
def _sf_man(c):
    cl = c.lower()
    return any(k in cl for k in ("viper", "recon", "_sf_", "spec", "sniper", "diver"))


def _short_man(c):
    cl = c.lower()
    return any(k in cl for k in ("crew", "pilot", "helicrew", "engineer", "repair", "medic", "uav", "ugv"))


# A WEAPON CLASS WITH ITS MOD PREFIX OFF. Athena files its rifles as
# Athena_arifle_SPAR_01_blk_ARCO_IR_snds_F, so every `w.startswith("arifle_")`
# test below missed them and only the one rule written as `"_GL_" in w` hit -
# which is why the whole Athena recon element came out of 2040 Turkey still
# carrying SPARs while its riflemen, its crews and its grenadiers all carried
# the SCAR (user, 2026-09-01: "yes scar"). Five men: Recon, Recon_TL,
# Recon_medic, Recon_exp and recon_JTAC.
#
# The stem is searched for, not stripped blindly, so a name that never carried
# one comes back unchanged and "Throw"/"Put"/"Rangefinder" stay themselves.
def _un(w):
    for stem in ("arifle_", "srifle_", "hgun_", "launch_", "LMG_", "MMG_", "SMG_"):
        i = w.find(stem)
        if i > 0:
            return w[i:]
    return w


def _china_rifles(rifle, rifle_s, gl, gl_s, ctars, ctars_s, lmg, lmg_s):
    # EVERY TEST READS _un(w), THE STEM - see _un. A mod that signs its presets
    # is then matched exactly as the base game's, and the SDAR / pistol /
    # launcher exemption on the first line keeps working on a signed one too.
    return [
        # not the family's business
        (lambda w, c: _un(w).startswith(("srifle_", "arifle_SDAR", "hgun_", "launch_")), None),
        # already a machine gun, or a man who should carry one
        (lambda w, c: _un(w).startswith(("LMG_", "MMG_")) and _sf_man(c),                lmg_s),
        (lambda w, c: _un(w).startswith(("LMG_", "MMG_")),                               lmg),
        # the grenadier keeps his launcher
        (lambda w, c: "_GL_" in w and _sf_man(c),                                        gl_s),
        (lambda w, c: "_GL_" in w,                                                       gl),
        # The short one for crews, and for anyone already carrying it.
        #
        # THE _short_man CLAUSE MUST STILL LOOK AT THE WEAPON. Written as a
        # bare `or _short_man(c)` it matched on the man alone, so for a crewman,
        # pilot, medic, engineer or anything with "repair"/"uav" in its name
        # EVERY entry in weapons[] hit this rule - "Throw" and "Put" became a
        # third and fourth copy of the rifle, and the trucks, transport helis
        # and UAVs that carry those words in their class name lost TruckHorn3,
        # CMFlareLauncher and rksla3_wpn_masterarm the same way. That is where
        # the RPT's "Duplicate weapon ... detected for jmfsb_China_O_T_Crew_F"
        # came from, and why no AI in these three factions could throw a
        # grenade. A rule in this table may read the man, but it may only ever
        # replace something that is itself a rifle.
        (lambda w, c: (_un(w).startswith("arifle_CTARS") or "CTARS" in w
                       or (_un(w).startswith("arifle_") and _short_man(c))) and _sf_man(c), ctars_s),
        (lambda w, c: _un(w).startswith("arifle_CTARS") or "CTARS" in w
                      or (_un(w).startswith("arifle_") and _short_man(c)),               ctars),
        # everybody else: the rifle
        (lambda w, c: _un(w).startswith("arifle_") and _sf_man(c),                        rifle_s),
        (lambda w, c: _un(w).startswith("arifle_"),                                       rifle),
    ]


# 2040 IRAN (user, 2026-08-30): AK-103s, "and find the machine gun and sniper
# rifle and marksman rifle to fit into this scheme". The AK-103 is 7.62x39, so
# the machine gun is the RPK-12 in the same round rather than a 5.45 one, and
# the long guns are the SVD - the rifle Iran actually fields beside an AK.
# The plain AK-103 has no ARCO preset in the load order, so one is built - see
# EXTRA_PRESETS, the same way the Gendarmerie's UMP was.
_IRAN_RIFLES = [
    (lambda w, c: w.startswith(("arifle_SDAR", "hgun_", "launch_")),                None),
    # the long guns
    (lambda w, c: w.startswith("srifle_") and "GM6" in w,                           None),   # the AMR stays
    (lambda w, c: w.startswith("srifle_") and any(k in c.lower() for k in ("sniper", "spotter")),
     "Aegis_srifle_SVD_KHS_old_F"),
    (lambda w, c: w.startswith("srifle_"),                                          "Aegis_srifle_SVD_f"),
    # the machine gun, in the rifle's own round
    (lambda w, c: w.startswith(("LMG_", "MMG_")) or "RPK" in w or "Zafir" in w,      "arifle_RPK12_arco_pointer_F"),
    # the grenadier keeps his launcher
    (lambda w, c: "_GL_" in w,                                                      "Rev_arifle_AK103_GL_ARCO_AK_FL_F"),
    (lambda w, c: w.startswith("arifle_"),                                          "jmfsb_Iran_arifle_AK103_arco"),
]

RIFLE_SWAP = {
    "jmfsb_Iran": _IRAN_RIFLES,
    "jmfsb_China": _china_rifles(
        "arifle_CTAR_blk_ARCO_Pointer_F",       "arifle_CTAR_blk_ARCO_Pointer_Snds_F",
        "arifle_CTAR_GL_blk_ARCO_Pointer_F",    "arifle_CTAR_GL_blk_ARCO_Pointer_Snds_F",
        "arifle_CTARS_blk_ARCO_Pointer_F",      "arifle_CTARS_blk_ARCO_Pointer_Snds_F",
        "LMG_03_Arco_Pointer_F",                "LMG_03_arco_Pointer_snds_F"),
    # The desert force carries Aegis's tan CTARs. There is no tan LMG_03
    # preset in the load order, so the machine gun is the same one - said out
    # loud here rather than left to be noticed in game.
    "jmfsb_China_ard": _china_rifles(
        "Aegis_arifle_CTAR_tan_ARCO_Pointer_F",    "Aegis_arifle_CTAR_tan_ARCO_Pointer_Snds_F",
        "Aegis_arifle_CTAR_GL_tan_ARCO_Pointer_F", "Aegis_arifle_CTAR_GL_tan_ARCO_Pointer_Snds_F",
        "Aegis_arifle_CTARS_tan_ARCO_Pointer_F",   "Aegis_arifle_CTARS_tan_ARCO_Pointer_Snds_F",
        "LMG_03_Arco_Pointer_F",                   "LMG_03_arco_Pointer_snds_F"),
    "jmfsb_CSAT":     _CSAT_RIFLES,
    "jmfsb_CSAT_tna": _CSAT_RIFLES,
    # 2040 TURKEY CARRIES SCARs (user, 2026-08-31), from the list they gave.
    # THE SCAR-L, NOT THE SCAR-H: Athena's Pacific OPFOR already issues
    # 30Rnd_556x45_Stanag, so the 5.56 family is a straight swap and nobody
    # ends up with 7.62 rifles over 5.56 pouches. Special forces take the grip
    # variant, crews and the short-rifle men the CQB one, and the machine
    # guns, marksman rifles, pistols and launchers are left as issued.
    "jmfsb_Turkey": _china_rifles(
        "arifle_SCAR_L_F",       "arifle_SCAR_L_grip_F",
        "arifle_SCAR_L_GL_F",    "arifle_SCAR_L_GL_F",
        "arifle_SCAR_L_short_F", "arifle_SCAR_L_short_F",
        None,                    None),
    "jmfsb_PLA_ard":  _pla_rifles("arifle_ARX_hex_ARCO_Pointer_Snds_F"),
    "jmfsb_PLA_wdl":  _pla_rifles("arifle_ARX_ghex_ARCO_Pointer_Snds_F"),
}

# MAGAZINES TO MATCH - newfac -> [(match on the magazine, replacement)], first
# match wins, applied before the tier pass. The 12.7x55 and 9.3x64 have no FA
# round, so they stay as RF and the base game issue them. Marksman, sniper,
# underwater and pistol magazines are not matched.
_ASH_MAG, _NAVID_MAG = "20Rnd_127x55_Mag_RF", "150Rnd_93x64_Mag"
_CSAT_MAGS = [
    # 20-round magazines throughout (user, 2026-08-28) - the 10s RF issues
    # with the same rifle become 20s too.
    (lambda m: m == "10Rnd_127x55_Mag_RF", _ASH_MAG),
    (lambda m: m.startswith(("150Rnd_762x54_Box", "100Rnd_580x42", "100Rnd_762x51_S77", "200Rnd_65x39_cased")), _NAVID_MAG),
    (lambda m: m.startswith(("30Rnd_65x39_caseless_green", "30Rnd_580x42", "35Rnd_556x45_Velko",
                             "30Rnd_762x51_slr", "20Rnd_762x51_slr", "30Rnd_556x45_Stanag_green",
                             "20Rnd_650x39_Cased")), _ASH_MAG),
]
# 2040 CHINA: whatever the rifle was, the magazine is the 5.8 - the FA tier
# pass downstream turns it into the 2040 round (FA_o_30Rnd_580x42_*_t4, "make
# sure they have 2040 ammo"). The LMG's 100-round belt has no FA build yet, so
# it stays the base game's.
_CHINA_MAGS = [
    (lambda m: m.startswith(("100Rnd_580x42", "150Rnd_762x54", "200Rnd_65x39_cased",
                             "150Rnd_93x64", "130Rnd_338")),                 "100Rnd_580x42_Mag_F"),
    (lambda m: m.startswith(("30Rnd_65x39_caseless", "30Rnd_556x45_Stanag", "20Rnd_650x39_Cased",
                             "30Rnd_762x51_slr", "20Rnd_762x51_slr", "35Rnd_556x45_Velko",
                             "20Rnd_127x55", "10Rnd_127x55")),               "30Rnd_580x42_Mag_F"),
]

# 2040 IRAN: the rifles are AK-103s now, so the magazine is 7.62x39 - the
# source's 6.5 Katiba magazines would otherwise be handed to a rifle that
# cannot take them. The RPK-12 carries the 75-round drum of the same round and
# the SVD its own 7.62x54; both have future builds, so the tier pass takes
# them from here.
_IRAN_MAGS = [
    (lambda m: m.startswith(("150Rnd_762x54_Box", "200Rnd_65x39_cased", "100Rnd_580x42",
                             "150Rnd_93x64")),                                "75Rnd_762x39_Mag_F"),
    (lambda m: m.startswith(("10Rnd_762x54", "Aegis_10Rnd_762x54", "10Rnd_93x64")), "Aegis_10Rnd_762x54_SVD_Red_Mag_F"),
    (lambda m: m.startswith(("30Rnd_65x39_caseless", "30Rnd_580x42", "30Rnd_545x39",
                             "30Rnd_556x45_Stanag", "20Rnd_650x39_Cased",
                             "30Rnd_762x51_slr", "20Rnd_762x51_slr")),         "30Rnd_762x39_Mag_F"),
]

MAG_SWAP = {
    "jmfsb_Iran":      _IRAN_MAGS,
    "jmfsb_China":     _CHINA_MAGS,
    "jmfsb_China_ard": _CHINA_MAGS,
    "jmfsb_CSAT":     _CSAT_MAGS,
    "jmfsb_CSAT_tna": _CSAT_MAGS,
    "jmfsb_PLA_ard":  _PLA_MAGS,
    "jmfsb_PLA_wdl":  _PLA_MAGS,
}


def rule_hit(test, x, c):
    """A rule may look at the thing alone or at the thing and the man."""
    try:
        return test(x, c)
    except TypeError:
        return test(x)


def mag_swap(mag, rules, c=""):
    for test, new_m in rules:
        if rule_hit(test, mag, c):
            return new_m
    return mag


# WHO THE MEN ARE - newfac -> identityTypes[] written on every man. CSAT Iran
# is Iranian in both theatres (user, 2026-08-28): the base game's Altis CSAT
# already is (Head_TK, Persian), its Pacific CSAT is Chinese (Head_Asian).
IDENTITY = {
    "jmfsb_CSAT":     ["LanguagePER_F", "Head_TK", "G_IRAN_default"],
    "jmfsb_CSAT_tna": ["LanguagePER_F", "Head_TK", "G_IRAN_default"],
    # the PLA is Chinese - the base game's Pacific CSAT identity
    "jmfsb_PLA_ard":  ["LanguageCHI_F", "Head_Asian", "G_CIVIL_male"],
    "jmfsb_PLA_wdl":  ["LanguageCHI_F", "Head_Asian", "G_CIVIL_male"],
}


# ---------------------------------------------------------------------------
# UNITS A FACTION FIELDS THAT ITS SOURCE DOES NOT
# ---------------------------------------------------------------------------
# Each entry is either
#   {"kind": "veh", "base": <source class>, "name": <3DEN name>,
#    "crew": <source class of the crew, optional>, "as": <name to build
#    under, optional - default is the base class>, "tex": [...] optional,
#    "props": [<raw config lines, comments allowed>] optional,
#    "why": <one line>}
# or a man built from EXTRA_MAN_BASE[newfac] - this faction's own rifleman -
#   {"kind": "man", "suffix": <class suffix>, "name": <3DEN name>,
#    "backpack": <class, optional>, "add_weapons"/"add_mags"/"add_items":
#    [...] optional, "why": optional}
# Emitted by emit_extras, shared with tools/apply_faction_extras.py.

# A "props" value, because more than one borrowed static needs it.
#
# A mod is free to invent its own editor heading, and RKSL does: every Rapier
# FSC piece carries vehicleClass "RKSL_UK_GBAD" and editorSubcategory
# "RKSLA3_UK_GBAD_SUBCAT" - Ground Based Air Defence, RKSL's own shelf. Our
# copies inherit both and land there instead of with the rest of our statics,
# which is where anyone reaching for a static weapon actually looks.
#
# Same fix, same reason, as addons/antiship: name the vanilla pair and the
# piece files under Turrets. Nothing else about the class changes.
EDEN_TURRET = [
    "// RKSL files these under its own Ground Based Air Defence heading;",
    "// put them with the rest of the statics, under Turrets.",
    'vehicleClass = "Static";',
    'editorSubcategory = "EdSubcat_Turrets";',
]


def raf_extras(rifleman, _uav_man, tubes):
    """What every Russian theatre fields beyond E22's roster: the east drone
    allocation. E22 names its D and A riflemen differently and the SwitchBlade
    tubes come in Desert and Woodland only (alpine takes woodland), so the
    list is built per theatre rather than written three times.
    """
    return [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_%s" % tubes, "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": rifleman, "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_%s" % tubes, "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": rifleman, "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [RAF]",
         "add_items": ["SwitchBlade_300_Tube_%s" % tubes, "SwitchBlade_600_Tube_%s" % tubes],
         "why": "carries the tubes DDT fires"},
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ]


_IDAP = [
    # IDAP's demining Pelican in US hands: one of the three base-game drones
    # the US fields (see NOT_FIELDED) and one no US roster owns.
    {"kind": "veh", "base": "C_IDAP_UAV_06_antimine_F", "name": "AL-6 Pelican (Demining)",
     "crew": "B_UAV_AI", "why": "the demining drone - IDAP's airframe, US kit"},
]
EXTRA_UNITS = {
    "jmfsb_US_JTF_wdl": _IDAP,
    "jmfsb_US_JTF_des": _IDAP,
    "jmfsb_US_JTF_tna": _IDAP,
    "jmfsb_US_JTF_ocp": _IDAP,

    # EAST GETS WHAT THE BASE GAME ONLY GAVE THE WEST, AND THE SWITCHBLADE.
    # The Falcon and the SwitchBlades exist only as B_/I_ classes, so the
    # east versions are ours: the BLUFOR class with side 0 and CSAT's own
    # autopilot in the seat. "as" is the name they are built under, so a
    # CSAT drone is not called jmfsb_CSAT_B_something.
    # 2040 IRAN and the three 2040 RUSSIAS (user, 2026-08-30: "give them
    # drones for 2040"). The same east allocation, each faction's own rifleman
    # crewing the emplaced tubes and carrying them.
    "jmfsb_Iran": [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_Desert", "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": "O_soldier_F", "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_Desert", "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": "O_soldier_F", "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [IRAN]",
         "add_items": ["SwitchBlade_300_Tube_Desert", "SwitchBlade_600_Tube_Desert"],
         "why": "carries the tubes DDT fires"},
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ],
    "jmfsb_Russia": [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_Woodland", "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": "O_R_Soldier_F", "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_Woodland", "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": "O_R_Soldier_F", "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [RUS]",
         "add_items": ["SwitchBlade_300_Tube_Woodland", "SwitchBlade_600_Tube_Woodland"],
         "why": "carries the tubes DDT fires"},
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ],
    "jmfsb_Russia_ard": [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_Desert", "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": "O_R_Soldier_ard_F", "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_Desert", "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": "O_R_Soldier_ard_F", "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [RUS]",
         "add_items": ["SwitchBlade_300_Tube_Desert", "SwitchBlade_600_Tube_Desert"],
         "why": "carries the tubes DDT fires"},
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ],
    "jmfsb_Russia_arc": [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_Woodland", "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": "CF_O_R_Soldier_F", "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_Woodland", "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": "CF_O_R_Soldier_F", "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [RUS]",
         "add_items": ["SwitchBlade_300_Tube_Woodland", "SwitchBlade_600_Tube_Woodland"],
         "why": "carries the tubes DDT fires"},
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ],
    # 2040 CHINA (user, 2026-08-30: "make sure there's drones") - the east
    # allocation CSAT carries, with the launch tubes in each theatre's colour
    # and the tropical / desert rifleman crewing the emplaced ones.
    "jmfsb_China": [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_Woodland", "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": "O_T_Soldier_F", "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_Woodland", "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": "O_T_Soldier_F", "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [PLA]",
         "add_items": ["SwitchBlade_300_Tube_Woodland", "SwitchBlade_600_Tube_Woodland"],
         "why": "carries the tubes DDT fires"},
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ],
    "jmfsb_China_ard": [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_Desert", "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": "Aegis_O_C_D_Soldier_F", "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_Desert", "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": "Aegis_O_C_D_Soldier_F", "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [PLA]",
         "add_items": ["SwitchBlade_300_Tube_Desert", "SwitchBlade_600_Tube_Desert"],
         "why": "carries the tubes DDT fires"},
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ],
    "jmfsb_CSAT": [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east - no base-game east version exists"},
        {"kind": "veh", "base": "O_T_UAV_04_CAS_F", "name": "KH-3A Fenghuang",
         "why": "OPF_T_F's CAS drone, fielded by OPF_F's order of battle"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_Woodland", "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": "O_Soldier_F", "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_Woodland", "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": "O_Soldier_F", "why": "emplaced"},
        # THE MAN WHO FIRES IT. Drongo's Drone Tweaks launches a SwitchBlade
        # for the AI from the tube ITEM a man carries (its ddtClassesFPVAT);
        # a faction with the airframe and nobody carrying a tube never fires
        # one. The tubes are CBA_MiscItems, hence items[] rather than mags.
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [CSAT]",
         "add_items": ["SwitchBlade_300_Tube_Woodland", "SwitchBlade_600_Tube_Woodland"],
         "why": "carries the tubes DDT fires"},
        # RKSL, EAST: the Aeroshark and its ground station. Class names from
        # the 2026-08-27 in-game dump (D:\work\rksl_classes.txt) - the PBOs
        # are obfuscated. The Watchkeeper the allocation named is not in the
        # load order, so it is not here.
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ],
    # The Pacific CSAT is the same army in green: what it fields beyond
    # OPF_T_F's own roster is the same list (the SwitchBlade tubes come in
    # woodland only, which suits it).
    "jmfsb_CSAT_tna": [
        {"kind": "veh", "base": "B_T_UAV_03_dynamicLoadout_F", "as": "O_UAV_03_dynamicLoadout_F",
         "name": "MQ-12 Falcon", "crew": "O_UAV_AI", "why": "the Falcon, in the east"},
        {"kind": "veh", "base": "B_SwitchBlade_300", "as": "O_SwitchBlade_300", "name": "SwitchBlade 300",
         "crew": "O_UAV_AI", "why": "loitering munition - AI only, east and ind"},
        {"kind": "veh", "base": "B_SwitchBlade_600", "as": "O_SwitchBlade_600", "name": "SwitchBlade 600",
         "crew": "O_UAV_AI", "why": "the anti-armour one"},
        {"kind": "veh", "base": "B_SwitchBlade_300_LaunchTube_Woodland", "as": "O_SwitchBlade_300_LaunchTube",
         "name": "SwitchBlade 300 Launch Tube", "crew": "O_T_Soldier_F", "why": "emplaced"},
        {"kind": "veh", "base": "B_SwitchBlade_600_LaunchTube_Woodland", "as": "O_SwitchBlade_600_LaunchTube",
         "name": "SwitchBlade 600 Launch Tube", "crew": "O_T_Soldier_F", "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [CSAT]",
         "add_items": ["SwitchBlade_300_Tube_Woodland", "SwitchBlade_600_Tube_Woodland"],
         "why": "carries the tubes DDT fires"},
        {"kind": "veh", "base": "rksla3_aeroshark_opfor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, east"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_o", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, east paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_o", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, east paint"},
        # THE RAPIER FSC BATTERY (user, 2026-08-30) - launcher, its Blindfire
        # fire-control radar and the Dagger surveillance radar. RKSL files all
        # three under UK_ARMED_FORCES and crews them with NATO's, so each is
        # renamed into this faction and given the EAST autopilot: an unmanned
        # radar with no crew line answers to whoever the mod put in it.
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "as": "O_Rapier_FSC_Launcher",
         "name": "Rapier FSC Launcher", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "the battery's launcher"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "as": "O_Rapier_FSC_Blindfire",
         "name": "Rapier FSC Blindfire FCR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "as": "O_Rapier_FSC_Dagger",
         "name": "Rapier FSC Dagger SR", "crew": "O_UAV_AI", "props": EDEN_TURRET,
         "why": "its surveillance radar"},
    ],

    # RUSSIA: the east drone allocation in full, per theatre - see raf_extras.
    "jmfsb_RAF_wdl": raf_extras("E22_O_RAF_Soldier_F",   "E22_O_RAF_Soldier_UAV_F",   "Woodland"),
    "jmfsb_RAF_ard": raf_extras("E22_O_RAF_D_Soldier_F", "E22_O_RAF_D_Soldier_UAV_F", "Desert"),
    "jmfsb_RAF_alp": raf_extras("E22_O_RAF_A_Soldier_F", "E22_O_RAF_A_Soldier_UAV_F", "Woodland"),

    # TIER 0 IS A SINGLE FPV, DAYLIGHT, CRUDE - the bottom row of the capability
    # table in docs/faction_builder_handoff.md.
    #
    # ONE AIRFRAME, AND ONLY ANTI-PERSONNEL. The insurgents at tier 1 field an
    # AP and an AT bird from one supplier; a criminal network fields whatever
    # it could buy, and having an answer to armour is what it does not have.
    #
    # NO FPV LEFT. The insurgents took KVN until the KVN mod left the load
    # order, the Syndikat took Crocus until that mod left too (2026-08-28,
    # DROP_TESTS). The IED Pelican is tier 0's drone now.
    #
    # Their IED quad and the two UGV Saifs come with the roster already and are
    # left alone: an IED strapped to a hobby drone is exactly tier 0, and it is
    # what the faction is known for.
    "jmfsb_Syndikat": [
        # THE IED PELICAN, tier 0's other drone - see jmfsb_Insurgents.
        {"kind": "veh", "base": "jmfsb_uas_UAV_06_IED_I", "as": "UAV_06_IED", "name": "AL-6 Pelican (IED)",
         "why": "a cargo quad with a charge where the crate was"},
        {"kind": "man", "suffix": "UAV_06_IED_Operator", "name": "Pelican IED Operator [SYN]",
         "backpack": "jmfsb_uas_UAV_06_IED_backpack_I"},
    ],

    # TIER 1 IS LOITERING MUNITIONS, FIBER FPV AND NIGHT - the capability table
    # in docs/faction_builder_handoff.md. It is NOT tier 2's multi-ship
    # recon-strike, so there is no recon quad fleet, no UGV, no cargo lift and
    # no second FPV family: a proxy force gets what one patron sends.
    #
    # NO _TI VARIANTS. Every one of these has a thermal-seeker twin in the mod;
    # thermal is the tier 3 marker.
    #
    # Their own Opf_I_I_UAV_02_IED_lxWS stays as it is - a crude IED quad is
    # exactly tier 0, and keeping it is what makes the new kit read as an
    # upgrade rather than a replacement.
    "jmfsb_Insurgents": [
        {"kind": "veh", "base": "I_SwitchBlade_300", "name": "SwitchBlade 300",
         "why": "the loitering munition - reach without an air force"},
        {"kind": "veh", "base": "I_SwitchBlade_300_LaunchTube_Desert",
         "name": "SwitchBlade 300 Launch Tube",
         "why": "emplaced, because they have no vehicle to fire it from"},
        {"kind": "veh", "base": "I_SwitchBlade_600", "name": "SwitchBlade 600",
         "why": "the anti-armour one - what KVN used to be for"},
        {"kind": "veh", "base": "I_SwitchBlade_600_LaunchTube_Desert", "name": "SwitchBlade 600 Launch Tube",
         "why": "emplaced"},
        {"kind": "man", "suffix": "SwitchBlade_Operator", "name": "SwitchBlade Operator [INS]",
         "add_items": ["SwitchBlade_300_Tube_Desert", "SwitchBlade_600_Tube_Desert"],
         "why": "carries the tubes DDT fires - see jmfsb_CSAT"},
        # The KVN AP/AT pair and their operators were here - the fiber FPV,
        # and the only thing the insurgents had that killed armour. Gone with
        # the KVN mod; the SwitchBlade is what is left of their reach.
        # THE IED PELICAN - jmfsb_uas builds the airframe (a cargo quad with a
        # charge where the crate was) and registers it with DDT as an FPV;
        # this is the faction fielding it and the man who carries it.
        {"kind": "veh", "base": "jmfsb_uas_UAV_06_IED_I", "as": "UAV_06_IED", "name": "AL-6 Pelican (IED)",
         "why": "the cheap answer to everything - tier 1"},
        {"kind": "man", "suffix": "UAV_06_IED_Operator", "name": "Pelican IED Operator [INS]",
         "backpack": "jmfsb_uas_UAV_06_IED_backpack_I"},
        # RKSL, IND. The allocation said "ind side"; of the two IND factions
        # built here this is the organised one, so it gets the lot - the
        # Aeroshark, the Shadow, the Hermes, the Rapier battery and the
        # ground stations. Names from the 2026-08-27 dump. RKSL's own side
        # numbers are unreliable (the "infor" Aeroshark says side 0, the
        # "opfor" Shadow says faction BLU_F) - ours are written on top, and
        # the Shadow and the Rapier get an IND autopilot because the mod
        # crews them with NATO's.
        {"kind": "veh", "base": "rksla3_aeroshark_infor", "name": "Aeroshark Mini UAV",
         "why": "RKSL's mini tactical UAV, ind"},
        {"kind": "veh", "base": "rksla3_uav_rq7shadow_01_insurg", "name": "RQ-7 Shadow 200",
         "crew": "I_UAV_AI", "why": "RKSL's tactical UAV - ind only"},
        {"kind": "veh", "base": "rksla3_uav_h450_3", "name": "Hermes 450",
         "why": "RKSL's Hermes - ind only"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Launcher", "name": "Rapier FSC Launcher",
         "crew": "I_UAV_AI", "props": EDEN_TURRET,
         "why": "RKSL's Rapier SAM - ind only"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Blindfire", "name": "Rapier FSC Blindfire FCR",
         "crew": "I_UAV_AI", "props": EDEN_TURRET,
         "why": "the Rapier's fire-control radar"},
        {"kind": "veh", "base": "RKSLA3_Static_Rapier_FSC_Dagger", "name": "Rapier FSC Dagger Search Radar",
         "crew": "I_UAV_AI", "props": EDEN_TURRET,
         "why": "the Rapier's search radar"},
        {"kind": "veh", "base": "rksla3_uav_gdt_sa_i", "name": "UAV Ground Data Terminal",
         "why": "RKSL's GDT, ind paint"},
        {"kind": "veh", "base": "rksla3_uav_wkshelter_sa_i", "name": "UAV Ground Control Station",
         "why": "RKSL's GCS shelter, ind paint"},
    ],
}

# The man every operator is built from: this faction's own rifleman, so each
# inherits the faction's rifle and tier ammunition rather than the source's.
EXTRA_MAN_BASE = {
    "jmfsb_Iran": "O_soldier_F",
    "jmfsb_Russia": "O_R_Soldier_F",
    "jmfsb_Russia_ard": "O_R_Soldier_ard_F",
    "jmfsb_Russia_arc": "CF_O_R_Soldier_F",
    # 2040 China: the drone operator and the SwitchBlade man are this
    # faction's own rifleman, so they turn up in its uniform like everyone
    # else. Without an entry here no extra man is built at all.
    "jmfsb_China": "O_T_Soldier_F",
    "jmfsb_China_ard": "Aegis_O_C_D_Soldier_F",
    "jmfsb_CSAT": "O_Soldier_F",
    "jmfsb_CSAT_tna": "O_T_Soldier_F",
    "jmfsb_PLA_ard": "O_Soldier_F", "jmfsb_PLA_wdl": "O_Soldier_F",
    "jmfsb_US_JTF_wdl": "B_W_Soldier_F", "jmfsb_US_JTF_tna": "B_T_Soldier_F",
    "jmfsb_US_JTF_des": "B_D_Soldier_lxWS", "jmfsb_US_JTF_ocp": "B_D_Soldier_lxWS",
    "jmfsb_Marine_wdl": "EF_B_Marine_R_Wdl", "jmfsb_Marine_des": "EF_B_Marine_R_Des",
    "jmfsb_EUDF": "B_soldier_F", "jmfsb_EUDF_wdl": "B_W_Soldier_F",
    "jmfsb_EUDF_des": "B_D_Soldier_lxWS", "jmfsb_EUDF_tna": "B_T_Soldier_F",
    "jmfsb_EUDF_arc": "CF_B_Soldier_F",
    "jmfsb_Turkey": "Athena_O_T_Soldier_F",
    "jmfsb_AAF": "I_soldier_F", "jmfsb_LDF": "I_E_Soldier_F",
    "jmfsb_FIA": "B_G_Soldier_F", "jmfsb_FIA_ind": "I_G_Soldier_F",
    "jmfsb_Insurgents": "I_G_Soldier_F",
    "jmfsb_Syndikat": "I_C_Soldier_Bandit_7_F",
}

HDR = ("// Generated by tools/gen_us_factions.py - re-run rather than hand-edit.\n"
       "//\n")


# ---------------------------------------------------------------------------
# FA TIER AMMUNITION
# ---------------------------------------------------------------------------
# A faction at tier 2 or above carries the FA round of its tier - every
# vanilla magazine with an FA equivalent is swapped for that round's _tN
# variant. A magazine with no FA equivalent is left alone: FA does not cover
# grenades, smoke, chemlights or pistol ammunition, and most of what a
# faction carries is exactly that.
#
# THE SWAP IS SAFE BECAUSE fa_tiers PUTS EVERY TIER MAGAZINE IN THE WELLS ITS
# BASE MAGAZINE SITS IN (fa_tiers/CfgMagazineWells.hpp). Not because of
# inheritance: a weapon knows its magazines by NAME, through magazines[] and
# CfgMagazineWells, and FA_b_30Rnd_65_EPR_t3 descending from the vanilla
# magazine does nothing for that. Believing otherwise is how a whole faction
# spawned with magazines it could not chamber.
#
# WHICH FA ROUND, WHEN SEVERAL DESCEND FROM THE SAME VANILLA MAGAZINE:
#
#   1. Never one from an fa_antidrone* addon. Those are proximity-airburst
#      counter-UAS rounds - Mk367 PAB and friends - and issuing them as ball
#      ammunition would arm the whole army against drones and nothing else.
#   2. The faction's own prefix first - FA_b_ (NATO) for the US and the
#      Marines, FA_i_ (AAF) for the independents; see FA_PREFER.
#   3. Anything still tied is named in PICK below, with the reason.
FA_SKIP_ADDONS = ("fa_antidrone",)

PICK = {
    # THE 5.45 AK-12 ROUND (2026-08-30). Aegis builds three futures of it -
    # 7N44, 7N48 and 7U5 - and three candidates with no FA_o_ among them is a
    # tie the chooser cannot break, so 2040 Russia was issued base-game 5.45
    # while every other faction had a future round. 7N44 is the standard AP
    # load and the one E22's Russia carried before the mod left; the other two
    # stay available in the arsenal.
    "30Rnd_545x39_AK12_Mag_F": "FA_Aegis_30Rnd_545x39_7N44",
    # M80A2 HV is a hybrid case that "feeds existing 7.62 wells"; XM751 CTEP is
    # cased-telescoped and "needs rated well", so it is not a drop-in.
    "20Rnd_762x51_Mag": "FA_b_20Rnd_762_M80A2_HV",
    # The other 40mm rounds are a different NATURE - smoke, EMP, decoy, UGS,
    # jammer. Only the TBK is HE, so only it replaces an HE shell.
    "1Rnd_HE_Grenade_shell": "FA_b_1Rnd_40mm_Mk389_TBK",
    "3Rnd_HE_Grenade_shell": "FA_b_3Rnd_40mm_Mk389_TBK",
    # HEAT for HEAT; the others are guided or anti-air.
    "MRAWS_HEAT_F": "FA_MRAWS_HEAT758_TT",
    # HE for HE; AD and DP are other natures.
    "1Rnd_RC40_HE_shell_RF": "FA_1Rnd_RC40_HEP",
    # THE ASh-12 (CSAT Iran, 2026-08-28): fa_rf builds three 12.7x55 loads and
    # nothing says which is standard. 7N52 Molot - transonic tungsten AP -
    # is the general-issue round; 7U13/7U14 are the subsonic suppressed loads.
    "20Rnd_127x55_Mag_RF": "FA_rf_20Rnd_127x55_7N52",
    "10Rnd_127x55_Mag_RF": "FA_rf_10Rnd_127x55_7N52",
    # THE NAVID'S BELT - fa_ammo's Type40 belt (2026-08-28), the Cyrus's round belted.
    "150Rnd_93x64_Mag": "FA_o_150Rnd_93x64_Type40",
    # CSAT'S RIFLE MAGAZINE IS 6.2, NOT 6.5. The green caseless magazine has
    # seven FA descendants - three Type 4x in 6.5 and four DBP in 6.2 - so it
    # was ambiguous and got no substitution at all, leaving the whole faction
    # on vanilla ammunition. DBP-25 is the "caseless standard": DBP-26 is
    # tungsten AP, DBP-88B is the heavy DMR/GPMG load, and DBJ-25 PAB is a
    # proximity airburst driven by the anti-drone fuze registry.
    "30Rnd_65x39_caseless_green": "FA_o_30Rnd_62_DBP25",
    # The leaders' tracer magazine has NO FA descendant of its own, so it fell
    # through the map entirely and left squad and team leaders on vanilla
    # ammunition while their riflemen were on DBP-25. Green to match the round
    # CSAT already fires.
    "30Rnd_65x39_caseless_green_mag_Tracer": "FA_o_30Rnd_62_DBP25_T_Green",
    # ARBITRARY, AND FLAGGED AS SUCH. Both Titan variants are the right nature
    # and nothing in the configs says which the US issues. Change the line and
    # re-run.
    "Titan_AT": "FA_Titan_AT_BGM185_Broadsword",
    "Titan_AA": "FA_Titan_AA_MIM165_Sentry",
    # 2026-09-27 (user: "make sure all 2040 factions have future ammo"). The faction configs were swapped in
    # place to these; they are here so a re-run issues the same. Tracer magazines have no FA descendant of their
    # own, so without an entry they kept base-game rounds; the pistol/SMG/DMR ones are magazines made that day.
    "30Rnd_762x39_Mag_F": "FA_o_30Rnd_762x39_7N47_CT",
    "30Rnd_762x39_Mag_Tracer_F": "FA_o_30Rnd_762x39_7N47_CT_T_Yellow",
    "30Rnd_580x42_Mag_F": "FA_o_30Rnd_580x42_DBP39_CT",
    "30Rnd_580x42_Mag_Tracer_F": "FA_o_30Rnd_580x42_DBP39_CT_T_Green",
    "30Rnd_556x45_Stanag_red": "FA_b_30Rnd_556_Mk327_HV_T_Red",
    "30Rnd_65x39_caseless_mag_Tracer": "FA_b_30Rnd_65_EPR_T_Red",
    "30Rnd_65x39_caseless_khaki_mag_Tracer": "FA_b_30Rnd_65_EPR_Khaki_T_Red",
    "30Rnd_65x39_caseless_black_mag_Tracer": "FA_b_30Rnd_65_EPR_Black_T_Red",
    "EF_30Rnd_65x39_caseless_coy_mag_Tracer": "FA_b_30Rnd_65_EPR_T_Red",
    "16Rnd_9x21_Mag": "FA_b_16Rnd_9x21_Mk424_AP",
    "jmfsb_weapons_17Rnd_9x21_Mag": "FA_b_17Rnd_9x21_Mk424_AP",
    "30Rnd_9x21_Mag_SMG_02": "FA_b_30Rnd_9x21_SMG_02_Mk424_AP",
    "30Rnd_9x21_Mag_SMG_02_Tracer_Red": "FA_b_30Rnd_9x21_SMG_02_Mk424_AP",
    "jmfsb_weapons_40Rnd_9x21_Gepard_Mag_F": "FA_b_40Rnd_9x21_Gepard_Mk424_AP",
    "17Rnd_9x19_Mag_RF": "FA_rf_17Rnd_9x19_Mk422_AP",
    "33Rnd_9x19_Mag_Tan_RF": "FA_rf_33Rnd_9x19_Mk422_AP",
    "6Rnd_45ACP_Cylinder": "FA_b_6Rnd_45ACP_Mk421",
    "10Rnd_762x54_Mag": "FA_o_10Rnd_762x54_Ball_HV",
    "7Rnd_408_Mag": "FA_b_7Rnd_408_Mk240",
    "RPG32_F": "FA_RPG32_PG32V2",
    "Vorona_HEAT": "FA_Vorona_9M135M",
    "MRAWS_HEAT55_F": "FA_MRAWS_HEAT665_CS",
}


# ---------------------------------------------------------------------------
# VEHICLE CAMO
# ---------------------------------------------------------------------------
# Keyed by faction, then SOURCE class -> {"tex": [...], "sel": [...]}: the
# paint a vehicle spawns in, written as hiddenSelectionsTextures. EMPTY since
# 2026-08-27: jmfsb_CSAT is OPF_F in its own hex again and jmfsb_CSAT_tna is
# OPF_T_F in its own green-hex, so nothing needs repainting. The mechanism
# stays for the day something does - the array order is the hiddenSelections
# order, and a swap paints the turret with the hull.
VEH_TEX = {}

# THE PLA'S PAINT. Each PLA vehicle offers TextureSources; the theatre picks one
# by name, first match wins - the arid faction the desert scheme, the woodland
# one the wood digital. The mod randomises between them at spawn (textureList),
# so the emitter also writes textureList[] = {} (the "notl" flag). Helicopters
# and jets offer no camo scheme and are left as the mod paints them.
_PLA_CAMO = {
    "jmfsb_PLA_ard": ("Desertcamo", "desert", "Desert", "khaki", "Khaki"),
    "jmfsb_PLA_wdl": ("Woodcamo2", "woodcamo2", "Woodcamo", "woodcamo", "Woodland", "Woodland2", "Woodland_2", "Olive"),
}


def pla_camo():
    for fac, prefs in _PLA_CAMO.items():
        for c, rec in PLA_INDEX.items():
            srcs = rec.get("textureSources") or {}
            pick = next((n for n in prefs if n in srcs), None)
            if not pick:
                continue
            tex = ["\\" + t.lstrip("\\") for t in srcs[pick]]
            VEH_TEX.setdefault(fac, {})[c] = {"tex": tex, "sel": rec.get("hiddenSelections"), "notl": True}


pla_camo()

# THE JTF'S PAINT (user, 2026-08-28, "with proper camo"). The base game paints
# the Ghost Hawk four ways - NATO grey, BLUFOR camo, CTRG sand and tropic - the
# Huron green or black, the Prowler sand or olive. Woodland flies camo JMSB
# Hawks, tropical the tropic ones, both with green Hurons and olive Prowlers;
# desert and OCP fly sand Ghost Hawks and black Hurons (there is no desert
# Huron) and drive sand Prowlers. Paths as the dump lists them for the
# variants (B_Heli_Transport_01_camo_F, B_CTRG_Heli_Transport_01_sand_F, ...).
_GH_B = "\\A3\\Air_F_Beta\\Heli_Transport_01\\Data\\Heli_Transport_01_"
_GH_X = "\\A3\\Air_F_Exp\\Heli_Transport_01\\Data\\Heli_Transport_01_"
_HU = "\\a3\\air_f_heli\\heli_transport_03\\data\\heli_transport_03_"
_LSV = "\\A3\\Soft_F_Exp\\LSV_01\\Data\\NATO_LSV_"
_TITAN = ["\\A3\\weapons_f_beta\\launchers\\titan\\data\\launcher_co.paa",
          "\\A3\\weapons_f_beta\\launchers\\titan\\data\\tubem_co.paa"]


def _ghosthawk(kind):
    if kind == "BLUFOR":
        return [_GH_B + "ext01_BLUFOR_CO.paa", _GH_B + "ext02_BLUFOR_CO.paa",
                _GH_B + "ext01_add_BLUFOR_co.paa", _GH_B + "DAP_BLUFOR_CO.paa"]
    return [_GH_X + "ext01_%s_CO.paa" % kind, _GH_X + "ext02_%s_CO.paa" % kind,
            _GH_B + "ext01_add_%s_CO.paa" % kind, _GH_B + "DAP_%s_CO.paa" % kind]


def _huron(kind):
    sfx = "_black" if kind == "black" else ""
    return [_HU + "ext01%s_co.paa" % sfx, _HU + "ext02%s_co.paa" % sfx]


def _prowler(kind):
    return [_LSV + "0%d_%s_CO.paa" % (i, kind) for i in (1, 2, 3)] + [_LSV + "Adds_%s_CO.paa" % kind]


# faction -> (Ghost Hawk, Huron, Prowler)
_JTF_PAINT = {"jmfsb_US_JTF_wdl": ("BLUFOR", "green", "olive"),
              "jmfsb_US_JTF_tna": ("tropic", "green", "olive"),
              "jmfsb_US_JTF_des": ("sand", "black", "sand"),
              "jmfsb_US_JTF_ocp": ("sand", "black", "sand")}


def jtf_paint():
    for fac, (gh, hu, lsv) in _JTF_PAINT.items():
        vt = VEH_TEX.setdefault(fac, {})
        for c in ("B_Heli_Transport_01_F", "B_Heli_Transport_01_unarmed_F", "B_Heli_Transport_01_pylons_F"):
            vt[c] = {"tex": _ghosthawk(gh), "notl": True}
        for c in ("B_Heli_Transport_03_F", "B_Heli_Transport_03_unarmed_F"):
            vt[c] = {"tex": _huron(hu), "notl": True}
        for c in ("B_LSV_01_armed_F", "B_LSV_01_unarmed_F", "B_T_LSV_01_armed_F", "B_T_LSV_01_unarmed_F"):
            vt[c] = {"tex": _prowler(lsv), "notl": True}
        for c in ("B_LSV_01_AT_F", "B_T_LSV_01_AT_F"):
            # the AT one's launcher and tube are two more selections
            vt[c] = {"tex": _prowler(lsv) + _TITAN, "notl": True}


jtf_paint()

_CHEETAH_OLIVE = ["A3\\Armor_F_exp\\APC_Tracked_01\\Data\\apc_tracked_01_aa_body_olive_co.paa",
                  "A3\\Armor_F_exp\\APC_Tracked_01\\Data\\mbt_01_body_olive_co.paa",
                  "A3\\Armor_F_exp\\APC_Tracked_01\\Data\\apc_tracked_01_aa_tower_olive_co.paa",
                  "a3\\Armor_F\\Data\\camonet_NATO_Green_CO.paa"]


# THE EUDF'S PAINT (2026-08-31). Same three transports as the JTFs, in each
# theatre's own scheme - the airframes come in through _EU_HELI, which means
# they arrive in whatever the base game painted them unless they are told.
# There is no white Ghost Hawk, so the arctic theatre keeps the plain one.
_EU_PAINT = {"jmfsb_EUDF": "BLUFOR", "jmfsb_EUDF_wdl": "BLUFOR",
             "jmfsb_EUDF_tna": "tropic", "jmfsb_EUDF_des": "sand"}


def eu_paint():
    """The temperate EUDF's Cheetah in NATO Pacific's olive, and each
    theatre's Ghost Hawks in its own scheme."""
    vt = VEH_TEX.setdefault("jmfsb_EUDF", {})
    vt["B_APC_Tracked_01_AA_F"] = {"tex": _CHEETAH_OLIVE, "notl": True}
    for fac, kind in _EU_PAINT.items():
        v = VEH_TEX.setdefault(fac, {})
        for c in ("B_Heli_Transport_01_F", "B_Heli_Transport_01_unarmed_F",
                  "B_Heli_Transport_01_pylons_F"):
            v[c] = {"tex": _ghosthawk(kind), "notl": True}


eu_paint()


# WHAT THE EDITOR CALLS IT (user, 2026-08-28). A loaded mod renames the base
# game's AMV-7 "Badger IFV" and E22 calls its M-ATVs "Hunter"; the JTFs say
# Marshall and M-ATV. Exact names first, then the Hunter family - never the
# Hunter-SP, which is a loitering munition.
# PREFIX RULES, NOT EXACT NAMES (user, 2026-08-31: "rename all badgers
# marshall"). The exact-name map renamed the IFV and the ATGM and left the
# Command, Medical and Mortar variants saying Badger; the variant suffix rides
# along now, and a variant nobody has thought of yet is covered too.
RENAME = {"Badger IFV": "AMV-7 Marshall", "Hunter": "M-ATV"}
# THE EUDF DOES NOT FLY AMERICAN (user, 2026-08-31: "the helos, replace the
# american names"). Applied to the EU factions only - the JTFs keep the JMSB
# Hawk and the Comanche - and by prefix, so "(Unarmed)" and "(Stub Wings)"
# ride along. The Super Cougar and the Merlin already read European.
EU_RENAME = {"UH-80 Ghost Hawk": "NH90 TTH",
             "RAH-66J Comanche": "Tiger HAD (Naval)",
             "RAH-66 Comanche":  "Tiger HAD"}

# ALiVE'S AA PICKER READS THE NAME (user, 2026-08-28: "the custom factions AA
# did not show up in the ALiVE selection window").
#
# ALiVE_fnc_listFactionAAUnits will not list a vehicle as anti-air unless its
# CLASS NAME or its DISPLAY NAME contains one of the markers below, or it
# inherits one of six vanilla AA base classes. That is deliberate on ALiVE's
# side - the behavioural test alone (a high turret with airLock ammo) also
# catches every 30 mm IFV - but it means an AA system whose name says neither
# "AA" nor a cold-war codename is invisible to the picker. The PLA's PGZ09 and
# HQ6A, QAV's Guardian, RF's AA pickup and E22's Skynex all fall in that hole.
#
# ALiVE is read-only reference here, so the fix is on our side: the classes
# below say "(Anti-Air)" in the editor, which is both true and a marker ALiVE
# matches. Appended only when nothing in the name is a marker already, so it
# never doubles up and the vehicles ALiVE already finds are left alone.
_ALIVE_AA_MARKERS = ("_aa_", "_aa.", "aa_pod", "aapod", "anti_air", "anti-air", "antiair",
                     "_sam_", "stinger", "igla", "avenger", "tunguska", "shilka", "zsu",
                     "zu23", "zu_23", "zu-23", "praetorian", "patriot", "centurion",
                     "pantsir", "tigris", "bardelas", "buk", "manpad", " tor ", "_tor_",
                     "rapier", "starstreak", "strela", "roland", "2s6")
# THE GAME'S OWN ANSWER FIRST. Anything the dump files under the AA editor
# subcategory IS air defence - that is what 3DEN sorts it as, so it needs no
# list here and nothing new can be missed (the EF M-ATV LAAD went unnoticed
# exactly that way). The names below are the fallback for a vehicle whose
# subcategory the dump did not resolve - the PLA mod's, merged from
# work/pla_vehicles.json rather than read from the dump.
AA_SUBCATEGORY = "EdSubcat_AAs"
_AA_SYSTEMS = {"o_pgz09_aa", "o_pgz09_ty90", "hq6a",                     # PLA mod
               "apc_wheeled_01_shorad_qav", "b_t_apc_wheeled_01_shorad_qav"}   # QAV Guardian
_AA_SUBSTR = ("pickup_aat",          # RF's Ram 1500 (AA), every side's copy
              "_aaa_system_")        # E22's ADS-2 Skynex


def is_aa_system(cls, subcat=""):
    if subcat == AA_SUBCATEGORY:
        return True
    c = cls.lower()
    return c in _AA_SYSTEMS or any(k in c for k in _AA_SUBSTR)


def display(cls, name, subcat="", fac=None):
    # The faction's own table first, then the mod-wide one. Longest first, so
    # a name that is a prefix of another cannot win first.
    for table in ((EU_RENAME,) if fac in EU_FACTIONS else ()) + (RENAME,):
        hit = False
        for _old in sorted(table, key=len, reverse=True):
            # " " and not "-": never the Hunter-SP, a loitering munition.
            if name == _old or name.startswith(_old + " "):
                name = table[_old] + name[len(_old):]
                hit = True
                break
        if hit:
            break
    # see _ALIVE_AA_MARKERS: make the air defence findable by name. A name that
    # already says "(AA)" - RF's Ram 1500 - has it SPELLED OUT rather than a
    # second bracket bolted on; anything else gets the suffix.
    if is_aa_system(cls, subcat) and not any(m in (cls + " " + name).lower() for m in _ALIVE_AA_MARKERS):
        if name.endswith("(AA)"):
            name = name[:-len("(AA)")].rstrip() + " (Anti-Air)"
        else:
            name += " (Anti-Air)"
    return name


def fa_map(addons_dir, prefer="FA_b_"):
    """vanilla magazine -> the FA magazine a tiered unit should carry.

    `prefer` is the FA prefix that wins a tie - FA_b_ (NATO) by default,
    FA_i_ (AAF) for the independents; see FA_PREFER.
    """
    import glob as _glob
    cand = {}
    for mp in _glob.glob(os.path.join(addons_dir, "fa_*", "CfgMagazines.hpp")):
        src = os.path.basename(os.path.dirname(mp))
        if src.startswith(FA_SKIP_ADDONS):
            continue
        txt = io.open(mp, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"^\s*class (FA_[A-Za-z0-9_]+)\s*:\s*([A-Za-z0-9_]+)",
                             txt, re.M):
            child, parent = m.group(1), m.group(2)
            if parent.startswith("FA_") or "_T_" in child:
                continue          # tracer variants are the same round
            cand.setdefault(parent, []).append(child)

    out = {}
    for van, lst in cand.items():
        if van in PICK:
            out[van] = PICK[van]
            continue
        mine = [c for c in lst if c.startswith(prefer)]
        if len(mine) > 1:
            # THE INDEPENDENTS' ROUNDS COME IN THREE NATURES per magazine -
            # AF556_HV, AF556C_CT, AF556P_AP - and a tie is no pick at all.
            # The caseless-telescoped round is the standard issue, the same
            # call PICK makes for CSAT's DBP-25; HV is the fallback. E22's
            # 5.45 comes as 7N44 (the standard), 7N48 and 7U5 (subsonic).
            for nature in ("_CT", "_HV", "_7N44"):
                std = [c for c in mine if c.endswith(nature)]
                if len(std) == 1:
                    mine = std
                    break
            if len(mine) > 1:
                # JCA's PMAG comes plain, _XM891_CTEP and _Mk332_AP: the
                # plain one is the standard, and it is the one the others
                # are named after.
                shortest = min(mine, key=len)
                if all(c.startswith(shortest) for c in mine):
                    mine = [shortest]
        blue = [c for c in lst if not c.startswith("FA_i_")]
        if len(mine) == 1:
            out[van] = mine[0]
        elif len(blue) == 1:
            out[van] = blue[0]
        elif len(lst) == 1:
            out[van] = lst[0]

    # A PICK ENTRY IS AUTHORITATIVE EVEN IF NOTHING INHERITS FROM THE VANILLA
    # MAGAZINE. The loop above only walks magazines that have FA descendants;
    # CSAT's tracer magazine has none, so its mapping would never have been
    # reached and its squad leaders would have quietly kept vanilla rounds.
    for van, fa in PICK.items():
        out.setdefault(van, fa)
    return out, cand


# ---------------------------------------------------------------------------
# FACTION TIER
# ---------------------------------------------------------------------------
# Which FA tier a faction's ammunition is drawn from. 3 is the FA round as
# built and is the default; 4 is peer+, the edge nobody else has.
# Tier 1 and 0 are base game ammunition. gen_fa_tiers generates nothing below
# t2 - "the FA round IS tier 3" and there is no FA round at all down here - so a
# tier 1 faction gets NO substitution and keeps what its source issues. Asking
# for _t1 would name magazines that were never built.
TIER = {"jmfsb_CSAT": 4, "jmfsb_CSAT_tna": 4,
        # PEER AND PEER+ (user, 2026-08-30): "this is a peer tier, Iran is a
        # peer tier, and China is peer plus". China alone buys from the t4
        # shelf; Iran and all three Russias are t3.
        "jmfsb_China": 4, "jmfsb_China_ard": 4,
        "jmfsb_Iran": 3,
        "jmfsb_Russia": 3, "jmfsb_Russia_ard": 3, "jmfsb_Russia_arc": 3,
        "jmfsb_PLA_ard": 4, "jmfsb_PLA_wdl": 4,    # peer+ (user, 2026-08-28)
        # Russia at peer (t3): the E22 kit is current-generation, the
        # depth and procurement freedom of t4 is CSAT's alone. Change here.
        "jmfsb_RAF_wdl": 3, "jmfsb_RAF_ard": 3, "jmfsb_RAF_alp": 3,
        "jmfsb_AAF": 2, "jmfsb_LDF": 2,
        "jmfsb_FIA": 1, "jmfsb_FIA_ind": 1,
        "jmfsb_Insurgents": 1, "jmfsb_Syndikat": 0}
TIER["jmfsb_Turkey"] = 4   # peer+ (user, 2026-08-31: "make them peer+")
TIER["jmfsb_GEN"] = 2      # police, not an army - and its kit is forced anyway
DEFAULT_TIER = 3

# EDITOR CATEGORIES (user, 2026-08-28: "only need Men (Special Forces) and Men
# (Story); the rest can be removed - if the unit is unique, move it to just
# Men"; "yes to SF" for the mods' recon sets). Every man lands in one of three
# 3DEN subcategories. A man in any other subcategory is a DUPLICATE when a man
# in plain Men of the same source faction has the same displayName - CSAT's
# urban-camo and African copies, RF's QRF men - and is dropped, the twin taking
# his group slots; otherwise he is unique and moves to Men (the Syndikat's
# bandits and paramilitaries, E22's Marines and Navy, the Pacific men...).
# SUBCAT_SF are special forces under a mod's own name - and the Vipers; the
# VR entities go regardless. The generated class restates editorSubcategory
# and vehicleClass only when it moves.
SUBCAT_KEEP = ("EdSubcat_Personnel", "EdSubcat_Personnel_SpecialForces", "EdSubcat_Personnel_Story")
SUBCAT_SF = ("EdSubcat_Personnel_Viper", "E22_EdSubcat_Personel_Recon", "E22_EdSubcat_Personel_Spetsnaz",
             "E22_EdSubcat_Personel_Marines_Recon", "EF_EdSubcat_Personnel_Recon")
SUBCAT_OUT = ("EdSubcat_Personnel_VR",)
SUBCAT_WRITE = {"sf": ("EdSubcat_Personnel_SpecialForces", "MenRecon"),
                "men": ("EdSubcat_Personnel", "Men")}


def prop_inh(units, props, c, name):
    """A dumped property up the parent chain - the dump logs OWN values only."""
    seen = set()
    while c and c not in seen:
        seen.add(c)
        v = props.get(c, {}).get(name)
        if v:
            return v[1]
        c = units.get(c, {}).get("parent")
    return ""


# SUPPRESSORS (user, 2026-08-28: "peer factions get silencers" - and the
# attachments rule in docs/weapon_pools_2040.md: at t3-4 suppressors are the
# DEFAULT on every primary, the pistols one tier behind). A faction at
# SUPPRESS_TIER or above gets a suppressed preset of every primary its men
# carry that links no muzzle item yet; at SUPPRESS_PISTOL_TIER the sidearms
# too. The can comes from the weapon's own MuzzleSlot as the dump logged it -
# CBA Joint Rails decides what fits, so nothing is guessed - picked by the
# faction's colour words first (SUPPRESS_PREFER), the thermal-insulated ones
# first at t4, the base game's when all else is equal. The presets are
# written to the addon's CfgWeapons.hpp as children of the weapon with the
# can as a LinkedItem: config, not a script. A dump made before the dump
# script logged weapons has none of this, and says so.
SUPPRESS_TIER = 3
SUPPRESS_PISTOL_TIER = 4
_CAN = re.compile(r"snds|suppress|silenc|pbs_|_sd_|_sd$", re.I)
_NOT_CAN = re.compile(r"mzls|flash|brake|antenna|bayonet|_comp", re.I)
# KHAKI IS A GREEN IN ARMA (user, 2026-08-28), not the tan the word means
# everywhere else - "khk" belongs in a woodland or tropical list and never in
# a desert one. The arid factions take sand and tan; the green ones take khaki,
# olive and green.
SUPPRESS_PREFER = {
    "jmfsb_US_JTF_des": ("snd", "sand", "tan", "arid"), "jmfsb_US_JTF_ocp": ("snd", "sand", "tan", "arid"),
    "jmfsb_US_JTF_wdl": ("khk", "olive", "oli", "grn", "blk", "black"),
    "jmfsb_US_JTF_tna": ("khk", "olive", "oli", "grn", "lush", "blk", "black"),
    "jmfsb_EUDF": ("khk", "grn", "olive", "oli", "blk"),
    "jmfsb_EUDF_wdl": ("wdl", "woodland", "grn", "olive", "khk"),
    "jmfsb_EUDF_tna": ("tna", "tropic", "grn", "olive", "khk"),
    "jmfsb_EUDF_arc": ("wht", "white", "arctic", "snow", "blk"),
    "jmfsb_EUDF_des": ("snd", "sand", "tan", "arid"),
    "jmfsb_Marine_wdl": ("khk", "grn", "olive", "oli", "blk"), "jmfsb_Marine_des": ("snd", "sand", "tan", "arid"),
    "jmfsb_RAF_wdl": ("khk", "grn", "olive", "blk", "black"),
    "jmfsb_RAF_ard": ("snd", "sand", "tan", "arid", "blk"), "jmfsb_RAF_alp": ("wht", "white", "snow", "blk"),
    "jmfsb_CSAT": ("hex", "blk", "black"), "jmfsb_CSAT_tna": ("ghex", "grn", "khk", "blk", "black"),
    "jmfsb_PLA_ard": ("snd", "sand", "tan", "arid", "blk", "black"),
    "jmfsb_PLA_wdl": ("grn", "olive", "oli", "khk", "blk", "black"),
}


def pick_can(fac, tier, compat):
    """The suppressor this faction fits from a weapon's MuzzleSlot, or None."""
    # NO JCA (user, 2026-10-09: "remove jca arsenal from factions and logistics")
    cans = [x for x in compat
            if _CAN.search(x) and not _NOT_CAN.search(x) and class_origin(x, None) != "dropped"
            and not x.lower().startswith("jca_")]
    if not cans:
        return None
    prefer = SUPPRESS_PREFER.get(fac, ())

    def score(x):
        xl = x.lower()
        sc = 0
        if tier >= 4 and "_ti" in xl:
            sc -= 20
        for i, tok in enumerate(prefer):
            if tok in xl:
                sc -= 10 - i
                break
        if xl.startswith("muzzle_snds_"):
            sc -= 1
        return (sc, len(x), xl)

    return min(cans, key=score)


WEAPONS_DB, WLOW = {}, {}

# WHOSE ROUND, when a vanilla magazine has both a NATO (FA_b_) and an AAF
# (FA_i_) descendant. The US and the Marines carry the b round; the
# independents carry the i round - the AAF's own, and the LDF's by the same
# logic (an independent army does not draw NATO ammunition).
# EAST FACTIONS TAKE THE EAST BUILD OF A ROUND. Without an entry a faction
# falls back to "FA_b_" - the WEST build - and an east-only round like the 5.8
# has no west build at all, so the whole faction quietly kept the base game's
# magazines. That is what happened to 2040 China on its first run.
FA_PREFER = {"jmfsb_AAF": "FA_i_", "jmfsb_LDF": "FA_i_",
             "jmfsb_China": "FA_o_", "jmfsb_China_ard": "FA_o_",
             "jmfsb_Iran": "FA_o_",
             "jmfsb_Russia": "FA_o_", "jmfsb_Russia_ard": "FA_o_", "jmfsb_Russia_arc": "FA_o_",
             "jmfsb_CSAT": "FA_o_", "jmfsb_CSAT_tna": "FA_o_",
             "jmfsb_PLA_ard": "FA_o_", "jmfsb_PLA_wdl": "FA_o_",
             "jmfsb_Insurgents": "FA_o_", "jmfsb_Syndikat": "FA_o_",
             "jmfsb_US_JTF_wdl": "FA_JCA_", "jmfsb_US_JTF_des": "FA_JCA_",
             "jmfsb_US_JTF_tna": "FA_JCA_", "jmfsb_US_JTF_ocp": "FA_JCA_",
             "jmfsb_RAF_wdl": "FA_e22raf_", "jmfsb_RAF_ard": "FA_e22raf_", "jmfsb_RAF_alp": "FA_e22raf_"}

# A MAGAZINE BY ANOTHER NAME. E22 issues its men the colour variants of its
# magazines (..._Mag_black_Green_F) while fa_e22raf maps the plain one
# (..._Mag_black_F) - same round, same well. The variant is folded onto the
# plain name before the FA map is consulted; a magazine the fold does not
# touch is looked up as it is.
def mag_alias(mag, famap=None):
    """The FA-map key for `mag`, or `mag` itself when no fold applies."""
    cands = [mag]
    if mag.startswith("E22_RAF_"):
        cands.append(re.sub(r"_black_[A-Za-z]+_F$", "_black_F", mag))
    if mag.startswith("JCA_"):
        # JCA's TRACER MAGAZINES carry the tracer colour in the name -
        # JCA_30Rnd_556x45_Red_sand_PMAG, ..._Tracer_IR_PMAG - and fa_jca
        # maps the plain magazine (..._sand_PMAG, ..._PMAG). Same round,
        # same well; the fold drops the tracer, as fa_map does for the
        # vanilla ones. Without it the desert JTF (sand magazines) kept
        # base-game rounds while the woodland JTF was tiered (2026-08-27).
        cands.append(re.sub(r"_(?:Red|Green|Yellow|White|Blue|Orange|Tracer_IR)_((?:[Ss]and_)?(?:PMAG|EMAG))$",
                            r"_\1", mag))
    if famap is None:
        return cands[-1]
    # fa_jca writes "Sand" for 7.62 and "sand" for 5.56; config does not
    # care about case and neither does this.
    low = dict((k.lower(), k) for k in famap)
    for c in cands:
        if c in famap:
            return c
        if c.lower() in low:
            return low[c.lower()]
    return mag


# ---------------------------------------------------------------------------
# KIT SUBSTITUTION
# ---------------------------------------------------------------------------
# newfac -> {source item -> item this faction wears}. Mapped item by item
# rather than by matching each man to a counterpart: only the men who carry
# a mapped item are rewritten, everyone else keeps what the source issued.
#
# ANYTHING WITH NO EQUIVALENT IS LEFT AS ISSUED and named in the run report -
# a wetsuit is a wetsuit, and inventing a colour for the RF heavy helmets
# would mean writing a classname that does not exist. KIT_KEEP is the list of
# things that are left alone on purpose and so are not reported.
#
# The SOF classes below are NAMED, not required - see faction_csat/config.cpp.
# A load order without SOF_Characters spawns these men in nothing, which is
# the same bargain every faction makes with its tier magazines.
# A PRESET THIS FACTION DECLARES OUTRIGHT, rather than one the suppressor tier
# worked out for it - see SUPPRESS_TIER for those. Same shape on disk: a scope 1
# child of the weapon with the attachments as LinkedItems and baseWeapon naming
# the plain gun, so the arsenal still lists one UMP and not two. Attachments
# CANNOT be given to a man any other way in config - weapons[] takes a class
# name and nothing else - so a hand-written loadout with a can and an optic on
# it has to become a class here first.
#   (preset class, the weapon it is, [(slot, item), ...])
EXTRA_PRESETS = {
    # 2040 Iran's service rifle: Aegis's AK-103 with the black ARCO the user's
    # loadout array puts on it. The AKM74 family's optic rail is CowsSlot
    # (CowsSlot_Rail, read off A3_Aegis weapons_f_aegis Rifles/AKM74), which
    # the ARCO fits.
    "jmfsb_Iran": [
        ("jmfsb_Iran_arifle_AK103_arco", "Aegis_arifle_AK103_F",
         [("CowsSlot", "optic_Arco_blk_F")]),
    ],
    "jmfsb_GEN": [
        ("jmfsb_GEN_smg_UMP_snds", "JCA_smg_UMP_black_F",
         # slots read off JCA's own config: MuzzleSlot is asdg_MuzzleSlot_45ACP_SMG,
         # CowsSlot is asdg_OpticRail1913. Both attachments fit those rails.
         [("MuzzleSlot", "muzzle_snds_acp"), ("CowsSlot", "JCA_optic_ARS_black")]),
    ],
}

# THE WHOLE LOADOUT, WRITTEN OUT, for men the user kitted by hand. KIT_SWAP
# substitutes item for item and leaves the rest of the source's loadout alone;
# this replaces it. Every field is stated because a class that states none of
# them inherits the source's, and the swap machinery downstream is skipped for
# these men so nothing re-swaps what was just set.
#
# "units" is the SOURCE class names, lower case: the men this applies to. The
# pilot and the APC crew are deliberately not on it - they keep their own kit.
# A LIST PER FACTION, FIRST MATCH WINS. One faction can want more than one
# loadout - the Gendarmerie's commander does not carry what his men carry - so
# each entry names the units it covers and the emitter takes the first entry
# that names the class. A single dict is still accepted.
FORCE_LOADOUT = {
    # THE GENDARMERIE, AS THE USER GAVE IT (2026-08-30, two getUnitLoadout
    # arrays, translated field for field). The JCA UMP the whole faction
    # carried until now is gone: the rank and file get AddGis's M16 carbine,
    # the commander Aegis's M4A1, and both get the G17 in place of the P07.
    #
    # WHAT THE ARRAYS SAY, LITERALLY: one magazine in the rifle and one in the
    # pistol - no spares in the vest, which is empty in both - and the frag,
    # the smoke and the first aid kit in the uniform. NO NVGs and no GPS: both
    # arrays leave those two linked slots empty.
    #
    # THE CLASSES ARE ALL VERIFIED against the mods' own configs, not guessed:
    # AddGis_arifle_M16_Carbine_F (AddGis weapons_f_addgis),
    # Aegis_arifle_M4A1_F / hgun_G17_black_F / 17Rnd_9x21_Mag / H_Beret_gen_F
    # (A3_Aegis), STC_H_MK7_blk_Visor_up_F (Aegis Gear Overhaul stc_equipment).
    # None of them is in the dump - it predates those mods coming back - so a
    # load order without them is a load order where these men stand empty
    # handed; that is the same trade every other named-class loadout makes.
    "jmfsb_GEN": [
        # THE COMMANDER FIRST, so his entry wins before the rank-and-file one
        # can claim him: Aegis's M4A1 and the Gendarmerie beret.
        {
            "units": {"b_gen_commander_f"},
            "uniform": "U_B_GEN_Soldier_F",
            "weapons": ["Aegis_arifle_M4A1_F", "hgun_G17_black_F", "Throw", "Put"],
            # THE 2040 BUILD OF THE SAME ROUND (user, 2026-08-30: "make sure
            # all factions have future ammo"). A hand-written loadout skips
            # the tier pass, so the Gendarmerie's rifle magazine is named at
            # its tier here - t2, police, see TIER. The 9x21 has no future
            # build, so the pistol keeps the base game's.
            "magazines": ["FA_b_30Rnd_556_Mk327_HV_t2", "17Rnd_9x21_Mag",
                          "HandGrenade", "SmokeShell"],
            # vest and headgear are linkedItems in config, not fields of their own
            "linked": ["V_PlateCarrier1_blk", "H_Beret_gen_F",
                       "ItemMap", "ItemRadio", "ItemCompass", "ItemWatch"],
            "items": ["FirstAidKit"],
            "backpack": "",
        },
        # THE REST OF THEM - the men who carried the JCA UMP: AddGis's M16
        # carbine and the MK7 with the visor up. Captain Dwarden is in here
        # rather than with the commander: the user's second array was for the
        # commander, and Dwarden is a named guest, not the unit's CO.
        {
            "units": {"b_gen_soldier_f", "b_gen_soldier_rf",
                      "b_gen_soldier_universal_f", "b_captain_dwarden_f"},
            "uniform": "U_B_GEN_Soldier_F",
            "weapons": ["AddGis_arifle_M16_Carbine_F", "hgun_G17_black_F", "Throw", "Put"],
            # THE 2040 BUILD OF THE SAME ROUND (user, 2026-08-30: "make sure
            # all factions have future ammo"). A hand-written loadout skips
            # the tier pass, so the Gendarmerie's rifle magazine is named at
            # its tier here - t2, police, see TIER. The 9x21 has no future
            # build, so the pistol keeps the base game's.
            "magazines": ["FA_b_30Rnd_556_Mk327_HV_t2", "17Rnd_9x21_Mag",
                          "HandGrenade", "SmokeShell"],
            "linked": ["V_PlateCarrier1_blk", "STC_H_MK7_blk_Visor_up_F",
                       "ItemMap", "ItemRadio", "ItemCompass", "ItemWatch"],
            "items": ["FirstAidKit"],
            "backpack": "",
        },
    ],
}

KIT_SWAP = {
    # 2040 CSAT: OPF_F's order of battle in the SOF_Characters mod's HEX set
    # (2026-08-27) - fatigues, CHPC rig, Attacker helmet cover - with OPF_F's
    # own items filling the slots the set does not cover (pilots, crews,
    # officers, ghillies, the bandolier and belt).
    "jmfsb_CSAT": {
        # --- uniforms ---
        "U_O_CombatUniform_ocamo":       "SOF_U_O_SFFatigues_hex",
        "U_O_CombatUniform_oucamo":      "SOF_U_O_SFFatigues_hex",
        "U_O_LCF_noInsignia_hex_lxWS":   "SOF_U_O_SFFatigues_hex",
        "U_O_LCF_noInsignia_hex_lxws":   "SOF_U_O_SFFatigues_hex",
        "U_O_SpecopsUniform_ocamo":      "SOF_U_O_SFFatigues_hex",
        # --- vests ---
        "V_TacVest_khk":                 "SOF_V_CHPCCarrier_Rig_hex",
        "V_TacVest_gry":                 "SOF_V_CHPCCarrier_Rig_hex",
        "V_TacVest_blk":                 "SOF_V_CHPCCarrier_Rig_hex",
        "V_TacVest_brn":                 "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessO_brn":                "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessO_gry":                "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessOGL_brn":              "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessOGL_gry":              "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessOSpec_brn":            "SOF_V_CHPCCarrier_Rig_hex",
        "V_Chestrig_khk":                "SOF_V_CHPCCarrier_Rig_hex",
        "V_ChestrigF_khk":               "SOF_V_CHPCCarrier_Rig_hex",
        # --- helmets ---
        "H_HelmetO_ocamo":               "SOF_H_HelmetAttacker_Cover_hex",
        "H_HelmetO_oucamo":              "SOF_H_HelmetAttacker_Cover_hex",
        "H_O_Helmet_canvas_ocamo":       "SOF_H_HelmetAttacker_Cover_hex",
        "H_HelmetO_ocamo_sb_hex_RF":     "SOF_H_HelmetAttacker_Cover_hex",
        "H_HelmetSpecO_ocamo":           "SOF_H_HelmetAttacker_Cover_hex",
        "H_HelmetLeaderO_ocamo":         "SOF_H_HelmetAttacker_Cover_hex",
        "H_HelmetLeaderO_oucamo":        "SOF_H_HelmetAttacker_Cover_hex",
    },
    # 2040 CSAT (Pacific): OPF_T_F in the same set's GREEN-HEX colours.
    "jmfsb_CSAT_tna": {
        # --- uniforms ---
        "U_O_T_Soldier_F":               "SOF_U_O_SFFatigues_ghex",
        # --- vests ---
        "V_HarnessO_ghex_F":             "SOF_V_CHPCCarrier_Rig_ghex",
        "V_HarnessOGL_ghex_F":           "SOF_V_CHPCCarrier_Rig_ghex",
        "V_HarnessOSpec_ghex_F":         "SOF_V_CHPCCarrier_Rig_ghex",
        "V_TacVest_oli":                 "SOF_V_CHPCCarrier_Rig_ghex",
        "V_TacChestrig_oli_F":           "SOF_V_CHPCCarrier_Rig_ghex",
        # --- helmets ---
        "H_HelmetO_ghex_F":              "SOF_H_HelmetAttacker_Cover_ghex",
        "H_HelmetSpecO_ghex_F":          "SOF_H_HelmetAttacker_Cover_ghex",
        "H_HelmetLeaderO_ghex_F":        "SOF_H_HelmetAttacker_Cover_ghex",
    },
    # 2040 US Army JTF (Tropical): E22's woodland JTF in the base game's NATO
    # Pacific kit (user, 2026-08-27). One E22 item maps to one base-game item,
    # so the roles keep E22's spread: the headset helmet most men wear is the
    # plain tropic helmet, the bare one the light, chops and ear-pro the
    # enhanced. Berets, the fighter helmet, the wetsuit and the Navy's
    # black-and-navy kit are left as they are.
    # 2040 IRAN (user, 2026-08-30), Aegis Gear Overhaul's Iranian digital
    # ("irdigi") set. The user's loadout array names the PCU uniform, the CQB
    # carrier and the PCH helmet with a cover; the alternates he listed beside
    # it are broken up here on the source's own distinctions - a chest rig
    # becomes the light carrier, a grenadier rig the GL one, special forces
    # keep the CQB carrier, and a cap stays a cap.
    "jmfsb_Iran": {
        # --- uniforms ---
        "U_O_CombatUniform_ocamo":       "STC_U_O_CombatUniform_PCU_irdigi_01_F",
        "U_O_CombatUniform_oucamo":      "STC_U_O_CombatUniform_PCU_irdigi_02_F",
        "U_O_LCF_noInsignia_hex_lxWS":   "STC_U_O_CombatUniform_PCU_irdigi_01_F",
        "U_O_LCF_noInsignia_hex_lxws":   "STC_U_O_CombatUniform_PCU_irdigi_01_F",
        "U_O_SpecopsUniform_ocamo":      "STC_U_O_Uniform_PCU_irdigi_01_F",
        "U_O_OfficerUniform_ocamo":      "STC_U_O_OfficerUniform_PCU_irdigi_01_F",
        "U_O_officer_noInsignia_hex_F":  "STC_U_O_OfficerUniform_PCU_irdigi_01_F",
        "U_O_CombatUniform_oucamo_tshirt": "STC_U_InsCombatFatigues_irdigi_F",
        "U_I_C_Soldier_Bandit_1_F":      "STC_U_InsCombatFatigues_irdigi_F",
        # --- vests ---
        "V_HarnessO_brn":                "STC_V_OCarrierRig_Lite_alt_irdigi_F",
        "V_HarnessO_gry":                "STC_V_OCarrierRig_Lite_alt_irdigi_F",
        "V_HarnessO_ghex_F":             "STC_V_OCarrierRig_Lite_alt_irdigi_F",
        "V_HarnessO_oicamo":             "STC_V_OCarrierRig_Lite_alt_irdigi_F",
        "V_Chestrig_khk":                "STC_V_OCarrierRig_Lite_alt_irdigi_F",
        "V_ChestrigF_khk":               "STC_V_OCarrierRig_Lite_alt_irdigi_F",
        "V_TacChestrig_cbr_F":           "STC_V_OCarrierRig_Lite_alt_irdigi_F",
        "V_TacChestrig_oli_F":           "STC_V_OCarrierRig_Lite_alt_irdigi_F",
        "V_HarnessOGL_brn":              "STC_V_OCarrierRig_GL_alt_irdigi_F",
        "V_HarnessOGL_gry":              "STC_V_OCarrierRig_GL_alt_irdigi_F",
        "V_HarnessOGL_ghex_F":           "STC_V_OCarrierRig_GL_alt_irdigi_F",
        "V_HarnessOGL_oicamo":           "STC_V_OCarrierRig_GL_alt_irdigi_F",
        "V_HarnessOSpec_brn":            "STC_V_OCarrierRig_CQB_alt_irdigi_F",
        "V_HarnessOSpec_gry":            "STC_V_OCarrierRig_CQB_alt_irdigi_F",
        "V_HarnessOSpec_ghex_F":         "STC_V_OCarrierRig_CQB_alt_irdigi_F",
        "V_TacVest_brn":                 "STC_V_OCarrierRig_CQB_alt_irdigi_F",
        "V_TacVest_khk":                 "STC_V_OCarrierRig_CQB_alt_irdigi_F",
        "V_TacVest_oli":                 "STC_V_OCarrierRig_CQB_alt_irdigi_F",
        # --- headgear: helmets get the PCH, caps and boonies stay soft ---
        "H_HelmetO_ocamo":               "STC_H_HelmetPCH_cover_irdigi_F",
        "H_HelmetO_oucamo":              "STC_H_HelmetPCH_cover_irdigi_F",
        "H_HelmetO_ghex_F":              "STC_H_HelmetPCH_cover_irdigi_F",
        "H_O_Helmet_canvas_ocamo":       "STC_H_HelmetPCH_cover_irdigi_F",
        "H_HelmetLeaderO_ocamo":         "STC_H_HelmetPCH_cover_lite_irdigi_F",
        "H_HelmetLeaderO_oucamo":        "STC_H_HelmetPCH_cover_lite_irdigi_F",
        "H_HelmetSpecO_ocamo":           "STC_H_HelmetPCH_cover_lite_irdigi_F",
        "H_HelmetSpecO_blk":             "STC_H_HelmetPCH_cover_lite_irdigi_F",
        "H_HelmetSpecO_brn":             "STC_H_HelmetPCH_cover_lite_irdigi_F",
        "H_MilCap_ocamo":                "STC_H_MilCap_irdigi",
        "H_MilCap_oucamo":               "STC_H_MilCap_irdigi",
        "H_MilCap_gry":                  "STC_H_Milcap_nohs_irdigi",
        "H_Booniehat_oli":               "STC_H_Booniehat_irdigi_F",
        "H_Booniehat_khk":               "STC_H_Booniehat_irdigi_F",
        "H_Booniehat_tan":               "STC_H_Booniehat_irdigi_F",
    },
    # 2040 CHINA (user, 2026-08-30), the JAM SOF green-hex set. The user's
    # loadout array names the fatigues, the light carrier and the CSAT light
    # helmet with a cover; the alternates he listed beside it are broken up by
    # unit type below, on the source's own distinctions.
    "jmfsb_China": {
        # --- uniforms: the SF fatigues, short sleeves where the source
        # man was already in a t-shirt or rolled sleeves ---
        "U_O_T_Soldier_F":                    "SOF_U_O_SFFatigues_ghex",
        "U_O_CombatUniform_oicamo":           "SOF_U_O_SFFatigues_ghex",
        "U_O_CombatUniform_ocamo":            "SOF_U_O_SFFatigues_ghex",
        "U_O_OfficerUniform_ocamo":           "SOF_U_O_SFFatigues_ghex",
        "Atlas_U_O_CombatFatigues_mhex_F":    "SOF_U_O_SFFatigues_ghex",
        "Atlas_U_O_CombatFatigues_mhex_02_F": "SOF_U_O_SFFatigues_ghex",
        "athena_U_O_IHWCU_combat_tu_F":       "SOF_U_O_SFFatigues_ghex",
        "athena_U_O_CombatUniform_F":         "SOF_U_O_SFFatigues_ghex",
        "athena_U_O_IHWCU_combat_shortsleeve_tu_F": "SOF_U_O_SFFatigues_Shortsleeve_ghex",
        "U_O_T_Soldier_shortsleeve_F":        "SOF_U_O_SFFatigues_Shortsleeve_ghex",
        # --- vests: chest rigs and harnesses are the light carrier, the
        # grenadier/leader rigs and the heavy vests the full one ---
        "V_HarnessO_ghex_F":                  "SOF_V_CHPCCarrier_Lite_ghex",
        "V_HarnessO_oicamo":                  "SOF_V_CHPCCarrier_Lite_ghex",
        "V_HarnessO_gry":                     "SOF_V_CHPCCarrier_Lite_ghex",
        "V_HarnessO_brn":                     "SOF_V_CHPCCarrier_Lite_ghex",
        "V_TacChestrig_oli_F":                "SOF_V_CHPCCarrier_Lite_ghex",
        "V_TacChestrig_cbr_F":                "SOF_V_CHPCCarrier_Lite_ghex",
        "V_TacChestrig_grn_F":                "SOF_V_CHPCCarrier_Lite_ghex",
        "V_CarrierRigKBT_01_light_Turkey_F":  "SOF_V_CHPCCarrier_Lite_ghex",
        "V_HarnessOGL_ghex_F":                "SOF_V_CHPCCarrier_Rig_ghex",
        "V_HarnessOGL_oicamo":                "SOF_V_CHPCCarrier_Rig_ghex",
        "V_HarnessOGL_gry":                   "SOF_V_CHPCCarrier_Rig_ghex",
        "V_HarnessOGL_brn":                   "SOF_V_CHPCCarrier_Rig_ghex",
        "V_HarnessOSpec_ghex_F":              "SOF_V_CHPCCarrier_Rig_ghex",
        "V_HarnessOSpec_brn":                 "SOF_V_CHPCCarrier_Rig_ghex",
        "V_TacVest_oli":                      "SOF_V_CHPCCarrier_Rig_ghex",
        "V_TacVest_brn":                      "SOF_V_CHPCCarrier_Rig_ghex",
        "V_TacVest_khk":                      "SOF_V_CHPCCarrier_Rig_ghex",
        "V_CarrierRigKBT_01_Turkey_F":        "SOF_V_CHPCCarrier_Rig_ghex",
        # --- helmets: the line wears the CSAT light helmet with a cover, the
        # leaders the scrimmed one, and special forces the high-cut Opscore
        # (user: "China should have high cut helmets"). Pilot, crew and diver
        # headgear is not touched - none of it has a version in this set.
        "H_HelmetO_ghex_F":                   "SOF_H_HelmetCSAT_Light_Cover_ghex",
        "H_HelmetO_oicamo":                   "SOF_H_HelmetCSAT_Light_Cover_ghex",
        "H_HelmetO_ocamo":                    "SOF_H_HelmetCSAT_Light_Cover_ghex",
        "H_HelmetO_oucamo":                   "SOF_H_HelmetCSAT_Light_Cover_ghex",
        "H_O_Helmet_canvas_ocamo":            "SOF_H_HelmetCSAT_Light_Cover_ghex",
        "H_HelmetLeaderO_ghex_F":             "SOF_H_HelmetCSAT_Light_CoverScrim_ghex",
        "H_HelmetLeaderO_oicamo":             "SOF_H_HelmetCSAT_Light_CoverScrim_ghex",
        "H_HelmetLeaderO_ocamo":              "SOF_H_HelmetCSAT_Light_CoverScrim_ghex",
        "H_HelmetLeaderO_oucamo":             "SOF_H_HelmetCSAT_Light_CoverScrim_ghex",
        "H_HelmetSpecO_ghex_F":               "SOF_H_Opscore_CoverSpec_ghex",
        "H_HelmetSpecO_oicamo":               "SOF_H_Opscore_CoverSpec_ghex",
        "H_HelmetSpecO_ocamo":                "SOF_H_Opscore_CoverSpec_ghex",
        "H_HelmetSpecO_blk":                  "SOF_H_Opscore_CoverSpec_ghex",
        "H_HelmetSpecO_brn":                  "SOF_H_Opscore_CoverSpec_ghex",
        # --- night vision, in the faction's own camo ---
        "O_NVGoggles_ghex_F":                 "O_NVGoggles_ghex_F",
        "O_NVGoggles_hex_F":                  "O_NVGoggles_ghex_F",
        "O_NVGoggles_blk_F":                  "O_NVGoggles_ghex_F",
        "O_NVGoggles_urb_F":                  "O_NVGoggles_ghex_F",
        "NVGoggles_OPFOR":                    "O_NVGoggles_ghex_F",
    },
    # 2040 CHINA (DESERT): the same map in hex. Every man the desert faction
    # borrows from the tropical roster (ROSTER_TEMPLATE) is re-dressed by these
    # lines, which is what lets the two be equal in units without the desert
    # force turning up in green.
    "jmfsb_China_ard": {
        # --- uniforms: the SF fatigues, short sleeves where the source
        # man was already in a t-shirt or rolled sleeves ---
        "U_O_T_Soldier_F":                    "SOF_U_O_SFFatigues_hex",
        "U_O_CombatUniform_oicamo":           "SOF_U_O_SFFatigues_hex",
        "U_O_CombatUniform_ocamo":            "SOF_U_O_SFFatigues_hex",
        "U_O_OfficerUniform_ocamo":           "SOF_U_O_SFFatigues_hex",
        "Atlas_U_O_CombatFatigues_mhex_F":    "SOF_U_O_SFFatigues_hex",
        "Atlas_U_O_CombatFatigues_mhex_02_F": "SOF_U_O_SFFatigues_hex",
        "athena_U_O_IHWCU_combat_tu_F":       "SOF_U_O_SFFatigues_hex",
        "athena_U_O_CombatUniform_F":         "SOF_U_O_SFFatigues_hex",
        "athena_U_O_IHWCU_combat_shortsleeve_tu_F": "SOF_U_O_SFFatigues_Shortsleeve_hex",
        "U_O_T_Soldier_shortsleeve_F":        "SOF_U_O_SFFatigues_Shortsleeve_hex",
        # --- vests: chest rigs and harnesses are the light carrier, the
        # grenadier/leader rigs and the heavy vests the full one ---
        "V_HarnessO_ghex_F":                  "SOF_V_CHPCCarrier_Lite_hex",
        "V_HarnessO_oicamo":                  "SOF_V_CHPCCarrier_Lite_hex",
        "V_HarnessO_gry":                     "SOF_V_CHPCCarrier_Lite_hex",
        "V_HarnessO_brn":                     "SOF_V_CHPCCarrier_Lite_hex",
        "V_TacChestrig_oli_F":                "SOF_V_CHPCCarrier_Lite_hex",
        "V_TacChestrig_cbr_F":                "SOF_V_CHPCCarrier_Lite_hex",
        "V_TacChestrig_grn_F":                "SOF_V_CHPCCarrier_Lite_hex",
        "V_CarrierRigKBT_01_light_Turkey_F":  "SOF_V_CHPCCarrier_Lite_hex",
        "V_HarnessOGL_ghex_F":                "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessOGL_oicamo":                "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessOGL_gry":                   "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessOGL_brn":                   "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessOSpec_ghex_F":              "SOF_V_CHPCCarrier_Rig_hex",
        "V_HarnessOSpec_brn":                 "SOF_V_CHPCCarrier_Rig_hex",
        "V_TacVest_oli":                      "SOF_V_CHPCCarrier_Rig_hex",
        "V_TacVest_brn":                      "SOF_V_CHPCCarrier_Rig_hex",
        "V_TacVest_khk":                      "SOF_V_CHPCCarrier_Rig_hex",
        "V_CarrierRigKBT_01_Turkey_F":        "SOF_V_CHPCCarrier_Rig_hex",
        # --- helmets: the line wears the CSAT light helmet with a cover, the
        # leaders the scrimmed one, and special forces the high-cut Opscore
        # (user: "China should have high cut helmets"). Pilot, crew and diver
        # headgear is not touched - none of it has a version in this set.
        "H_HelmetO_ghex_F":                   "SOF_H_HelmetCSAT_Light_Cover_hex",
        "H_HelmetO_oicamo":                   "SOF_H_HelmetCSAT_Light_Cover_hex",
        "H_HelmetO_ocamo":                    "SOF_H_HelmetCSAT_Light_Cover_hex",
        "H_HelmetO_oucamo":                   "SOF_H_HelmetCSAT_Light_Cover_hex",
        "H_O_Helmet_canvas_ocamo":            "SOF_H_HelmetCSAT_Light_Cover_hex",
        "H_HelmetLeaderO_ghex_F":             "SOF_H_HelmetCSAT_Light_CoverScrim_hex",
        "H_HelmetLeaderO_oicamo":             "SOF_H_HelmetCSAT_Light_CoverScrim_hex",
        "H_HelmetLeaderO_ocamo":              "SOF_H_HelmetCSAT_Light_CoverScrim_hex",
        "H_HelmetLeaderO_oucamo":             "SOF_H_HelmetCSAT_Light_CoverScrim_hex",
        "H_HelmetSpecO_ghex_F":               "SOF_H_Opscore_CoverSpec_hex",
        "H_HelmetSpecO_oicamo":               "SOF_H_Opscore_CoverSpec_hex",
        "H_HelmetSpecO_ocamo":                "SOF_H_Opscore_CoverSpec_hex",
        "H_HelmetSpecO_blk":                  "SOF_H_Opscore_CoverSpec_hex",
        "H_HelmetSpecO_brn":                  "SOF_H_Opscore_CoverSpec_hex",
        # --- night vision, in the faction's own camo ---
        "O_NVGoggles_ghex_F":                 "O_NVGoggles_hex_F",
        "O_NVGoggles_hex_F":                  "O_NVGoggles_hex_F",
        "O_NVGoggles_blk_F":                  "O_NVGoggles_hex_F",
        "O_NVGoggles_urb_F":                  "O_NVGoggles_hex_F",
        "NVGoggles_OPFOR":                    "O_NVGoggles_hex_F",
    },
    # 2040 US Army JTF (Woodland): BLU_W_F already wears the woodland kit -
    # only the men borrowed from the tropical roster need dressing.
    "jmfsb_US_JTF_wdl": {
        # THE BORROWED MEN (2026-08-30). The woodland JTF has no recon, no
        # divers, no sniper and no spotter of its own - BLU_W_F fields none -
        # so GROUP_TEMPLATE borrows BLU_T_F's, and they arrive in tropical
        # camo. These lines put them in the woodland kit the rest of the
        # faction wears. The wetsuit and rebreather are not camo and stay.
        "U_B_T_Soldier_F":      "U_B_CombatUniform_mcam_wdl_f",
        "U_B_T_Soldier_SL_F":   "U_B_CombatUniform_vest_mcam_wdl_f",
        "U_B_T_Sniper_F":       "U_B_FullGhillie_lsh",
        "V_Chestrig_rgr":       "V_PlateCarrier1_wdl",
        "H_MilCap_tna_F":       "H_MilCap_mcamo",
        "NVGoggles_tna_F":      "NVGoggles_INDEP",
    },
    # 2040 US Army JTF (Desert): Western Sahara's own desert kit, plus the
    # borrowed men.
    "jmfsb_US_JTF_des": {
        # THE BORROWED MEN (2026-08-30) - see the woodland entry. Western
        # Sahara's desert roster has no divers and no sniper pair; BLU_T_F's
        # come in through GROUP_TEMPLATE and are dressed in desert here.
        "U_B_T_Soldier_F":      "U_lxWS_B_CombatUniform_desert",
        "U_B_T_Soldier_SL_F":   "U_lxWS_B_CombatUniform_desert_vest",
        "U_B_T_Sniper_F":       "U_B_FullGhillie_ard",
        "V_Chestrig_rgr":       "V_Chestrig_khk",
        "H_Watchcap_camo":      "H_Watchcap_khk",
        "H_MilCap_tna_F":       "H_MilCap_tna_F",
        "NVGoggles_tna_F":      "NVGoggles",
    },
    # 2040 US Army JTF (Tropical): built from BLU_T_F since 2026-08-29, which
    # already wears the NATO Pacific kit - and it is the group template, so it
    # borrows nothing. Nothing to swap.
    "jmfsb_US_JTF_tna": {},
    # 2040 US Army JTF (OCP): E22's desert JTF in the repo's own OCP
    # retextures of the base game's NATO kit (user, 2026-08-27) - combat
    # fatigues (uniform), plate carriers (vests), FAST-MT helmets and the
    # booniehat (headware). Caps, crew and aircrew helmets and the beret have
    # no OCP version and stay desert tan.
    # 2040 US Army JTF (OCP): Western Sahara's desert NATO roster in the repo's
    # own OCP retextures of the base game's kit (user, 2026-08-27; re-keyed to
    # the lxWS classes 2026-08-29 when E22 left) - fatigues (uniform), FAST-MT
    # helmets and the booniehat (headware). Whatever the run report shows the
    # roster still wearing in desert tan is the next line here.
    "jmfsb_US_JTF_ocp": {
        "U_lxWS_B_CombatUniform_desert":        "jmfsb_uniform_U_B_CombatUniform_ocp_F",
        "U_lxWS_B_CombatUniform_desert_tshirt": "jmfsb_uniform_U_B_CombatUniform_ocp_F",
        "U_lxWS_B_CombatUniform_desert_vest":   "jmfsb_uniform_U_B_CombatUniform_ocp_F",
        "H_HelmetB_sand":                       "jmfsb_headware_H_Helmet_FASTMT_US_OCP_F",
        "H_HelmetB_light_sand":                 "jmfsb_headware_H_Helmet_FASTMT_US_OCP_F",
        "H_HelmetSpecB_sand":                   "jmfsb_headware_H_Helmet_FASTMT_Headset_US_OCP_F",
        "H_Booniehat_khk":                      "jmfsb_headware_H_Booniehat_ocp_F",
        "H_Booniehat_khk_hs":                   "jmfsb_headware_H_Booniehat_ocp_hs_F",
        # THE BORROWED MEN (2026-08-30) - see the woodland entry. The OCP
        # theatre dresses them in its own retextures; the ghillie has no OCP
        # version, so the semi-arid one stands in.
        "U_B_T_Soldier_F":      "jmfsb_uniform_U_B_CombatUniform_ocp_F",
        "U_B_T_Soldier_SL_F":   "jmfsb_uniform_U_B_CombatUniform_ocp_F",
        "U_B_T_Sniper_F":       "U_B_FullGhillie_sard",
        "V_Chestrig_rgr":       "V_Chestrig_khk",
        "H_Watchcap_camo":      "H_Watchcap_khk",
        "NVGoggles_tna_F":      "NVGoggles",
    },
    # THE PLA CAMO ADDON IS GONE (user, 2026-08-30: "remove the pla camos").
    # addons/uniform_pla was removed with the two PLA factions it dressed;
    # it is kept whole in backup/uniform_pla_removed_2026-08-30/ and
    # tools/gen_pla_kit.py can rebuild it from the ACP pack. THESE TWO TABLES
    # ARE INERT until then - their factions are commented out of TARGETS - and
    # putting a PLA line back means restoring the addon first, or every man
    # comes out in a uniform that does not exist.
    # 2040 PLA (Arid): OPF_F's kit in the vendored Xingkong Arid set - addons/uniform_pla (user, 2026-08-28).
    # VESTS (user, 2026-08-28: "a lot of the vests had no pouches, they were plain"): the plain Modular
    # Carrier is out - the rifle line wears the GL rig (heavy), the chest-rig roles the Lite (light). Vipers wear the Xingkong Special Purpose Suit; packs are not swapped (their contents are the loadout).
    "jmfsb_PLA_ard": {
        "U_O_CombatUniform_ocamo": "jmfsb_uniform_pla_U_B_CombatUniform_A",
        "U_O_CombatUniform_oucamo": "jmfsb_uniform_pla_U_B_CombatUniform_A",
        "U_O_LCF_noInsignia_hex_lxWS": "jmfsb_uniform_pla_U_B_CombatUniform_A",
        "U_O_LCF_noInsignia_hex_lxws": "jmfsb_uniform_pla_U_B_CombatUniform_A",
        "U_O_officer_noInsignia_hex_F": "jmfsb_uniform_pla_U_B_CombatUniform_A",
        "U_O_OfficerUniform_ocamo": "jmfsb_uniform_pla_U_B_CombatUniform_A",
        "SOF_U_O_SFFatigues_hex": "jmfsb_uniform_pla_U_B_CombatUniform_A",
        "SOF_U_O_SFFatigues_Shortsleeve_hex": "jmfsb_uniform_pla_U_B_CombatUniform_vest_A",
        "U_O_SpecopsUniform_ocamo": "jmfsb_uniform_pla_U_Tank_A",
        "U_O_PilotCoveralls": "jmfsb_uniform_pla_U_O_PilotCoveralls_A",
        "U_O_GhillieSuit": "jmfsb_uniform_pla_U_B_GhillieSuit_A",
        # THE VIPERS TOO (user, 2026-08-28): ACP's Special Purpose Suit and helmet
        "U_O_V_Soldier_Viper_hex_F": "jmfsb_uniform_pla_U_O_V_Soldier_Viper_A",
        "U_O_V_Soldier_Viper_F": "jmfsb_uniform_pla_U_O_V_Soldier_Viper_A",
        "H_HelmetO_ViperSP_hex_F": "jmfsb_uniform_pla_H_HelmetO_ViperSP_A",
        "H_HelmetO_ViperSP_ghex_F": "jmfsb_uniform_pla_H_HelmetO_ViperSP_A",
        "V_Chestrig_khk": "jmfsb_uniform_pla_V_CarrierRigKBT_01_light_A",
        "V_TacVest_khk": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_TacVest_brn": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_TacVest_blk": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_TacVest_Blk": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_TacVest_rig_khk_RF": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_HarnessO_brn": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_HarnessO_gry": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_HarnessOGL_brn": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_HarnessOGL_gry": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_A",
        "V_BandollierB_cbr": "jmfsb_uniform_pla_V_SmershVest_01_A",
        "V_BandollierB_khk": "jmfsb_uniform_pla_V_SmershVest_01_A",
        "H_HelmetO_ocamo": "jmfsb_uniform_pla_H_HelmetHBK_A",
        "H_HelmetO_oucamo": "jmfsb_uniform_pla_H_HelmetHBK_A",
        "H_HelmetO_ocamo_sb_hex_RF": "jmfsb_uniform_pla_H_HelmetHBK_A",
        "H_HelmetB_plain_sb_hex_RF": "jmfsb_uniform_pla_H_HelmetHBK_A",
        "H_HelmetLeaderO_ocamo": "jmfsb_uniform_pla_H_HelmetHBK_headset_A",
        "H_HelmetLeaderO_oucamo": "jmfsb_uniform_pla_H_HelmetHBK_headset_A",
        "H_HelmetSpecO_ocamo": "jmfsb_uniform_pla_H_HelmetHBK_chops_A",
        "H_HelmetSpecO_blk": "jmfsb_uniform_pla_H_HelmetHBK_chops_A",
        "H_MilCap_ocamo": "jmfsb_uniform_pla_H_MilCap_A",
        "H_Cap_brn_SPECOPS": "jmfsb_uniform_pla_H_Cap_A",
        "H_Beret_ocamo": "jmfsb_uniform_pla_H_Cap_A",
        "H_HelmetCrew_O": "jmfsb_uniform_pla_H_HelmetCrew_A",
        "EF_H_HelmetCrew_O_Urban": "jmfsb_uniform_pla_H_HelmetCrew_A",
        "H_Tank_black_F": "jmfsb_uniform_pla_H_HelmetCrew_A",
        "H_PilotHelmetHeli_O": "jmfsb_uniform_pla_H_PilotHelmetHeli_A",
        "H_PilotHelmetHeli_B": "jmfsb_uniform_pla_H_PilotHelmetHeli_A",
        "H_CrewHelmetHeli_O": "jmfsb_uniform_pla_H_CrewHelmetHeli_A",
        # Western Sahara's arid CSAT men (in OPF_F's roster) wear SSh-40s and turbans
        "lxWS_H_ssh40_sand": "jmfsb_uniform_pla_H_HelmetHBK_A",
        "lxWS_H_turban_02_sand": "jmfsb_uniform_pla_H_MilCap_A",
        "H_turban_02_mask_hex_lxws": "jmfsb_uniform_pla_H_MilCap_A",
    },
    # 2040 PLA (Woodland): the same in Xingkong Woodland.
    "jmfsb_PLA_wdl": {
        "U_O_CombatUniform_ocamo": "jmfsb_uniform_pla_U_B_CombatUniform_W",
        "U_O_CombatUniform_oucamo": "jmfsb_uniform_pla_U_B_CombatUniform_W",
        "U_O_LCF_noInsignia_hex_lxWS": "jmfsb_uniform_pla_U_B_CombatUniform_W",
        "U_O_LCF_noInsignia_hex_lxws": "jmfsb_uniform_pla_U_B_CombatUniform_W",
        "U_O_officer_noInsignia_hex_F": "jmfsb_uniform_pla_U_B_CombatUniform_W",
        "U_O_OfficerUniform_ocamo": "jmfsb_uniform_pla_U_B_CombatUniform_W",
        "SOF_U_O_SFFatigues_hex": "jmfsb_uniform_pla_U_B_CombatUniform_W",
        "SOF_U_O_SFFatigues_Shortsleeve_hex": "jmfsb_uniform_pla_U_B_CombatUniform_vest_W",
        "U_O_SpecopsUniform_ocamo": "jmfsb_uniform_pla_U_Tank_W",
        "U_O_PilotCoveralls": "jmfsb_uniform_pla_U_O_PilotCoveralls_W",
        "U_O_GhillieSuit": "jmfsb_uniform_pla_U_B_GhillieSuit_W",
        # THE VIPERS TOO (user, 2026-08-28): ACP's Special Purpose Suit and helmet
        "U_O_V_Soldier_Viper_hex_F": "jmfsb_uniform_pla_U_O_V_Soldier_Viper_W",
        "U_O_V_Soldier_Viper_F": "jmfsb_uniform_pla_U_O_V_Soldier_Viper_W",
        "H_HelmetO_ViperSP_hex_F": "jmfsb_uniform_pla_H_HelmetO_ViperSP_W",
        "H_HelmetO_ViperSP_ghex_F": "jmfsb_uniform_pla_H_HelmetO_ViperSP_W",
        "V_Chestrig_khk": "jmfsb_uniform_pla_V_CarrierRigKBT_01_light_W",
        "V_TacVest_khk": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_TacVest_brn": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_TacVest_blk": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_TacVest_Blk": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_TacVest_rig_khk_RF": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_HarnessO_brn": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_HarnessO_gry": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_HarnessOGL_brn": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_HarnessOGL_gry": "jmfsb_uniform_pla_V_CarrierRigKBT_01_heavy_W",
        "V_BandollierB_cbr": "jmfsb_uniform_pla_V_SmershVest_01_W",
        "V_BandollierB_khk": "jmfsb_uniform_pla_V_SmershVest_01_W",
        "H_HelmetO_ocamo": "jmfsb_uniform_pla_H_HelmetHBK_W",
        "H_HelmetO_oucamo": "jmfsb_uniform_pla_H_HelmetHBK_W",
        "H_HelmetO_ocamo_sb_hex_RF": "jmfsb_uniform_pla_H_HelmetHBK_W",
        "H_HelmetB_plain_sb_hex_RF": "jmfsb_uniform_pla_H_HelmetHBK_W",
        "H_HelmetLeaderO_ocamo": "jmfsb_uniform_pla_H_HelmetHBK_headset_W",
        "H_HelmetLeaderO_oucamo": "jmfsb_uniform_pla_H_HelmetHBK_headset_W",
        "H_HelmetSpecO_ocamo": "jmfsb_uniform_pla_H_HelmetHBK_chops_W",
        "H_HelmetSpecO_blk": "jmfsb_uniform_pla_H_HelmetHBK_chops_W",
        "H_MilCap_ocamo": "jmfsb_uniform_pla_H_MilCap_W",
        "H_Cap_brn_SPECOPS": "jmfsb_uniform_pla_H_Cap_W",
        "H_Beret_ocamo": "jmfsb_uniform_pla_H_Cap_W",
        "H_HelmetCrew_O": "jmfsb_uniform_pla_H_HelmetCrew_W",
        "EF_H_HelmetCrew_O_Urban": "jmfsb_uniform_pla_H_HelmetCrew_W",
        "H_Tank_black_F": "jmfsb_uniform_pla_H_HelmetCrew_W",
        "H_PilotHelmetHeli_O": "jmfsb_uniform_pla_H_PilotHelmetHeli_W",
        "H_PilotHelmetHeli_B": "jmfsb_uniform_pla_H_PilotHelmetHeli_W",
        "H_CrewHelmetHeli_O": "jmfsb_uniform_pla_H_CrewHelmetHeli_W",
        # Western Sahara's arid CSAT men (in OPF_F's roster) wear SSh-40s and turbans
        "lxWS_H_ssh40_sand": "jmfsb_uniform_pla_H_HelmetHBK_W",
        "lxWS_H_turban_02_sand": "jmfsb_uniform_pla_H_MilCap_W",
        "H_turban_02_mask_hex_lxws": "jmfsb_uniform_pla_H_MilCap_W",
    },
    # The two E22 t-shirt rules that used to sit here (user, 2026-08-28: no
    # t-shirts at this level) went with E22 on 2026-08-29 - and being a SECOND
    # "jmfsb_US_JTF_wdl"/"_des" key in this same dict, they were quietly
    # throwing away whatever the first one said. The woodland and desert
    # entries are up with the rest of them now.
}

# Issued unchanged on purpose - the SOF set has no version, or the item is
# not a uniform, vest or helmet in the sense the set replaces.
KIT_KEEP = {
    "U_O_Wetsuit", "V_RebreatherIR", "U_O_Protagonist_VR",
    "U_O_ParadeUniform_01_CSAT_F", "U_O_ParadeUniform_01_CSAT_decorated_F",
    "H_ParadeDressCap_01_CSAT_F", "H_Beret_CSAT_01_F", "H_HelmetSpecO_blk",
    "H_PilotHelmetHeli_O", "H_CrewHelmetHeli_O", "H_PilotHelmetFighter_O",
    "H_HelmetHeavy_VisorUp_Hex_RF", "H_HelmetHeavy_Hex_RF",
    "H_HelmetHeavy_Simple_Hex_RF", "V_TacVest_Blk",
    # OPF_F's and OPF_T_F's own specialist kit, left alone by both CSATs
    "U_O_OfficerUniform_ocamo", "U_O_PilotCoveralls", "U_O_GhillieSuit",
    "U_O_FullGhillie_lsh", "U_O_FullGhillie_sard", "U_O_FullGhillie_ard",
    "U_O_T_Officer_F", "U_O_T_Pilot_F", "U_O_T_FullGhillie_tna_F",
    "V_BandollierB_khk", "V_BandolierB_khk", "V_BandollierB_ghex_F",
    "V_Rangemaster_belt_khk", "V_Rangemaster_belt_ghex_F",
    "H_HelmetCrew_O", "H_HelmetCrew_O_ghex_F", "H_MilCap_ocamo", "H_MilCap_ghex_F",
    # the Vipers keep their own suits and helmets; the officer's no-insignia
    # fatigues are an officer's
    "U_O_V_Soldier_Viper_hex_F", "U_O_V_Soldier_Viper_F",
    "H_HelmetO_ViperSP_hex_F", "H_HelmetO_ViperSP_ghex_F",
    "U_O_officer_noInsignia_hex_F",
}


def is_ram(cls, disp):
    """The Ram 1500s are out of every US faction.

    A civilian pickup with a gun bolted on is an insurgent's answer to not
    having an MRAP. A US or Marine formation has MRAPs, so the technical reads
    as the wrong army the moment it drives past.

    Matched on the display name first, because that is what says Ram; the AT
    variants are matched on the classname instead, because theirs is a raw
    classname with no display name at all. NOT BUILT rather than scoped to 0 -
    a class that does not exist cannot be fielded by anything.
    """
    if disp and disp.startswith("Ram 1500"):
        return True
    return "Pickup" in cls and ("_AT_RF" in cls or "_AT_rf" in cls)


def resolve(new, src):
    """This faction's class for a source class, whatever the case.

    CfgVehicles says O_Soldier_F, the dump said O_soldier_F, config does not
    care which - and a lookup that did left a CSAT man inheriting from a
    class that was never declared in scope.
    """
    if src in new:
        return new[src]
    low = src.lower()
    for k, v in new.items():
        if k.lower() == low:
            return v
    return src


# THE PLA'S DRONES ARE CSAT'S - the east allocation, with the SwitchBlade tubes
# in the theatre's colour.
def _pla_extras(tubes):
    out = []
    for e in EXTRA_UNITS["jmfsb_CSAT"]:
        e = dict(e)
        for k in ("base", "name"):
            if k in e:
                e[k] = e[k].replace("_Woodland", "_" + tubes).replace("[CSAT]", "[PLA]")
        if "add_items" in e:
            e["add_items"] = [x.replace("_Woodland", "_" + tubes) for x in e["add_items"]]
        out.append(e)
    return out


EXTRA_UNITS["jmfsb_PLA_ard"] = _pla_extras("Desert")
EXTRA_UNITS["jmfsb_PLA_wdl"] = _pla_extras("Woodland")
# the west's tier-3 squads carry the IDAP demining Pelican as their second drone
for _f in EU_FACTIONS + ("jmfsb_Marine_wdl", "jmfsb_Marine_des"):
    EXTRA_UNITS.setdefault(_f, []).extend(_IDAP)
# THE MEDEVAC EVERY WEST FACTION FLIES (user, 2026-08-31: "change the base
# class to B_Heli_Transport_01_unarmed_F [...] add the new medevac to all eu
# and us factions try to camo properly"). The base game's medevac Ghost Hawk
# inherits a medevac base class and wears one fixed livery whatever theatre
# it is in; this one is the unarmed transport, so it carries troops, and it
# takes the theatre's own paint. Named for the faction that flies it.
_MEDEVAC_PAINT = dict(_EU_PAINT)
_MEDEVAC_PAINT.update((f, gh) for f, (gh, _hu, _lsv) in _JTF_PAINT.items())
# the Marines fly EF airframes and have no Ghost Hawk of their own; theirs
# takes the tropic and sand schemes their theatres wear
_MEDEVAC_PAINT.update({"jmfsb_Marine_wdl": "BLUFOR", "jmfsb_Marine_des": "sand"})


def medevac_extras():
    for fac in EU_FACTIONS + US_FACTIONS + ("jmfsb_Marine_wdl", "jmfsb_Marine_des"):
        name = "NH90 TTH (Medevac)" if fac in EU_FACTIONS else "UH-80 Ghost Hawk (Medevac)"
        e = {"kind": "veh", "base": "B_Heli_Transport_01_unarmed_F",
             "as": "B_Heli_Transport_01_medevac_F", "name": name,
             "why": "the medevac, on the unarmed transport and in the theatre's paint"}
        kind = _MEDEVAC_PAINT.get(fac)
        if kind:
            e["tex"] = _ghosthawk(kind)
        # A NEW LIST, NOT AN APPEND. EXTRA_UNITS gives the four JTF keys the
        # SAME _IDAP list object, so appending to one wrote the medevac into
        # all four - and then the loop below copied all four into every EU
        # faction. Four medevac classes of the same name in one CfgVehicles.
        EXTRA_UNITS[fac] = list(EXTRA_UNITS.get(fac, [])) + [e]


medevac_extras()

# the LDF carries SwitchBlade tubes like the AAF, so it fields the airframes too
EXTRA_UNITS.setdefault("jmfsb_LDF", []).extend([e for e in EXTRA_UNITS.get("jmfsb_AAF", []) if "SwitchBlade" in e.get("base", "")])

# ---------------------------------------------------------------------------
# DRONES ON THE SQUADS (user, 2026-08-28)
# ---------------------------------------------------------------------------
# docs/weapon_pools_2040.md: "every squad carries 2-3 drones - the SEO carries
# the primary, other members carry the rest". No squad did; the source rosters
# keep their drones in dedicated UAV teams, and ALiVE spawns groups, so an
# operator outside a group is never seen. So:
#   * every infantry, motorised and mechanised squad (4+ men, no drone man
#     already) gets ONE Drone Operator appended - the faction's rifleman with
#     the tier's recon bag and, east and independent, the SwitchBlade tubes
#     Drongo's Drone Tweaks fires (the FPV rows of the table: KVN and Crocus
#     left the load order);
#   * the squad's GRENADIER carries the second drone - a pack-less role, so no
#     loadout is lost;
#   * every bag is a CHILD of the source's that assembles THIS faction's own
#     drone class, where the faction fields one (a PLA operator deploys a PLA
#     Darter, not CSAT's); otherwise the source bag as it is.
# By tier: t0 the IED Pelican; t1 the UAV_02 quad + the IED quad (+ a 300 tube
# for the insurgents); t2 the Darter + AL-6 + both tubes (independents); t3-4
# the Darter + AL-6 medical + a SWITCHBLADE OPERATOR in every squad (east - user,
# 2026-08-28: the tubes ride with a man of their own, the "escort") or the Darter + IDAP demining
# Pelican (west - user: "west t3 gets Darter + IDAP Pelican"). Kedr is not in
# the load order. Tube colour follows the theatre.
def _sb(colour):
    return ["SwitchBlade_300_Tube_%s" % colour, "SwitchBlade_600_Tube_%s" % colour]


SQUAD_DRONES = {
    # east - the same load on every east force (user)
    # 2040 China (user, 2026-08-30: "make sure there's drones") - the same
    # east load every other east force carries.
    "jmfsb_Iran":       {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_backpack_F"},
    "jmfsb_Turkey":     {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_backpack_F"},
    "jmfsb_Russia":     {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_backpack_F"},
    "jmfsb_Russia_ard": {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_backpack_F"},
    "jmfsb_Russia_arc": {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_backpack_F"},
    "jmfsb_China":      {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_backpack_F"},
    "jmfsb_China_ard":  {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_backpack_F"},
    "jmfsb_CSAT":       {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator",   "second": "O_UAV_06_medical_backpack_F"},
    "jmfsb_CSAT_tna":   {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_medical_backpack_F"},
    "jmfsb_PLA_ard":    {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator",   "second": "O_UAV_06_medical_backpack_F"},
    "jmfsb_PLA_wdl":    {"bag": "O_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "O_UAV_06_medical_backpack_F"},
    "jmfsb_RAF_wdl":    {"bag": "E22_O_RAF_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "E22_O_RAF_UAV_06_medical_backpack_F"},
    "jmfsb_RAF_ard":    {"bag": "E22_O_RAF_D_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator",   "second": "E22_O_RAF_D_UAV_06_medical_backpack_F"},
    "jmfsb_RAF_alp":    {"bag": "E22_O_RAF_A_UAV_01_backpack_F", "tubes": [], "escort": "SwitchBlade_Operator", "second": "E22_O_RAF_A_UAV_06_medical_backpack_F"},
    # west, tier 3
    "jmfsb_US_JTF_wdl": {"bag": "B_UAV_01_backpack_F", "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_US_JTF_des": {"bag": "B_UAV_01_backpack_F", "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_US_JTF_tna": {"bag": "B_UAV_01_backpack_F", "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_US_JTF_ocp": {"bag": "B_UAV_01_backpack_F", "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_EUDF":       {"bag": "B_UAV_01_backpack_F",          "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_EUDF_wdl":   {"bag": "B_UAV_01_backpack_F",          "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_EUDF_des":   {"bag": "B_UAV_01_backpack_F",          "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_EUDF_tna":   {"bag": "B_UAV_01_backpack_F",          "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_EUDF_arc":   {"bag": "B_UAV_01_backpack_F",          "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_Marine_wdl": {"bag": "EF_B_UAV_01_backpack_coy", "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    "jmfsb_Marine_des": {"bag": "EF_B_UAV_01_backpack_coy", "tubes": [], "second": "C_IDAP_UAV_06_antimine_backpack_F"},
    # independents, tier 2
    "jmfsb_AAF":        {"bag": "I_UAV_01_backpack_F",   "tubes": _sb("Woodland"), "second": "I_UAV_06_backpack_F"},
    "jmfsb_LDF":        {"bag": "I_E_UAV_01_backpack_F", "tubes": _sb("Woodland"), "second": "I_E_UAV_06_backpack_F"},
    # irregulars, tier 1 (the FIA is west: no tubes)
    "jmfsb_FIA":        {"bag": "B_UAV_02_backpack_lxWS", "tubes": [], "second": "B_G_UAV_02_IED_backpack_lxWS"},
    "jmfsb_FIA_ind":    {"bag": "I_UAV_02_backpack_lxWS", "tubes": [], "second": "I_G_UAV_02_IED_backpack_lxWS"},
    "jmfsb_Insurgents": {"bag": "I_UAV_02_backpack_lxWS", "tubes": ["SwitchBlade_300_Tube_Woodland"], "second": "I_G_UAV_02_IED_backpack_lxWS"},
    # tier 0: the IED Pelican, and nothing else
    # the Syndikat has no grenadier: its second drone rides on a man of its own
    # (second_man), and its IED Pelican operator joins every squad too (user:
    # "low end drones and drones in the squad, IED ones")
    "jmfsb_Syndikat":   {"bag": "I_UAV_02_backpack_lxWS", "tubes": [], "second": "I_G_UAV_02_IED_backpack_lxWS",
                        "second_man": "IED_Quad_Operator", "escort": ["IED_Quad_Operator", "UAV_06_IED_Operator"]},
}

# ---------------------------------------------------------------------------
# TWIN FACTIONS - THE SAME ARMY ON ANOTHER SIDE
# ---------------------------------------------------------------------------
# A twin is generated from the same source roster and the same rules as its
# original; only the side differs. Copied here, in one loop, rather than
# restated across the seven tables that describe a faction - seven copies is
# seven chances for the twin to drift away from the thing it is a twin of.
FACTION_TWIN = {
    # 2040 Turkey, east and independent (user, 2026-09-01)
    "jmfsb_Turkey_ind": "jmfsb_Turkey",
}

for _twin, _orig in FACTION_TWIN.items():
    for _table in (ROSTER_ADD, GROUP_TEMPLATE, EXTRA_MAN_BASE, TIER,
                   RIFLE_SWAP, SQUAD_DRONES, KIT_SWAP, NOT_FIELDED,
                   NOT_FIELDED_VCLASS, IDENTITY, PACK_SWAP):
        if _orig in _table and _twin not in _table:
            _table[_twin] = _table[_orig]

# ---------------------------------------------------------------------------
# WHAT SIDE A FACTION IS
# ---------------------------------------------------------------------------
# Only for factions whose side is NOT simply their source roster's - a twin, or
# a roster that borrows kit from another side. Everything else is derived, see
# faction_side().
# jmfsb_Turkey is deliberately NOT listed: its roster is 135 east to 16 borrowed
# west, so the derivation below gets it right on its own, and leaving it to do so
# is what proves the fix rather than papering over it.
FACTION_SIDE = {
    "jmfsb_Turkey_ind": 2,   # independent - the same army as a third party
}

SIDE_NAME = {0: "east", 1: "west", 2: "independent", 3: "civilian"}


def faction_side(newfac, roster, units):
    """The side to stamp on every unit of a faction.

    ONE ARBITRARY UNIT USED TO DECIDE THIS. It read units[roster[0]]["side"],
    which is right only when a roster is all one side. 2040 Turkey is 135 east
    units and 16 borrowed west ones - HEMTTs, Hunters and three Athena
    airframes, deliberately added by ROSTER_ADD to be re-sided - and roster[0]
    landed on one of the sixteen, so the whole faction shipped as BLUFOR.

    Now: an explicit FACTION_SIDE wins, and otherwise the side is the one MOST
    of the roster is on. Every roster here spans sides - each carries a couple
    of civilian vehicles, and the east forces borrow a handful of NATO trucks
    that ROSTER_ADD adds precisely so they can be re-sided - so "they must all
    agree" would refuse to build anything. The majority is a decision the
    roster actually supports; roster[0] was a coin toss.

    The minority is NOT silent. Every unit being re-sided is named in the note
    the caller prints, so a faction that borrows something it did not mean to
    shows up in the build output instead of in a mission six weeks later.

    A tie has no answer and stops the build: say which side you meant.
    """
    if newfac in FACTION_SIDE:
        return FACTION_SIDE[newfac]

    seen = {}
    for c in roster:
        u = units.get(c)
        if u is None or "side" not in u:
            continue
        seen.setdefault(u["side"], []).append(c)

    if not seen:
        raise SystemExit("%s: no unit in the roster has a side" % newfac)

    ranked = sorted(seen, key=lambda s: -len(seen[s]))
    main = ranked[0]
    if len(ranked) > 1 and len(seen[ranked[1]]) == len(seen[main]):
        raise SystemExit(
            "%s: roster is evenly split between %s and %s - add it to FACTION_SIDE"
            % (newfac, SIDE_NAME.get(main, main), SIDE_NAME.get(ranked[1], ranked[1])))
    return main


def side_note(newfac, side, roster, units):
    """One line per side the roster carries that is not the faction's own."""
    seen = {}
    for c in roster:
        u = units.get(c)
        if u is not None and u.get("side") is not None and u["side"] != side:
            seen.setdefault(u["side"], []).append(c)
    out = []
    for s in sorted(seen, key=lambda s: -len(seen[s])):
        names = sorted(seen[s])
        out.append("  -- %s: %d %s unit(s) re-sided to %s: %s%s"
                   % (newfac, len(names), SIDE_NAME.get(s, s), SIDE_NAME.get(side, side),
                      ", ".join(names[:6]), " ..." if len(names) > 6 else ""))
    return out


# group categories that are squads; the rest (SpecOps, Support, Armored, Naval,
# Air, Artillery) keep their own shape
SQUAD_CATS = ("infantry", "motor", "mech")


# ---------------------------------------------------------------------------
# GROUPS A SOURCE NEVER HAD
# ---------------------------------------------------------------------------
# newfac -> [(class suffix, 3DEN name, category, [source classes...])]. The
# first member leads (a vehicle first means its crew leads, as the base game's
# motorised groups do); the men take the generator's wedge; the squad drone
# men join as they join every other squad. A member the faction does not
# field drops the whole group, said out loud.
#
# THE SYNDIKAT'S MOTORISED GROUPS (user, 2026-08-28): IND_C_F has the Jeeps,
# the technicals and the vans but only six foot groups; ALiVE motorised
# spawns need groups with a vehicle in them.
_BANDITS = ["I_C_Soldier_Bandit_4_F", "I_C_Soldier_Bandit_3_F", "I_C_Soldier_Bandit_7_F", "I_C_Soldier_Bandit_5_F",
            "I_C_Soldier_Bandit_6_F", "I_C_Soldier_Bandit_2_F", "I_C_Soldier_Bandit_8_F", "I_C_Soldier_Bandit_1_F"]
_PARAS = ["I_C_Soldier_Para_2_F", "I_C_Soldier_Para_4_F", "I_C_Soldier_Para_6_F", "I_C_Soldier_Para_1_F",
          "I_C_Soldier_Para_7_F", "I_C_Soldier_Para_5_F", "I_C_Soldier_Para_8_F", "I_C_Soldier_Para_3_F"]
# THE GENDARMERIE'S FOUR (user, 2026-08-29). BLU_GEN_F declares no groups of
# its own, so without these the faction spawns nothing under ALiVE and shows an
# empty tree in 3DEN. Four men to a group throughout - a commander and three
# constables - riding one truck in three of them and two in the fourth.
_GEN_TEAM = ["B_GEN_Commander_F", "B_GEN_Soldier_F", "B_GEN_Soldier_F", "B_GEN_Soldier_F"]
EXTRA_GROUPS = {
    "jmfsb_GEN": [
        ("Patrol_Comms",  "Gendarmerie Patrol (Comms)",   "Motorized",
         ["B_GEN_Offroad_01_comms_F"] + _GEN_TEAM),
        ("Patrol",        "Gendarmerie Patrol",           "Motorized",
         ["B_GEN_Offroad_01_covered_F"] + _GEN_TEAM),
        ("Patrol_Pickup", "Gendarmerie Pickup Patrol",    "Motorized",
         ["B_GEN_Pickup_covered_rf"] + _GEN_TEAM),
        ("Section",       "Gendarmerie Motorized Section", "Motorized",
         ["B_GEN_Offroad_01_comms_F", "B_GEN_Offroad_01_covered_F"] + _GEN_TEAM),
    ],
    "jmfsb_Syndikat": [
        ("BanditMotorized_LMG",   "Bandit Motorized Group (LMG)",     "Motorized", ["I_C_Offroad_02_LMG_F"] + _BANDITS[:5]),
        ("BanditMotorized_AT",    "Bandit Motorized Group (SPG-9)",   "Motorized", ["I_C_Offroad_02_AT_F"] + _BANDITS[:4]),
        ("BanditTechnical_HMG",   "Bandit Technical (HMG)",           "Motorized", ["I_C_Pickup_hmg_rf"] + _BANDITS[:4]),
        ("BanditMotorized_Truck", "Bandit Motorized Combat Group",    "Motorized", ["I_C_Van_01_transport_F"] + _BANDITS),
        ("ParaMotorized_LMG",     "Paramilitary Motorized Group (LMG)", "Motorized", ["I_C_Offroad_02_LMG_F"] + _PARAS[:5]),
        ("ParaTechnical_HMG",     "Paramilitary Technical (HMG)",     "Motorized", ["I_C_Pickup_hmg_rf"] + _PARAS[:4]),
        ("ParaMotorized_Van",     "Paramilitary Motorized Combat Group", "Motorized", ["I_C_Van_02_transport_F"] + _PARAS),
    ],
}


def wedge(i):
    """The wedge every generated group uses: leader at the point, the rest
    alternating right and left, five metres back a row."""
    if i == 0:
        return "[0,0,0]"
    row = (i + 1) // 2 * 5
    return "[%d,-%d,0]" % (row if i % 2 else -row, row)


def squad_drone_plan(newfac, new, ulow):
    """(bag-child config lines, operator bag class, second bag class) for a
    faction - the bags as children assembling the faction's own drone where it
    has one (roster or extras), the source's bag otherwise."""
    sd = SQUAD_DRONES.get(newfac)
    if not sd:
        return [], None, None
    lines, out = [], {}
    extras = dict((e["base"], "%s_%s" % (newfac, e.get("as", e["base"])))
                  for e in EXTRA_UNITS.get(newfac, []) if e.get("kind") == "veh")
    for key in ("bag", "second"):
        bag = sd.get(key)
        if not bag:
            out[key] = None
            continue
        drone = bag.replace("_backpack", "")
        own = new.get(ulow.get(drone.lower(), drone)) or extras.get(drone)
        if not own:
            out[key] = bag
            continue
        child = "%s_%s" % (newfac, bag)
        # assembleInfo IN FULL, all five fields. A nested class under a
        # forward-declared parent has nothing to inherit from at build time, so
        # a partial one silently loses every field it does not restate - which
        # is exactly what the RPT showed, once per bag per faction:
        #     No entry '.../<bag>/assembleInfo.primary'
        #     ... .assembleTo ... .displayName ... .dissasembleTo
        #
        # And the drone belongs in assembleTo, NOT base. "base" is the bag that
        # anchors a multi-part assembly and is empty for a one-bag drone; with
        # the drone in "base" these bags assembled into nothing of ours, in
        # every faction that has one.
        lines += ["    class %s;" % bag,
                  "    class %s: %s {" % (child, bag),
                  "        scope = 1;",
                  "        scopeCurator = 0;",
                  "        author = QAUTHOR;",
                  "        class assembleInfo {",
                  "            primary = 1;",
                  '            base = "";',
                  '            assembleTo = "%s";' % own,
                  '            displayName = "";',
                  "            dissasembleTo[] = {};",
                  "        };",
                  "    };   // assembles this faction's own drone"]
        out[key] = child
    return lines, out["bag"], out["second"]



# A faction's own art where the source's would be wrong: the PLA under the
# PRC flag the mod ships, not CSAT's.
FACTION_ART = {
    "jmfsb_PLA_ard": {"icon": r"\Main\Data\PRC_flag.paa", "flag": r"\Main\Data\PRC_flag.paa"},
    "jmfsb_PLA_wdl": {"icon": r"\Main\Data\PRC_flag.paa", "flag": r"\Main\Data\PRC_flag.paa"},
}


def emit_extras(newfac, addon, side, new, men, vanilla):
    """The classes in EXTRA_UNITS[newfac] as config lines: (lines, class names).

    Shared by main() and tools/apply_faction_extras.py, so an extra added
    while the dump is gone is written the same way a regeneration would
    write it. `new` maps source class -> this faction's class for everything
    the faction already fields; `men` is the source names of its men.
    """
    L, names = [], []
    extra = EXTRA_UNITS.get(newfac, [])
    if not extra:
        return L, names
    L.append("    // ---- fielded by this faction, not by its source ----")
    L.append("    // NEW CLASSES, NOT A SCRIPT. A man either is a drone")
    L.append("    // operator or is not; picking men out of a spawning group")
    L.append("    // and handing them a bag is a group composition decision,")
    L.append("    // and group composition is CfgGroups' job.")
    L.append("")
    manbase = EXTRA_MAN_BASE.get(newfac)
    for e in extra:
        if e["kind"] == "veh":
            base = e["base"]
            if is_dropped(base, vanilla, newfac):
                print("  -- %s: extra %s is a dropped mod's - skipped" % (addon, base))
                continue
            if base in new and not e.get("as"):
                # The source faction fields it after all - the roster
                # already built it, crew and all, and a second class of
                # the same name is a config error. Say so and move on.
                # AN ENTRY WITH "as" IS NOT A COLLISION: it is written under
                # its own name, so the base being in the roster is the point -
                # the medevac IS the unarmed transport, with a red cross.
                print("  -- %s: extra %s is already in the roster - skipped" % (addon, base))
                continue
            cls = "%s_%s" % (newfac, e.get("as", base))
            if base not in new:
                L.append("    class %s;" % base)
            L.append("    class %s: %s {" % (cls, base))
            L += ["        scope = 2;",
                  "        scopeCurator = 2;",
                  "        author = QAUTHOR;",
                  '        displayName = "%s";' % e["name"],
                  "        side = %d;" % side,
                  '        faction = "%s";' % newfac]
            if e.get("crew"):
                # A crewed vehicle needs this faction's men in it or it
                # spawns with the source faction's. Resolved through the
                # roster the same way the roster's own crews are.
                cr = e["crew"]
                if is_dropped(cr, vanilla, newfac):
                    cr = pick_crew(cr, men)
                if cr:
                    L.append('        crew = "%s";' % resolve(new, cr))
            for ln in e.get("props", []):
                # Raw config lines, comments included, for the handful of
                # borrowed classes that need one property put right. Written
                # verbatim so the reason travels with them - see EDEN_TURRET.
                L.append("        %s" % ln)
            if e.get("tex") and not any(DROP_PATH.search(x) for x in e["tex"]):
                # hiddenSelectionsTextures, NOT a TextureSources entry -
                # this is the skin it wears when it spawns, not an option
                # in the editor's dropdown.
                L.append("        hiddenSelectionsTextures[] = {")
                for i, tx in enumerate(e["tex"]):
                    L.append('            "%s"%s' % (tx, "," if i < len(e["tex"]) - 1 else ""))
                L.append("        };")
            L.append("    };%s" % ("   // " + e["why"] if e.get("why") else ""))
        else:
            # A rifleman who carries one system instead of a rucksack.
            bp = e.get("backpack")
            if bp and is_dropped(bp, vanilla, newfac):
                # The system went with its mod; so does the man who
                # carried it. A rifleman with nothing on his back is
                # just a rifleman, and the roster has those.
                print("  -- %s: extra %s carries a dropped mod's %s - skipped"
                      % (addon, e["suffix"], bp))
                continue
            parent = resolve(new, manbase)
            cls = "%s_%s" % (newfac, e["suffix"])
            L += ["    class %s: %s {" % (cls, parent),
                  "        scope = 2;",
                  "        scopeCurator = 2;",
                  "        author = QAUTHOR;",
                  '        displayName = "%s";' % e["name"],
                  '        faction = "%s";' % newfac]
            if bp:
                L.append('        backpack = "%s";' % bp)
            if e.get("add_weapons"):
                # += APPENDS. Writing weapons[] = {...} here would take
                # away the rifle, the sidearm and the binoculars along
                # with everything else the parent gave him.
                a = ",".join('"%s"' % w for w in e["add_weapons"])
                L.append("        weapons[] += {%s};" % a)
                L.append("        respawnWeapons[] += {%s};" % a)
            if e.get("add_mags"):
                a = ",".join('"%s"' % w for w in e["add_mags"])
                L.append("        magazines[] += {%s};" % a)
                L.append("        respawnMagazines[] += {%s};" % a)
            if e.get("add_items"):
                # Inventory items - the SwitchBlade tubes are CBA_MiscItems,
                # not magazines, and DDT looks for them in `items`.
                a = ",".join('"%s"' % w for w in e["add_items"])
                L.append("        items[] += {%s};" % a)
                L.append("        respawnItems[] += {%s};" % a)
            L.append("    };%s" % ("   // " + e["why"] if e.get("why") else ""))
        names.append(cls)
    L.append("")
    return L, names


def crlf(path, lines):
    io.open(path, "w", encoding="utf-8", newline="\r\n").write("\n".join(lines) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rpt")
    args = ap.parse_args()

    rpt = args.rpt or R.newest_rpt()
    if not rpt or not os.path.exists(rpt):
        print("no RPT given and none found - pass --rpt <path>")
        return 2

    facside, facprops, units, props, groups, gprops, gmen = R.read(rpt)
    # see DUMP_PARENT - the index cannot be trusted alone
    DUMP_PARENT.clear()
    for _c, _u in units.items():
        if _u.get("parent"):
            DUMP_PARENT[_c] = _u["parent"]
            DUMP_PARENT.setdefault(_c.lower(), _u["parent"])
    WEAPONS_DB.update(R.read_weapons(rpt))
    WLOW.update((k.lower(), k) for k in WEAPONS_DB)
    if WEAPONS_DB:
        print("weapons %d class(es) with muzzle slots - see SUPPRESS_TIER" % len(WEAPONS_DB))
    else:
        print("!! the dump has no WEAPON lines - NO SUPPRESSORS this build; re-run tools/dump_orbat.sqf in game")
    if not units:
        print("%s holds no UNIT records - wrong RPT?" % rpt)
        return 2
    print("read   %s" % rpt)

    # THE PLA MOD'S VEHICLES join the dump here - see PLA_INDEX.
    import json as _json
    for c, rec in PLA_INDEX.items():
        if c in units:
            continue
        units[c] = {"faction": rec.get("faction", "PLA_Armored_Force").lower(),
                    "parent": rec.get("parent", ""), "side": int(rec.get("side", 0)), "scope": 2}
        pr = {"displayName": ("txt", rec.get("displayName") or c),
              "vehicleClass": ("txt", rec.get("vehicleClass", "")),
              "scopeCurator": ("num", rec.get("scopeCurator", "2")),
              "side": ("num", str(rec.get("side", 0)))}
        for k in ("crew", "editorSubcategory"):
            if rec.get(k):
                pr[k] = ("txt", rec[k])
        for k in ("hiddenSelections", "hiddenSelectionsTextures"):
            if rec.get(k):
                pr[k] = ("arr", _json.dumps(rec[k]))
        props[c] = pr
    if PLA_INDEX:
        facside.setdefault("pla_armored_force", 0)
        print("merged %d PLA vehicle(s) from %s" % (len(PLA_INDEX), os.path.relpath(PLA_INDEX_PATH, ROOT)))

    # QAV'S VEHICLES, on the same terms - see QAV_INDEX. The dump wins wherever
    # it has a record, so this only fills the gap the 30 August snapshot left.
    qav_new = []
    for c, rec in QAV_INDEX.items():
        if c in units:
            continue
        units[c] = {"faction": (rec.get("faction") or "").lower(),
                    "parent": rec.get("parent", ""), "side": int(rec.get("side", 1)), "scope": 2}
        pr = {"displayName": ("txt", rec.get("displayName") or c),
              "vehicleClass": ("txt", rec.get("vehicleClass", "")),
              "scopeCurator": ("num", str(rec.get("scopeCurator", "2"))),
              "side": ("num", str(rec.get("side", 1)))}
        for k in ("crew", "editorSubcategory"):
            if rec.get(k):
                pr[k] = ("txt", rec[k])
        for k in ("hiddenSelections", "hiddenSelectionsTextures"):
            if rec.get(k):
                pr[k] = ("arr", _json.dumps(rec[k]))
        props[c] = pr
        facside.setdefault((rec.get("faction") or "").lower(), int(rec.get("side", 1)))
        qav_new.append(c)
    if qav_new:
        print("merged %d QAV vehicle(s) the dump has no record of, from %s: %s"
              % (len(qav_new), os.path.relpath(QAV_INDEX_PATH, ROOT), ", ".join(sorted(qav_new))))
    elif QAV_INDEX:
        print("QAV index read: every class in it is already in the dump - nothing merged")

    ulow = dict((k.lower(), k) for k in units)

    vanilla = load_vanilla()
    if vanilla is None:
        # NOT FATAL, BUT SAID LOUDLY. Without the index only the prefixed
        # classes can be dropped; the plain-named ones Aegis adds to the base
        # game's factions will be built as if they were the base game's.
        print("!! work/vanilla_vehicles.json is missing - run tools/gen_vanilla_vehicles.py")
        print("   Only %s-prefixed classes will be dropped this run." % "/".join(DROP_MODS))
    # A CHOSEN ROUND IS ONLY USABLE IF fa_tiers ACTUALLY BUILT A TIER FOR IT.
    # Only rounds declaring a lethality figure are tiered, so the two sets are
    # not the same - and a magazine that does not exist is a soldier with none.
    # fa_tiers holds the base-game rounds' tiers, fa_tiers_mods (Aegis) and fa_tiers_<source> the optional sources'
    # (E22's 5.45 among them); a faction on a mod's rifle needs both read.
    t3 = set()
    for tiers in sorted(d for d in os.listdir(ADDONS) if d.startswith("fa_tiers")):
        tp = os.path.join(ADDONS, tiers, "CfgMagazines.hpp")
        if os.path.exists(tp):
            t3 |= set(re.findall(r"^\s*class ([A-Za-z0-9_]+)_t[234]:",
                                 io.open(tp, encoding="utf-8", errors="replace").read(), re.M))

    def fa_for(newfac):
        """This faction's vanilla -> FA map, tiered rounds only."""
        m, _cand = fa_map(ADDONS, FA_PREFER.get(newfac, "FA_b_"))
        return dict((v, f) for v, f in m.items() if f in t3)

    famap, _cand = fa_map(ADDONS)
    dropped_no_t3 = sorted(v for v, f in famap.items() if f not in t3)
    famap = dict((v, f) for v, f in famap.items() if f in t3)
    swapped = [0]
    swapped_w = [0]
    suppressed = [0]
    moved = {"sf": 0, "men": 0}     # men whose editor category collapsed - see SUBCAT_KEEP
    no_can = {}        # weapon -> men: a muzzle slot with no suppressor this faction may fit
    kitn = [0]
    kit_unmapped = {}

    total_u = total_g = 0
    dropped = [0]
    squads_armed = [0]
    for addon, beaut, newfac, disp, src in TARGETS:
        # ---- what this faction fields ---------------------------------
        shed = []
        # EDITOR CATEGORIES - see SUBCAT_KEEP. Planned before keep(), which
        # refuses the duplicates and the VR men; the twin takes a duplicate's
        # group slots (gsub, below); the emitter restates the category of a
        # man who moves.
        plain_by_name = {}
        for c0, u0 in units.items():
            if u0["faction"] == src and u0["scope"] == 2 \
                    and prop_inh(units, props, c0, "editorSubcategory") == "EdSubcat_Personnel" \
                    and R.is_man(prop_inh(units, props, c0, "vehicleClass"), props.get(c0, {})):
                plain_by_name.setdefault(prop_inh(units, props, c0, "displayName"), c0)

        def subcat_of(c0):
            """'keep' | 'sf' | 'men' | 'out' | ('dupe', twin) for a man."""
            sc = prop_inh(units, props, c0, "editorSubcategory")
            if sc in SUBCAT_KEEP or not sc:
                return "keep"
            if sc in SUBCAT_SF:
                return "sf"
            if sc in SUBCAT_OUT:
                return "out"
            twin = plain_by_name.get(prop_inh(units, props, c0, "displayName"))
            if twin and twin != c0 and units.get(twin, {}).get("faction") == src:
                return ("dupe", twin)
            return "men"

        subcat_gone = []

        def keep(c, explicit=False):
            """`explicit` is a class ROSTER_ADD names by hand. The origin test
            below reads the CLASS NAME to decide which mod a class came from,
            and a mod that does not sign its classes fails it: Atlas files the
            C-192 Samson as B_A_Plane_Transport_01_*_tna_F, which says nothing
            about Atlas, so it was ruled a dropped mod's and refused in
            silence. A class named in the table has already been chosen; if
            its mod is really gone, the dump has no record of it and the
            caller says so."""
            pr = props.get(c, {})
            vc = pr.get("vehicleClass", (None, ""))[1] or ""
            if vc in R.SKIP_VCLASS:
                return False
            if R.is_man(vc, pr):
                plan = subcat_of(c)
                if plan == "out" or isinstance(plan, tuple):
                    # a duplicate of a man in plain Men, or a VR entity
                    if c not in subcat_gone:
                        subcat_gone.append(c)
                    return False
            vcs, unless = NOT_FIELDED_VCLASS.get(newfac, ((), None))
            if vc in vcs and not (unless and unless(c.lower())):
                # a category this faction does not field - see the table
                if c not in shed:
                    shed.append(c)
                return False
            if not explicit and is_dropped(c, vanilla, newfac):
                # A dropped mod's class - see DROP_MODS. Recorded so the run
                # report says what went, not just how many.
                if c not in shed:
                    shed.append(c)
                return False
            # The Ram 1500 technicals are out of the US and the Marines (see
            # is_ram) - and exactly right for the irregulars, who keep them.
            if newfac in US_FACTIONS or newfac.startswith("jmfsb_Marine"):
                return not is_ram(c, pr.get("displayName", (None, ""))[1] or "")
            return True

        roster = [c for c, u in units.items()
                  if u["faction"] == src and u["scope"] == 2 and keep(c)]

        # A mod's CfgGroups can file its groups under a different faction
        # name than CfgFactionClasses uses - E22 does. GROUP_ALIAS maps one
        # to the other; the base game needs no entry.
        #
        # OR THE TEMPLATE'S, so the four JTF theatres field one order of
        # battle - see GROUP_TEMPLATE.
        tmpl_src = (GROUP_TEMPLATE.get(newfac) or "").lower()
        gkeys = {tmpl_src} if tmpl_src else {src, GROUP_ALIAS.get(src, src)}
        mine = [g for g in groups if groups[g].get("faction", "").lower() in gkeys]

        # Anything a group names, at whatever scope - see the header. Resolved
        # case-insensitively: CfgGroups says B_soldier_SL_F where CfgVehicles
        # declares B_Soldier_SL_F, and config does not care which.
        gsub = dict(GROUP_SUB.get(newfac, {}))
        # THE TEMPLATE'S MEN GET THE SAME EDITOR-CATEGORY TREATMENT. A faction
        # that borrows a roster or an order of battle (GROUP_TEMPLATE /
        # ROSTER_TEMPLATE) would otherwise keep every duplicate the template
        # faction itself collapses, and the two would not be equal after all.
        _srcs = {src}
        for _t in (GROUP_TEMPLATE.get(newfac), ROSTER_TEMPLATE.get(newfac)):
            if _t:
                _srcs.add(_t.lower())
        for c0, u0 in units.items():
            if u0["faction"] in _srcs:
                plan = subcat_of(c0)
                if isinstance(plan, tuple):
                    gsub.setdefault(c0, plan[1])
        if subcat_gone:
            print("  -- %s: %d man/men in a removed editor category (duplicates of plain Men, VR): %s%s"
                  % (addon, len(subcat_gone), ", ".join(subcat_gone[:4]), "..." if len(subcat_gone) > 4 else ""))
        if newfac.startswith("jmfsb_RAF_"):
            # E22's groups name the west RAF's classes; the east twin, where the
            # dump has one, takes the slot - see NOT_FIELDED "west RAF classes".
            for c in units:
                if c.startswith("E22_B_RAF"):
                    twin = "E22_O_RAF" + c[len("E22_B_RAF"):]
                    if twin in units:
                        gsub.setdefault(c, twin)
        # THE TEMPLATE'S MEN, IN OUR CLASSES - see GROUP_TEMPLATE. Read off
        # the roster this faction already has, by role; first hit wins, and a
        # class the faction owns beats every alias. Written into gsub, which
        # the roster loop below and the group emitter both already honour.
        if tmpl_src:
            byrole = {}
            for c0 in sorted(roster):
                byrole.setdefault(role_key(c0), c0)
            borrowed = []
            _twin = VEHICLE_TWIN.get(newfac)

            def borrow(c0):
                """The class this faction fields in place of a template one.

                A man is re-dressed by KIT_SWAP and comes across as he is; a
                vehicle cannot be re-textured, so its base-game twin in this
                faction's camo is taken where the load order has one. Decided
                HERE and nowhere else, or the group template and the roster
                template each bring in their own copy.
                """
                if not _twin:
                    return c0
                pr0 = props.get(c0, {})
                if R.is_man(pr0.get("vehicleClass", (None, ""))[1] or "", pr0):
                    return c0
                for cand in _twin(c0):
                    real_c = ulow.get(cand.lower())
                    if real_c and real_c in units and keep(real_c):
                        return real_c
                return c0
            for g in mine:
                for veh, _rank, _pos in R.gmen_values(gmen, g):
                    real = ulow.get(veh.lower(), veh)
                    if real in gsub or real in roster:
                        continue
                    key = role_key(real)
                    own = byrole.get(key)
                    if not own:
                        for alt in ROLE_ALIAS.get(key, ()):
                            own = byrole.get(alt)
                            if own:
                                break
                    if own:
                        gsub[real] = own
                    elif not keep(real):
                        # the template faction would not field it either - see
                        # the same guard on the roster template below
                        continue
                    else:
                        take = borrow(real)
                        if take != real:
                            gsub[real] = take
                        if take not in borrowed:
                            borrowed.append(take)
            # EQUAL IN UNITS TOO - see ROSTER_TEMPLATE. The group template
            # above borrows only what its groups name; this brings across the
            # rest of the template faction's roster, so both factions field
            # the same list of units and not merely the same groups.
            rsrc = (ROSTER_TEMPLATE.get(newfac) or "").lower()
            if rsrc:
                for c0, u0 in sorted(units.items()):
                    if u0["faction"] != rsrc or u0["scope"] != 2:
                        continue
                    if role_key(c0) in byrole:
                        continue          # this faction has its own already
                    if not keep(c0):
                        # THE TEMPLATE FACTION ITSELF WOULD NOT FIELD IT, so
                        # neither do we - a borrower that ends up with classes
                        # the faction it copies does not have is the opposite
                        # of equal. (It was the drone backpacks: a Backpacks
                        # vehicleClass is not a unit and the tropical faction
                        # drops them, but their hex twins sailed past the
                        # check because the dump logs no properties for them.)
                        continue
                    pick = borrow(c0)
                    if role_key(pick) in byrole:
                        continue
                    if pick not in roster and keep(pick):
                        roster.append(pick)
                        byrole.setdefault(role_key(pick), pick)
                        if pick not in borrowed:
                            borrowed.append(pick)

            if borrowed:
                # NOT A WARNING. A borrow is the template's own class fielded
                # under our name because this theatre has no equivalent - the
                # woodland JTF's recon, divers and sniper are all borrows. It
                # is printed so the kit it turns up in is somebody's decision
                # rather than a surprise; KIT_SWAP re-dresses them.
                shown = sorted(borrowed)
                print("  -- %s: %d borrowed from %s (no equivalent of its own): %s%s"
                      % (addon, len(borrowed), tmpl_src.upper(), ", ".join(shown[:12]),
                         " ..." if len(shown) > 12 else ""))

        for g in mine:
            for veh, _rank, _pos in R.gmen_values(gmen, g):
                real = ulow.get(veh.lower())
                real = gsub.get(real, real)
                if real and real not in roster and keep(real):
                    roster.append(real)
        # ROSTER_ADD - dumped classes this faction fields that its source
        # does not list. Said out loud when one is not in the dump at all.
        for c in ROSTER_ADD.get(newfac, []):
            real = ulow.get(c.lower())
            if not real:
                print("  -- %s: ROSTER_ADD %s is not in the dump - skipped" % (addon, c))
            elif real not in roster and keep(real, explicit=True):
                roster.append(real)
        roster = sorted(set(roster))

        if not roster:
            print("  !! %s: source faction %s fields nothing - skipped" % (addon, src))
            continue

        new = dict((c, "%s_%s" % (newfac, c)) for c in roster)

        # DRONES ON THE SQUADS - see SQUAD_DRONES. The bag children are written
        # with the extras; the operator is an extra man; the grenadier's
        # second bag is written on his class; the squads get the operator.
        bag_lines, op_bag, second_bag = squad_drone_plan(newfac, new, ulow)
        operator = None
        if op_bag and EXTRA_MAN_BASE.get(newfac):
            sd = SQUAD_DRONES[newfac]
            operator = "%s_Drone_Operator" % newfac
            EXTRA_UNITS.setdefault(newfac, [])
            if not any(e.get("suffix") == "Drone_Operator" for e in EXTRA_UNITS[newfac]):
                EXTRA_UNITS[newfac].append(
                    {"kind": "man", "suffix": "Drone_Operator", "name": "Drone Operator [%s]" % disp.replace("2040 ", ""),
                     "backpack": op_bag, "add_items": sd.get("tubes") or None,
                     "why": "the squad's drones - see SQUAD_DRONES"})
            if sd.get("second_man") and second_bag and not any(e.get("suffix") == sd["second_man"] for e in EXTRA_UNITS[newfac]):
                EXTRA_UNITS[newfac].append(
                    {"kind": "man", "suffix": sd["second_man"], "name": "%s [%s]" % (sd["second_man"].replace("_", " "), disp.replace("2040 ", "")),
                     "backpack": second_bag, "why": "the squad's second drone, where there is no grenadier to carry it"})
        extra_names = []
        men = [c for c in roster
               if R.is_man(props.get(c, {}).get("vehicleClass", (None, ""))[1] or "",
                           props.get(c, {}))]
        recrewed = []
        tier = TIER.get(newfac, DEFAULT_TIER)
        tier_sfx = "_t%d" % tier
        presets = {}       # weapon -> (preset class, can) - see SUPPRESS_TIER
        forced = [0]       # men kitted by hand - see FORCE_LOADOUT
        famap = fa_for(newfac)
        # Looked up case-insensitively: the dump writes the uniform the way the
        # unit config spelt it, and E22 spells its shirts both ways.
        kit = dict((k.lower(), v) for k, v in KIT_SWAP.get(newfac, {}).items())
        side = faction_side(newfac, roster, units)
        for _ln in side_note(newfac, side, roster, units):
            print(_ln)

        path = os.path.join(ADDONS, addon)
        if not os.path.isdir(path):
            os.makedirs(path)

        crlf(os.path.join(path, "$PBOPREFIX$"), ["z\\jmfsb\\addons\\" + addon])
        crlf(os.path.join(path, "script_component.hpp"), [
            "#define COMPONENT " + addon,
            "#define COMPONENT_BEAUTIFIED " + beaut,
            '#include "\\z\\jmfsb\\addons\\main\\script_mod.hpp"',
            "",
            "// #define DEBUG_MODE_FULL",
            "// #define DISABLE_COMPILE_CACHE",
            "",
            '#include "\\z\\jmfsb\\addons\\main\\script_macros.hpp"',
        ])

        # ---- CfgFactionClasses ----------------------------------------
        fp = {}
        for k in facprops:
            if k.lower() == src:
                fp = facprops[k]
                break
        L = [HDR.rstrip("\n"),
             "// A NEW FACTION, NOT A CHANGE TO %s. The source faction is left" % src.upper(),
             "// exactly as its mod ships it; this sits beside it, so a mission",
             "// using the original is untouched and the two are one glance apart",
             "// in 3DEN and Zeus.",
             "",
             "class CfgFactionClasses {",
             "    class NO_CATEGORY;",
             "",
             "    class %s: NO_CATEGORY {" % newfac,
             '        displayName = "%s";' % disp,
             "        author = QAUTHOR;",
             "        side = %d;" % side,
             "        priority = %s;" % (fp.get("priority") or "1")]
        for n in ("icon", "flag"):
            v = FACTION_ART.get(newfac, {}).get(n) or fp.get(n)
            if v and DROP_PATH.search(v):
                # The source faction's art lives in a dropped mod's PBO. The
                # base game's side art stands in.
                v = VANILLA_ART[n].get(side)
            if v:
                L.append('        %s = "%s";' % (n, v))
        L += ["    };", "};"]
        crlf(os.path.join(path, "CfgFactionClasses.hpp"), L)

        # ---- CfgVehicles ----------------------------------------------
        L = [HDR.rstrip("\n"),
             "// FORWARD DECLARATIONS, NOT DEPENDENCIES. Every parent below",
             "// belongs to somebody else's mod. Declaring it means a load order",
             "// without that mod gets an inert class rather than a config that",
             "// refuses to build - see requiredAddons in config.cpp.",
             "",
             "class CfgVehicles {"]
        _ext = list(roster)
        # THE EXTRA MEN'S BASE, TOO - see EXTRA_MAN_BASE. The drone operator
        # and the SwitchBlade man inherit from the faction's own rifleman, and
        # that rifleman is not always ON the roster (2040 Russia (Arctic) is
        # built from a source whose CF_O_R_Soldier_F is scope 1). An
        # undeclared parent is an L-C04 build error, and the whole point of
        # this block is that a parent from somebody else's mod is declared.
        _emb = EXTRA_MAN_BASE.get(newfac)
        if _emb and _emb not in _ext:
            _ext.append(_emb)
        for c in _ext:
            L.append("    class %s;" % c)
        L.append("")

        for c in roster:
            u = units[c]
            pr = props.get(c, {})
            gv = lambda n: pr.get(n, (None, None))[1]
            man = R.is_man(gv("vehicleClass") or "", pr)

            L += ["    class %s: %s {" % (new[c], c),
                  "        scope = %d;" % u["scope"],
                  "        scopeCurator = %s;" % (gv("scopeCurator") or "2"),
                  "        author = QAUTHOR;",
                  '        displayName = "%s";' % display(c, gv("displayName") or c, gv("editorSubcategory") or "", newfac),
                  # THE FACTION'S side, not the source class's: a west radar
                  # in an east faction answers to the east - see _CLAMSHELL.
                  "        side = %d;" % side,
                  '        faction = "%s";' % newfac]
            # vehicleClass and editorSubcategory are NOT re-emitted. The class
            # inherits both from its parent, so writing them again is pure
            # duplication - and it made check_plumbing flag 291 base-game
            # categories it has no reason to know about. THE EXCEPTION: a man
            # whose category collapses into Men or Men (Special Forces) - see
            # SUBCAT_KEEP.
            if man:
                plan = subcat_of(c)
                if plan in SUBCAT_WRITE:
                    sub_, vcl_ = SUBCAT_WRITE[plan]
                    L.append('        editorSubcategory = "%s";' % sub_)
                    L.append('        vehicleClass = "%s";' % vcl_)
                    moved[plan] += 1
            if not man and gv("crew"):
                # The crew class is the FACTION'S OWN if it fields one, so a
                # jmfsb_US vehicle does not spawn with somebody else's men.
                cr = gv("crew")
                # THE NAVY CREWS THE BOATS - see BOAT_CREW.
                bc = BOAT_CREW.get(newfac)
                if bc and gv("vehicleClass") == "Ship":
                    real_bc = ulow.get(bc.lower())
                    if real_bc in new:
                        cr = real_bc
                if cr in new:
                    L.append('        crew = "%s";' % new[cr])
                elif is_dropped(cr, vanilla, newfac):
                    # The source crewed it with a dropped mod's men - Aegis
                    # put its own boat crew in the EF boats. This faction's
                    # own man takes the seat - see pick_crew; failing that
                    # the line is left out and the parent's crew stands.
                    sub = pick_crew(cr, men)
                    if sub:
                        L.append('        crew = "%s";' % new[sub])
                    recrewed.append((c, cr, sub))
                else:
                    # A crew from outside this roster - QAV's Knights come
                    # with NATO's B_crew_F. This faction's own man if it has
                    # one fit for the seat, the source's otherwise.
                    if "uav_ai" in cr.lower() and u["side"] != side and cr[:2] in ("B_", "O_", "I_"):
                        # AN AUTONOMOUS SYSTEM FROM ANOTHER SIDE - JK's Clam
                        # Shell in an east faction - gets this side's UAV AI,
                        # or the radar would answer to the west.
                        cr = {0: "O_", 1: "B_", 2: "I_"}[side] + cr[2:]
                        if cr.lower() not in ulow and cr.lower().endswith("_f"):
                            cr = cr[:-2]
                    sub = pick_crew(cr, men)
                    if not sub:
                        # NO CREWMAN OF ITS OWN. pick_crew only matches men
                        # whose class says crew or pilot, and a faction like
                        # the Syndikat has neither - so an emplaced weapon
                        # borrowed from another side kept ITS crew, and the
                        # bandits' Super-Dragon and SwitchBlade tubes spawned
                        # a NATO rifleman inside them. The faction's own base
                        # man takes the seat instead.
                        base = EXTRA_MAN_BASE.get(newfac)
                        real_base = ulow.get((base or "").lower())
                        if real_base and real_base in new:
                            sub = real_base
                    L.append('        crew = "%s";' % (new[sub] if sub else cr))

            # VEHICLE CAMO - see VEH_TEX. Written after the crew, before the
            # kit, so the class reads: who it is, who drives it, what it wears.
            vt = VEH_TEX.get(newfac, {}).get(c)
            if vt and not man and not any(DROP_PATH.search(x) for x in vt.get("tex", [])):
                if vt.get("tl"):
                    # a paint the mod names (TextureSources) - RF's pickups
                    L.append('        textureList[] = {"%s", 1};' % vt["tl"])
                elif vt.get("notl"):
                    L.append("        textureList[] = {};")
                if vt.get("sel"):
                    L.append("        hiddenSelections[] = {%s};" % ",".join('"%s"' % x for x in vt["sel"]))
                if vt.get("tex"):
                    L.append("        hiddenSelectionsTextures[] = {")
                    for i, t in enumerate(vt["tex"]):
                        L.append('            "%s"%s' % (t, "," if i < len(vt["tex"]) - 1 else ""))
                    L.append("        };")

            # WHO THE MEN ARE - see IDENTITY.
            if man and newfac in IDENTITY:
                L.append("        identityTypes[] = {%s};" % ",".join('"%s"' % x for x in IDENTITY[newfac]))

            # THE LOADOUT WRITTEN OUT IN FULL - see FORCE_LOADOUT. Set before
            # the swap blocks below and they are all skipped for this man: he
            # is not wearing a substituted version of somebody else's kit, he
            # is wearing what he was given.
            # FIRST ENTRY THAT NAMES THIS CLASS - see FORCE_LOADOUT. An old
            # single-dict entry still reads as a one-entry list.
            forcelist = FORCE_LOADOUT.get(newfac) if man else None
            if isinstance(forcelist, dict):
                forcelist = [forcelist]
            force = next((f for f in (forcelist or []) if c.lower() in f["units"]), None)
            force_hit = force is not None
            if force_hit:
                arrf = lambda xs: "{" + ",".join('"%s"' % x for x in xs) + "}"
                L += ['        uniformClass = "%s";' % force["uniform"],
                      "        weapons[] = %s;" % arrf(force["weapons"]),
                      "        respawnWeapons[] = %s;" % arrf(force["weapons"]),
                      "        magazines[] = %s;" % arrf(force["magazines"]),
                      "        respawnMagazines[] = %s;" % arrf(force["magazines"]),
                      "        linkedItems[] = %s;" % arrf(force["linked"]),
                      "        respawnLinkedItems[] = %s;" % arrf(force["linked"]),
                      "        items[] = %s;" % arrf(force["items"]),
                      "        respawnItems[] = %s;" % arrf(force["items"]),
                      '        backpack = "%s";' % force["backpack"]]
                forced[0] += 1

            # KIT SUBSTITUTION - see KIT_SWAP. uniformClass and linkedItems
            # are inherited and normally left unstated; a faction wearing
            # somebody else's kit is exactly the case where they must be
            # written out.
            if kit and not force_hit:
                uni = gv("uniformClass")
                if uni:
                    if uni.lower() in kit:
                        L.append('        uniformClass = "%s";' % kit[uni.lower()])
                        kitn[0] += 1
                    elif uni not in KIT_KEEP:
                        kit_unmapped[uni] = kit_unmapped.get(uni, 0) + 1
                rawl = gv("linkedItems")
                if rawl:
                    outl, hitl = [], False
                    for it in re.findall(r'"([^"]+)"', rawl):
                        # FACEWEAR CANNOT BE A LINKED ITEM. The dump read the
                        # unit's live loadout, and that array includes goggles -
                        # but goggles are CfgGlasses, and a config linkedItems[]
                        # entry is resolved in CfgWeapons. The engine then
                        # fabricates an empty weapon per spawn and floods the
                        # RPT: "creating weapon G_Balaclava_blk with
                        # scope=private" plus forty No-entry lines each time.
                        if re.match(r"^(?:[A-Za-z0-9]+_)?G_", it):
                            hitl = True
                            continue
                        if it.lower() in kit:
                            outl.append(kit[it.lower()])
                            kitn[0] += 1
                            hitl = True
                        else:
                            if it[:2] in ("V_", "H_") and it not in KIT_KEEP:
                                kit_unmapped[it] = kit_unmapped.get(it, 0) + 1
                            outl.append(it)
                    if hitl:
                        arrl = "{" + ",".join('"%s"' % x for x in outl) + "}"
                        L.append("        linkedItems[] = %s;" % arrl)
                        L.append("        respawnLinkedItems[] = %s;" % arrl)

            # THE PACKS - see PACK_SWAP: the same loaded pack in the faction's skin.
            bp0 = "" if force_hit else gv("backpack")
            if man and not force_hit and second_bag and "_GL_" in c:
                # THE GRENADIER CARRIES THE SQUAD'S SECOND DRONE - see SQUAD_DRONES
                L.append('        backpack = "%s";' % second_bag)
            elif man and bp0 and newfac in PACK_SWAP and bp0 in PACK_SWAP[newfac]:
                L.append('        backpack = "%s";' % PACK_SWAP[newfac][bp0])

            # RIFLE SUBSTITUTION - see RIFLE_SWAP.
            rules = None if force_hit else RIFLE_SWAP.get(newfac)
            raww = gv("weapons")
            wlist = re.findall(r'"([^"]+)"', raww) if raww else []
            hitw = False
            if rules and wlist:
                outw = []
                for wp in wlist:
                    rep = None
                    for test, new_w in rules:
                        if rule_hit(test, wp, c):
                            rep = new_w      # None: matched, and left alone
                            break
                    if rep:
                        outw.append(rep)
                        swapped_w[0] += 1
                        hitw = True
                    else:
                        outw.append(wp)
                wlist = outw
            # SUPPRESSORS - see SUPPRESS_TIER. The preset is named for the
            # weapon and written once per addon (presets -> CfgWeapons.hpp).
            if man and not force_hit and tier >= SUPPRESS_TIER and WEAPONS_DB and wlist:
                outw = []
                for wp in wlist:
                    real_w = WLOW.get(wp.lower())
                    info = WEAPONS_DB.get(real_w) if real_w else None
                    want = bool(info) and (info["type"] == 1 or (info["type"] == 2 and tier >= SUPPRESS_PISTOL_TIER))
                    if want and not info["linked"]:
                        can = pick_can(newfac, tier, info["compat"])
                        if can:
                            pre = "%s_%s_snds" % (newfac, real_w)
                            presets[real_w] = (pre, can)
                            outw.append(pre)
                            suppressed[0] += 1
                            hitw = True
                            continue
                        no_can[real_w] = no_can.get(real_w, 0) + 1
                    outw.append(wp)
                wlist = outw
            if hitw:
                arrw = "{" + ",".join('"%s"' % x for x in wlist) + "}"
                L.append("        weapons[] = %s;" % arrw)
                L.append("        respawnWeapons[] = %s;" % arrw)

            # FA TIER AMMUNITION - this faction's tier, see TIER. Everything
            # else this class needs - weapons, uniform, vest, linked items - is
            # inherited and deliberately not restated. The magazine list is the
            # exception, because swapping a round is the whole point of a tier.
            raw = "" if force_hit else gv("magazines")
            mrules = MAG_SWAP.get(newfac)
            if raw and (tier >= 2 or mrules):
                out, hit = [], False
                for mag in re.findall(r'"([^"]+)"', raw):
                    if mrules:
                        new_m = mag_swap(mag, mrules, c)
                        if new_m != mag:
                            mag, hit = new_m, True      # see MAG_SWAP
                    key = mag if mag in famap else mag_alias(mag, famap)
                    if key in famap and tier >= 2:
                        out.append(famap[key] + tier_sfx)
                        swapped[0] += 1
                        hit = True
                    else:
                        out.append(mag)
                if hit:
                    arr = "{" + ",".join('"%s"' % x for x in out) + "}"
                    L.append("        magazines[] = %s;" % arr)
                    L.append("        respawnMagazines[] = %s;" % arr)

            L.append("    };")
            total_u += 1

        # Fielded by this faction, not by its source - see EXTRA_UNITS and
        # emit_extras, which tools/apply_faction_extras.py shares.
        if bag_lines:
            L.append("    // ---- the squads' drone bags, assembling this faction's own drones - see SQUAD_DRONES ----")
            L += bag_lines
            for ln in bag_lines:
                if ln.startswith("    class %s_" % newfac):
                    extra_names.append(ln.split()[1].rstrip(":"))
            L.append("")
        ex_lines, ex_names = emit_extras(newfac, addon, side, new, men, vanilla)
        L += ex_lines
        extra_names += ex_names
        total_u += len(ex_names)
        if operator and operator not in ex_names:
            operator = None      # the extra was refused (dropped bag); no squad gets him

        L.append("};")
        left = sorted(set(s for s in re.findall(r'"([A-Za-z0-9_]+)"', "\n".join(L))
                          if class_origin(s, None) == "dropped"))
        if left:
            # A dropped mod's name in a kept class - a kit item, a crew, a
            # texture the filters above did not reach. Written anyway, and
            # said out loud, because the alternative is a class that quietly
            # points into a PBO that is not there.
            print("  !! %s: %d dropped-mod name(s) still written: %s"
                  % (addon, len(left), ", ".join(left[:5])))
        crlf(os.path.join(path, "CfgVehicles.hpp"), L)

        # ---- CfgWeapons: the suppressed presets - see SUPPRESS_TIER --------
        wpath = os.path.join(path, "CfgWeapons.hpp")
        # EVERY PRESET THIS ADDON WRITES, in one shape: (preset, weapon,
        # [(slot, item), ...]). The suppressor tier's are a MuzzleSlot and
        # nothing else; a faction may also declare its own - see EXTRA_PRESETS.
        plist = [(presets[w][0], w, [("MuzzleSlot", presets[w][1])]) for w in sorted(presets)]
        plist += [(pre, base, list(slots)) for pre, base, slots in EXTRA_PRESETS.get(newfac, [])]
        if plist:
            W = ["// Generated by tools/gen_us_factions.py - re-run rather than hand-edit.",
                 "// SUPPRESSED PRESETS - see SUPPRESS_TIER. Each is the weapon the source",
                 "// issues with the suppressor its MuzzleSlot takes linked on; scope 1 and",
                 "// baseWeapon keep the arsenal showing the plain weapon, as the base",
                 "// game's own presets do. No script: the man's weapons[] names the preset.",
                 "class CfgWeapons {"]
            for b in sorted(set(b for _p, b, _s in plist)):
                W.append("    class %s;" % b)
            W.append("")
            for pre, base, slots in plist:
                W += ["    class %s: %s {" % (pre, base),
                      "        scope = 1;",
                      "        author = QAUTHOR;",
                      '        baseWeapon = "%s";' % base,
                      "        class LinkedItems {"]
                for slot, item in slots:
                    W += ["            class LinkedItems%s {" % slot.replace("Slot", ""),
                          '                slot = "%s";' % slot,
                          '                item = "%s";' % item,
                          "            };"]
                W += ["        };", "    };"]
            W.append("};")
            crlf(wpath, W)
        elif os.path.exists(wpath):
            os.remove(wpath)
        preset_names = [pre for pre, _b, _s in plist]

        # ---- CfgGroups -------------------------------------------------
        sidecls = {0: "East", 1: "West", 2: "Indep", 3: "Civ"}.get(side, "West")
        L = [HDR.rstrip("\n"),
             "// EVERY MAN IS THIS FACTION'S OWN. A group that named the source",
             "// faction's classes would field somebody else's units under our",
             "// name; each vehicle below is the jmfsb_ class declared in",
             "// CfgVehicles.hpp.",
             "",
             "class CfgGroups {",
             "    class %s {" % sidecls,
             "",
             "        class %s {" % newfac,
             '            name = "%s";' % disp,
             ""]
        gdropped = []
        tree = collections.defaultdict(list)
        for g in mine:
            tree[groups[g]["cat"]].append(g)

        def arm_squad(men_in, cat):
            """THE DRONE OPERATOR JOINS EVERY SQUAD - see SQUAD_DRONES: a squad
            is four or more men in an infantry, motorised or mechanised group
            that has no drone man of its own yet. He takes the next slot of
            the wedge the group already uses; the escorts (the east's
            SwitchBlade Operator, the Syndikat's IED men) follow him."""
            if not (operator and len(men_in) >= 4 and any(k in cat.lower() for k in SQUAD_CATS)):
                return
            if any(("UAV" in v or "Drone" in v or "UGV" in v) for v, _r, _p in men_in):
                return
            men_in.append((operator, "PRIVATE", wedge(len(men_in))))
            squads_armed[0] += 1
            esc = SQUAD_DRONES[newfac].get("escort") or []
            for e_sfx in ([esc] if isinstance(esc, str) else esc):
                esc_cls = "%s_%s" % (newfac, e_sfx)
                if esc_cls in extra_names and not any(v == esc_cls for v, _r, _p in men_in):
                    men_in.append((esc_cls, "PRIVATE", wedge(len(men_in))))

        # GROUPS A SOURCE NEVER HAD - see EXTRA_GROUPS. Resolved here so a
        # missing member is reported with the faction, and filed under their
        # category beside the dump's groups.
        xgroups = collections.defaultdict(list)
        for gsfx, gname_x, gcat, members in EXTRA_GROUPS.get(newfac, []):
            resolved, missing = [], []
            for m in members:
                real = ulow.get(m.lower())
                cls_m = new.get(real) if real else None
                if not cls_m and m in extra_names:
                    cls_m = m
                if cls_m:
                    pr_m = props.get(real, {}) if real else {}
                    is_man_m = R.is_man(pr_m.get("vehicleClass", (None, ""))[1] or "", pr_m) if real else True
                    resolved.append((cls_m, is_man_m))
                else:
                    missing.append(m)
            if missing:
                print("  -- %s: extra group %s not written - not fielded: %s" % (addon, gsfx, ", ".join(missing)))
                continue
            xgroups[gcat].append((gsfx, gname_x, resolved))

        for cat in sorted(set(tree) | set(xgroups)):
            L += ["            class %s {" % cat,
                  '                name = "%s";' % cat,
                  ""]
            for g in sorted(tree[cat], key=lambda x: groups[x]["cls"]):
                gp = gprops.get(g, {})
                gname = groups[g].get("name") or gp.get("name", "")
                gcls = "%s_%s" % (newfac, groups[g]["cls"])
                # WHO IS STILL IN IT - decided before a line of the group is
                # written, or a dropped group leaves an unclosed class behind.
                men_in, lost = [], []
                for veh, rank, pos in R.gmen_values(gmen, g):
                    real = ulow.get(veh.lower())
                    real = gsub.get(real, real)
                    if real and real in new:
                        men_in.append((real, rank, pos))
                    else:
                        dropped[0] += 1
                        lost.append(real or veh)
                # A MECHANISED SQUAD THAT LOST ITS APC IS A RIFLE SQUAD UNDER
                # THE WRONG NAME, in the wrong category - which is what ALiVE
                # picks by. A group that lost a vehicle, or most of its men,
                # is not written; one short a man is, and is counted above.
                # A lost class the dump does not know is taken for a vehicle.
                def lost_vehicle(x):
                    pr = props.get(x)
                    if not pr:
                        return True
                    return not R.is_man(pr.get("vehicleClass", (None, ""))[1] or "", pr)
                if not men_in or any(lost_vehicle(x) for x in lost) or len(lost) * 2 > len(lost) + len(men_in):
                    if lost:
                        gdropped.append((groups[g]["cls"], lost))
                    continue
                arm_squad(men_in, cat)
                L.append("                class %s {" % gcls)
                if gname:
                    L.append('                    name = "%s";' % gname)
                L += ["                    side = %d;" % side,
                      '                    faction = "%s";' % newfac]
                if gp.get("icon"):
                    L.append('                    icon = "%s";' % gp["icon"])
                if gp.get("rarityGroup"):
                    L.append("                    rarityGroup = %s;" % gp["rarityGroup"])
                for i, (veh, rank, pos) in enumerate(men_in):
                    L += ["", "                    class Unit%d {" % i,
                          "                        side = %d;" % side,
                          '                        vehicle = "%s";' % new.get(veh, veh)]
                    if rank:
                        L.append('                        rank = "%s";' % rank)
                    L.append("                        position[] = %s;"
                             % (R.cfg_arr(pos) or "{0,0,0}"))
                    L.append("                    };")
                L += ["                };", ""]
                total_g += 1
            for gsfx, gname_x, resolved in xgroups.get(cat, []):
                # the vehicle or the leader first at the point of the wedge; a
                # sergeant leads a foot group, the first man behind a vehicle
                men_in = []
                # THE FIRST MAN LEADS, not the first entry after the first
                # vehicle: a group with two vehicles in front of its men would
                # otherwise pin SERGEANT on the second truck.
                lead_at = next((i for i, (_c, ism) in enumerate(resolved) if ism), 0)
                for i, (cls_m, _is_man) in enumerate(resolved):
                    men_in.append((cls_m, "SERGEANT" if i == lead_at else "PRIVATE", wedge(i)))
                arm_squad(men_in, cat)
                L.append("                class %s_%s {" % (newfac, gsfx))
                L += ['                    name = "%s";' % gname_x,
                      "                    side = %d;" % side,
                      '                    faction = "%s";' % newfac]
                for i, (veh, rank, pos) in enumerate(men_in):
                    L += ["", "                    class Unit%d {" % i,
                          "                        side = %d;" % side,
                          '                        vehicle = "%s";' % veh,
                          '                        rank = "%s";' % rank,
                          "                        position[] = %s;" % (R.cfg_arr(pos) or "{0,0,0}"),
                          "                    };"]
                L += ["                };", ""]
                total_g += 1
            L += ["            };", ""]
        L += ["        };", "    };", "};"]
        crlf(os.path.join(path, "CfgGroups.hpp"), L)

        # ---- config.cpp -------------------------------------------------
        L = ['#include "script_component.hpp"',
             "",
             "class CfgPatches {",
             "    class ADDON {",
             "        name = COMPONENT_NAME;",
             "        units[] = {"]
        allunits = [new[c] for c in roster] + extra_names
        L += ["            \"%s\"%s" % (u_, "," if i < len(allunits) - 1 else "")
              for i, u_ in enumerate(allunits)]
        L += ["        };",
              "        weapons[] = {%s};" % ",".join('"%s"' % x for x in preset_names),
              "        requiredVersion = REQUIRED_VERSION;",
              "        // jmfsb_fa_tiers IS NOT REQUIRED, DELIBERATELY. The tier",
              "        // magazines are named as STRINGS in magazines[]; nothing here",
              "        // inherits from them, so there is no load order to enforce.",
              "        // Requiring it was fatal: fa_tiers requires fa_rhs, fa_sps,",
              "        // fa_e22raf and fa_jca, which require RHS, SPS, E22 and JCA -",
              "        // and with skipWhenMissingDependencies any one of those absent",
              "        // dropped this whole faction out of 3DEN and Zeus in silence.",
              "        //",
              "        // NOTHING FROM THE SOURCE FACTION'S MOD IS REQUIRED EITHER.",
              "        // Every parent class is forward-declared in CfgVehicles.hpp, so a",
              "        // load order without that mod gets inert classes instead of a",
              "        // broken config. skipWhenMissingDependencies does the rest.",
              '        requiredAddons[] = {"jmfsb_main"};',
              "        skipWhenMissingDependencies = 1;",
              "        author = QAUTHOR;",
              "        VERSION_CONFIG;",
              "    };",
              "};",
              "",
              '#include "CfgFactionClasses.hpp"']
        if preset_names:
            L.append('#include "CfgWeapons.hpp"')
        L += ['#include "CfgVehicles.hpp"',
              '#include "CfgGroups.hpp"']
        crlf(os.path.join(path, "config.cpp"), L)

        # The generator writes class names out in full; the mod's rule is that an addon names its own classes
        # through CBA's macros (docs/CODING_GUIDELINES.md, user 2026-09-22). One pass over what was just written
        # turns them into GVAR / QGVAR / ADDON, so a regeneration cannot quietly undo the convention.
        try:
            import to_gvar
            _a, _done, _left, _pre = to_gvar.convert(addon)
            print("       %d name(s) written through GVAR, %d literal(s) left" % (_done, _left))
        except Exception as exc:
            print("       WARNING: the GVAR pass did not run (%s) - run tools/to_gvar.py %s by hand" % (exc, addon))

        if forced[0]:
            print("       %d man class(es) kitted by hand" % forced[0])
        if squads_armed[0]:
            print("       %d squad(s) got a Drone Operator" % squads_armed[0])
            squads_armed[0] = 0
        print("  %-20s %-18s %4d unit(s)  %3d group(s)"
              % (addon, newfac, len(roster), len(mine)))
        if shed:
            print("       %d class(es) dropped with %s: %s%s"
                  % (len(shed), "/".join(DROP_MODS), ", ".join(shed[:6]),
                     " ..." if len(shed) > 6 else ""))
        for veh, cr, sub in recrewed:
            print("       %s: crew %s went with its mod - %s"
                  % (veh, cr, ("now " + new[sub]) if sub else "parent's crew stands"))
        for gcls, lost in gdropped:
            print("       group %s not written - lost %s" % (gcls, ", ".join(lost)))

    print("wrote  %d addon(s), %d unit class(es), %d group(s)"
          % (len(TARGETS), total_u, total_g))
    if kitn[0]:
        print("       %d kit item(s) substituted" % kitn[0])
    if kit_unmapped:
        # NOT SILENT. An item with no equivalent stays as it was, and which
        # ones those are is the difference between a deliberate gap and a miss.
        print("       %d item(s) had no mapping - left as issued:" % len(kit_unmapped))
        for k in sorted(kit_unmapped, key=lambda x: -kit_unmapped[x])[:8]:
            print("         %-42s x%d" % (k, kit_unmapped[k]))
    if swapped_w[0]:
        print("       %d rifle(s) substituted" % swapped_w[0])
    if suppressed[0]:
        print("       %d weapon slot(s) suppressed - see SUPPRESS_TIER" % suppressed[0])
    if moved["sf"] or moved["men"]:
        print("       editor categories collapsed: %d man/men -> Men, %d -> Men (Special Forces)" % (moved["men"], moved["sf"]))
    if no_can:
        # NOT SILENT: a peer faction's weapon with a muzzle slot nothing in
        # the load order suppresses (or nothing kept - see DROP_MODS).
        print("       %d weapon(s) at a peer tier have NO suppressor to fit - left as issued:" % len(no_can))
        for k in sorted(no_can, key=lambda x: -no_can[x])[:10]:
            print("         %-46s x%d" % (k, no_can[k]))
    print("       %d magazine slot(s) swapped to FA tier rounds, via %d mapping(s)"
          % (swapped[0], len(famap)))
    if dropped_no_t3:
        # NOT SILENT. These have an FA round but fa_tiers built no tier for it,
        # so the unit keeps its vanilla magazine.
        print("       %d magazine(s) have an FA round with no tier built - left vanilla:"
              % len(dropped_no_t3))
        for v in dropped_no_t3[:6]:
            print("         %s" % v)
    if dropped[0]:
        # SAID OUT LOUD - a squad quietly one man short is worse than a note.
        print("       %d group slot(s) dropped, the vehicle is not in the faction"
              % dropped[0])
    return 0


if __name__ == "__main__":
    rc = main()
    # 2040 PEER ARMOUR. This rewrites files tools/peer_vests.py edits; put its protection and vest swaps back.
    import peer_vests
    peer_vests.main()
    sys.exit(rc)
