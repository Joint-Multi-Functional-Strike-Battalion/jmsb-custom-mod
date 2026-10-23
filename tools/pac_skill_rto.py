#!/usr/bin/env python3
"""The RTO is a PAC skill (user, 2026-10-22: "add an rto skill or trait, and on the radio app allow rtos to add
custom channels").

    set JMSB_PAC_URI=<the jmsb_pac mongodb+srv:// string>     (PAC > Service > Server > Database)
    python tools/pac_skill_rto.py            dry run: what would change
    python tools/pac_skill_rto.py --apply    write, each document saved first
    python tools/pac_skill_rto.py --db ghostd --unit GHOST [--apply]
                                             the same for another unit on the cluster (DIVINER's Ghosts;
                                             user, 2026-10-23: "rto added to diviner and diviner web?")

The mod has one RTO test, jmfsb_voice_fnc_isRto (addons/voice): the isRTO flag on the man, the RTO skill tag from
PAC, or a radio job in his slot's role description. The skill gives the first two at once, so holding it IS the
job - the RTO tag, FLASH, the MANAGE tab and the RTO nets of the RADIO app:

- JMSB.skills items.rto: id rto, abbrev RTO (the tag), effect trait:isRTO (the flag), colour 0,150,136 as
  art/skills/rto.png is tinted (tools/gen_skill_icons.py).
- JMSB.radio items.vonNets: "rto" in the skills column of the FIRST C2 row ([net, kind, [squads], [roles],
  [skills]], jmfsb_pac_fnc_netPlanUnit), so every RTO rides C2 and passes jmfsb_voice_fnc_canGlobal. An old
  three-column row grows to five. No C2 row: run tools/pac_von_plan.py first.
- Read-only: a WARNING names every JMSB.role.* whose own traits or customVariables set isRTO. Once a skill owns a
  name, jmfsb_pac_fnc_managedNames reports it and addons/groups fnc_setupPlayer skips it on the role, so such a
  role stops making its man the RTO the day this is applied - give it "rto" under defaultSkills (Skills it
  grants, the role page) instead. Nothing is written to a role.
Backups: D:/Git/_jmsb_db_backup_<date>/<id>_before_skill_rto.json.
"""
import argparse
import copy
import datetime
import json
import os
import sys

from pymongo import MongoClient

from pac_devices_gps import BACKUP, DB

COLLECTION = "pac"
UNIT = "JMSB"
TAG = "tools/pac_skill_rto.py"
SKILL_ID = "rto"
SKILL = {"id": SKILL_ID, "name": "RTO", "abbrev": "RTO", "effects": ["trait:isRTO"], "color": "0,150,136"}
# The name the skill's effect sets, lower-case as fnc_managedNames compares.
RTO_FLAG = "isrto"
VON_NETS = "vonNets"
# A vonNets row: [net, kind, [squads], [roles], [skills]].
VON_KIND, VON_SKILLS, VON_COLS = 1, 4, 5
VON_C2 = "c2"
# What a role sets itself: rows of [name, value, ...] under these two keys (fnc_setupPlayer).
ROLE_LISTS = ("traits", "customVariables")
ROLE_GRANTS = "defaultSkills"


def rto_on_c2(nets):
    """vonNets with "rto" in the first C2 row's skills column, and a note - None when nothing changes."""
    if not isinstance(nets, list):
        return None, "items.%s is not a list - left alone" % VON_NETS
    for i, row in enumerate(nets):
        if not (isinstance(row, list) and len(row) > VON_KIND and str(row[VON_KIND]).strip().lower() == VON_C2):
            continue
        skills = row[VON_SKILLS] if len(row) > VON_SKILLS and isinstance(row[VON_SKILLS], list) else []
        if any(str(s).strip().lower() == SKILL_ID for s in skills):
            return None, None
        out = copy.deepcopy(nets)
        fixed = out[i] + [[]] * (VON_COLS - len(out[i]))
        fixed[VON_SKILLS] = list(skills) + [SKILL_ID]
        out[i] = fixed
        return out, "row %r: skills %s -> %s" % (row[0], json.dumps(skills), json.dumps(fixed[VON_SKILLS]))
    return None, "no C2 row in %s - run tools/pac_von_plan.py first" % VON_NETS


