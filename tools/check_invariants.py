"""Architectural invariants that must never regress.

    python tools/check_invariants.py

These are not style checks. Each one encodes a design decision that was
expensive to make and is cheap to break by accident, and each fails the build
rather than warning - a warning about an architecture rule is a rule that gets
broken.

  1. THE ADAPTER SEAM (docs/new.md rule 4). Exactly one addon -
     addons/adapter_alive - may know ALiVE exists. Removing it must leave
     every other addon working, and the only way to keep that true is to
     never let a second addon name an ALiVE symbol. The regex is deliberately
     broad (any ALiVE_/ALIVE_ prefixed symbol, plus OPCOM_instances) - a
     narrower list missed ALIVE_aaProfileBehaviour and ALIVE_gridData.

  2. SIDES ARE TYPED ONCE (D59). The players' side comes from their slots
     (fnc_playerSides) and the enemy's from the mission's side relations
     (fnc_enemySide, 2026-10-09); those derive every side any subsystem needs. Four subsystems used to
     ask for a side five times between them, and every one of those fields was a
     chance to say something different by accident. A new module attribute
     asking for a side is a regression, not a feature.
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDONS = os.path.join(ROOT, "addons")

# --- 1. the adapter seam -----------------------------------------------------
ADAPTER = "adapter_alive"
ALIVE_SYMBOLS = re.compile(r"\bAL[iI]VE_\w+|\bOPCOM_instances\b")

# Matched name -> why it is allowed outside the adapter. These are ITEM/CLASS
# names from the ALiVE mod appearing as plain strings (gear lists), not code
# reaching into ALiVE.
ALIVE_SYMBOL_ALLOW = {
    "ALIVE_Tablet": "arsenal whitelist entry - an inventory item, not an API call",
}

# --- 2. sides are typed once -------------------------------------------------
# The only two attributes allowed to ask which side a FORCE belongs to.
SIDE_ATTRS_ALLOWED = {
    "enemy_side",       # JMSB - Enemy: the one place a hostile side is named
    "player_side",      # JMSB - Core: the one place the players' side is named

    # Not force allegiance, and so not what D59 is about:
    "crew_side",        # Site/intel spot: which faction crews a SPAWNED OBJECT
    "groupSide",        # Force/wave spawner: the side of the troops it makes,
                        #   and a Force module is not bound to an Enemy module
    "defend_side",      # Emplacement/CIWS: whose site this is, defaulting to
                        #   AUTO which reads it off the synced guns
    "sideOnly",         # Boarding: "presser's side" or "everyone in range".
                        #   Relative to whoever pressed at the time - it never
                        #   asks anybody to name a side, so D59 does not apply
    "swarmSide",        # Drone swarm: the crew of an airframe that SPAWNS
                        #   EMPTY - the airframe's own config decides the
                        #   side of one that crews itself. Same kind as
                        #   crew_side (2026-10-09)
}
SIDE_ATTR = re.compile(r"^\s*(?:AEDIT|ABOOL|APICK)\((\w*[Ss]ide\w*)\s*,", re.M)
SIDE_CLASS = re.compile(r"^\s*class (\w*[Ss]ide\w*)\s*:\s*(?:Combo|Edit)\b", re.M)


def read(p):
    try:
        return io.open(p, encoding="utf-8", errors="replace").read()
    except OSError:
        return ""


def main():
    seam, sides = [], []

    for dirpath, _dirs, files in os.walk(ADDONS):
        rel = os.path.relpath(dirpath, ADDONS).replace("\\", "/")
        addon = rel.split("/")[0]

        for f in files:
            path = os.path.join(dirpath, f)
            shown = os.path.relpath(path, ROOT).replace("\\", "/")

            if f.endswith(".sqf") and addon != ADAPTER:
                for n, line in enumerate(read(path).splitlines(), 1):
                    if line.lstrip().startswith("//") or line.lstrip().startswith("*"):
                        continue
                    m = ALIVE_SYMBOLS.search(line)
                    if m and m.group(0) not in ALIVE_SYMBOL_ALLOW:
                        seam.append("%s:%d  %s" % (shown, n, m.group(0)))

            if f.endswith(".hpp") and "CfgVehicles" in f:
                txt = read(path)
                for m in list(SIDE_ATTR.finditer(txt)) + list(SIDE_CLASS.finditer(txt)):
                    name = m.group(1)
                    if name in SIDE_ATTRS_ALLOWED:
                        continue
                    # "...PerSide" is a RATE - sites per side, jammers per
                    # side - not a question about allegiance. D59 is about
                    # asking a mission maker to name a side twice.
                    if re.search(r"[Pp]er[Ss]ide$", name):
                        continue
                    n = txt[:m.start()].count("\n") + 1
                    sides.append("%s:%d  %s" % (shown, n, name))

    print("Validating architectural invariants")
    print("------")

    ok = True

    if seam:
        ok = False
        print("ADAPTER SEAM BROKEN (Part 4 section 3) - %d reference(s) to ALiVE" % len(seam))
        print("  Only addons/%s may name an ALiVE symbol. Route this through the" % ADAPTER)
        print("  event contract or an adapter data read instead.")
        for s in seam[:20]:
            print("    " + s)
        if len(seam) > 20:
            print("    ... and %d more" % (len(seam) - 20))
        print("")

    if sides:
        ok = False
        print("SIDE TYPED MORE THAN ONCE (D59) - %d attribute(s)" % len(sides))
        print("  The players' side comes from their slots (jmfsb_common_fnc_playerSides)")
        print("  and the enemy from the side relations (jmfsb_common_fnc_enemySide).")
        print("  Call those rather than asking for a side again.")
        for s in sides:
            print("    " + s)
        print("")

    if not ok:
        print("invariant check FAILED")
        return 1

    print("adapter seam intact, sides typed once")
    return 0


if __name__ == "__main__":
    sys.exit(main())
