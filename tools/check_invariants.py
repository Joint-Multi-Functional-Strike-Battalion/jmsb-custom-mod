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

  3. EVERY CARD THE MOD NAMES IS BUILT IN (user, 2026-11-02: "the mod's own
     card always wins"). The mod carries its cards (messaging, support and PAC
     register them - fnc_builtin*.sqf, pac fnc_registerTemplates.sqf) and the
     TAC//PAC deck only adds the ids the mod does not have. A card id the
     support providers, the prompts' quick replies or the card reader name
     (a CARD / CARDS / ANSWERS / REPLIES macro in the addons that file or read
     cards) that is not built in is a flow that works only where a deck
     happens to carry it.
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

# --- 3. every card the mod names is built in -----------------------------------
# Where the mod's cards are: one `_cards pushBack ["id", ...]` per card.
CARD_FILES = [
    os.path.join(ADDONS, "messaging", "functions", "fnc_builtinCards.sqf"),
    os.path.join(ADDONS, "support", "functions", "fnc_builtinCards.sqf"),
    os.path.join(ADDONS, "support", "functions", "fnc_builtinFires.sqf"),
    os.path.join(ADDONS, "support", "functions", "fnc_builtinReplies.sqf"),
    os.path.join(ADDONS, "pac", "functions", "fnc_registerTemplates.sqf"),
]
CARD_SQF = re.compile(r"_cards pushBack \[\"(\w+)\"")
# The addons that file, offer or read cards by id; their script_component.hpp.
CARD_ADDONS = ["messaging", "support", "support_air", "support_fires", "support_logistics", "cas", "jumpmaster",
               "tacpad", "pac"]
# A macro naming card ids: CARD / CARDS (one id, a list, a list of [id, keys]),
# ANSWERS (a prompt's quick replies, "a,b,c") and REPLIES (a card's answers).
CARD_MACRO = re.compile(r"^#define\s+(\w*(?:CARD|ANSWERS|REPLIES)\w*)\s+(.*)$")
# Macros with CARD in the name that hold no card id, and the retired ids
# (never built in - the deck's copies are skipped).
CARD_MACRO_NOT_IDS = {"CARD_KIND_REPLY", "CARD_KIND_ROOT", "CARD_PRIORITY_HIGH", "THREAD_CARD_TAKE", "CARDS_RETIRED"}
# A card id: lowercase letters and digits. Field keys (Text.A), words (TOF %1)
# and line stems (Line6) are not.
CARD_ID = re.compile(r"^[a-z][a-z0-9]*$")
STRING = re.compile(r"\"([^\"]*)\"")


def macros(path):
    """(name, value) for every #define, continuation lines joined."""
    out, held = [], ""
    for line in read(path).splitlines():
        line = held + line.strip() if held else line.strip()
        if line.endswith("\\"):
            held = line[:-1] + " "
            continue
        held = ""
        m = CARD_MACRO.match(line)
        if m:
            out.append((m.group(1), m.group(2)))
    return out


def card_gaps():
    """Card ids the mod names and does not carry, as lines; [] when none."""
    built = set()
    for path in CARD_FILES:
        built |= set(CARD_SQF.findall(read(path)))
    if not built:
        return ["no built-in cards read from %s" % ", ".join(os.path.relpath(p, ROOT) for p in CARD_FILES)]
    out = []
    for addon in CARD_ADDONS:
        path = os.path.join(ADDONS, addon, "script_component.hpp")
        for name, value in macros(path):
            if name in CARD_MACRO_NOT_IDS:
                continue
            for text in STRING.findall(value):
                for cid in (t.strip() for t in text.split(",")):
                    if CARD_ID.match(cid) and cid not in built:
                        out.append("%s/script_component.hpp %s: '%s' is not a built-in card" % (addon, name, cid))
    return out


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

    gaps = card_gaps()
    if gaps:
        ok = False
        print("CARD NOT BUILT IN - %d card id(s)" % len(gaps))
        print("  The mod carries every card it names (messaging and support")
        print("  fnc_builtin*.sqf, pac fnc_registerTemplates.sqf). Build it in.")
        for s in gaps:
            print("    " + s)
        print("")

    if not ok:
        print("invariant check FAILED")
        return 1

    print("adapter seam intact, sides typed once, every card named is built in")
    return 0


if __name__ == "__main__":
    sys.exit(main())