def names_set(rows):
    """The lower-case names a role's traits or customVariables rows set."""
    if not isinstance(rows, list):
        return []
    return [r[0].strip().lower() for r in rows if isinstance(r, list) and r and isinstance(r[0], str)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--db", default=DB, help="database on the cluster (default %s)" % DB)
    ap.add_argument("--unit", default=UNIT, help="unit the documents belong to (default %s)" % UNIT)
    a = ap.parse_args()
    uri = os.environ.get("JMSB_PAC_URI", "")
    if not uri.startswith("mongodb"):
        sys.exit("set JMSB_PAC_URI to the jmsb_pac connection string first")
    coll = MongoClient(uri, serverSelectionTimeoutMS=15000)[a.db][COLLECTION]
    skills_doc = a.unit + ".skills"
    radio_doc = a.unit + ".radio"
    role_prefix = r"^" + a.unit + r"\.role\."

    changes = []

    skills = coll.find_one({"_id": skills_doc})
    if skills is None:
        sys.exit("no %s document" % skills_doc)
    now = (skills.get("items") or {}).get(SKILL_ID)
    print("now:  %s items.%s %s" % (skills_doc, SKILL_ID, json.dumps(now, default=str)))
    print("then: %s items.%s %s" % (skills_doc, SKILL_ID, json.dumps(SKILL)))
    if now == SKILL:
        print("already so")
    else:
        changes.append((skills, {"items." + SKILL_ID: SKILL}))

    radio = coll.find_one({"_id": radio_doc})
    if radio is None:
        sys.exit("no %s document" % radio_doc)
    nets = (radio.get("items") or {}).get(VON_NETS, [])
    fixed, note = rto_on_c2(nets)
    print("now:  %s items.%s %s" % (radio_doc, VON_NETS, json.dumps(nets, default=str)))
    print("then: %s items.%s %s" % (radio_doc, VON_NETS, json.dumps(nets if fixed is None else fixed, default=str)))
    print(note or "already so")
    if fixed is not None:
        changes.append((radio, {"items." + VON_NETS: fixed}))

    # Read-only: the roles that would lose isRTO to the skill.
    owners = []
    for doc in coll.find({"_id": {"$regex": role_prefix}}):
        role = doc.get("role")
        if not isinstance(role, dict):
            continue
        where = [k for k in ROLE_LISTS if RTO_FLAG in names_set(role.get(k))]
        if not where:
            continue
        grants = role.get(ROLE_GRANTS)
        grants = [str(s).strip().lower() for s in grants] if isinstance(grants, list) else []
        owners.append((doc["_id"], where, SKILL_ID in grants))
    print()
    if owners:
        print("WARNING: %d role(s) set isRTO themselves. With the skill owning isRTO, fnc_managedNames makes"
              " fnc_setupPlayer skip it on the role, so these stop making their man the RTO once this is applied:"
              % len(owners))
        for role_id, where, grants in owners:
            print("  %-34s %s%s" % (role_id, " and ".join(where), " (grants rto already)" if grants else ""))
        print("  give each \"rto\" under %s (Skills it grants) on the role page instead - not written here" % ROLE_GRANTS)
    else:
        print("no %s.role.* sets isRTO itself - no role loses it to the skill" % a.unit)

    print("\n%d document(s) to change" % len(changes))
    if not changes:
        return
    if not a.apply:
        print("dry run - nothing written. Re-run with --apply.")
        return
    os.makedirs(BACKUP, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for doc, upd in changes:
        with open(os.path.join(BACKUP, "%s_before_skill_rto.json" % doc["_id"]), "w", encoding="utf-8") as f:
            json.dump(doc, f, default=str, indent=1)
        coll.update_one({"_id": doc["_id"]}, {"$set": dict(upd, updatedAt=stamp, **{"from": TAG})})
    print("written; the documents as they were are in %s" % BACKUP)


if __name__ == "__main__":
    main()
