#!/usr/bin/env python
"""JMSB versions of every MIG helmet, NVG and vest - addons/headware_mig and addons/vests_mig.

MIG (Steam Workshop: MIG - Core, MIG - Headgear, MIG - Vests) is a third-party gear pack. Each of its arsenal
items gets a jmfsb class that INHERITS the MIG one - MIG's own models and textures, nothing copied - with
jmfsb's protection and hearing in place of MIG's (user, 2026-10-07: "make jmfsb versions of each align the
armor and ace hearing"):

    ballistic helmet   HitHead 6 / 0.5, jmfsb's combat-helmet value (MIG: 5.6 - 6.1, passThrough 0.25 - 0.4)
    bump helmet        MIG's own 1.6 / 0.9 kept: a bump helmet stops nothing, and jmfsb has no tier for one
    headset            MACRO_ACE_HEARING on every helmet MIG gives ear protection to (MIG: three different values)
    plate carrier      JMFSB_PLATE_CARRIER_STANDARD_PROTECTION, the 29-chest standard every jmfsb carrier wears;
                       MIG's own mass and load kept, so a slick still weighs less than an MG rig
    belt               copied as it is - no plates
    NVG, visor         copied as they are - no armour, no hearing

The arsenal: MIG's ACE Arsenal Extended data is mirrored onto the jmfsb classes, under jmfsb's own model names
so the jmfsb and MIG versions do not land on the same option and shadow each other.

Both addons load only with MIG (skipWhenMissingDependencies).

    python tools/gen_mig.py [path to the unpacked MIG folder]
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDONS = os.path.join(ROOT, "addons")
MIG = sys.argv[1] if len(sys.argv) > 1 else os.path.join("D:" + os.sep, "work", "mig", "MIG")

HEADWARE = "headware_mig"
VESTS = "vests_mig"
BELT_MASS = 20          # MIG's two belts weigh 13-14; every carrier is 27 and up
TOP = re.compile(r"(?m)^\tclass (\w+)\s*:\s*(\w+)\s*\n\t\{(.*?)\n\t\};", re.S)


def read(p):
    return open(p, encoding="utf-8", errors="replace").read()


def patch_name(cfg):
    m = re.search(r"class CfgPatches\s*\{\s*class (\w+)", read(cfg))
    return m.group(1) if m else None


def items():
    """[(addon, kind, class, parent, displayName, body, patch)] for every scope=2 MIG item."""
    out = []
    for part, addon in (("MIG_Helmets", HEADWARE), ("MIG_Vests", VESTS)):
        for dp, _dirs, files in os.walk(os.path.join(MIG, part)):
            if "config.cpp" not in files or "extended_arsenal" in dp or "bettir" in dp.lower():
                continue
            cfg = os.path.join(dp, "config.cpp")
            t = read(cfg)
            cw = t.find("class CfgWeapons")
            if cw < 0:
                continue
            for m in TOP.finditer(t, cw):
                cls, parent, body = m.groups()
                if not re.search(r"\n\t\tscope\s*=\s*2", body):
                    continue
                dn = re.search(r'\n\t\tdisplayName\s*=\s*"([^"]*)"', body)
                if parent == "NVGoggles":
                    kind = "nvg"
                elif parent.startswith("H_"):
                    kind = "bump" if "bump" in cls.lower() else "helmet"
                else:
                    mass = re.search(r"\bmass\s*=\s*([\d.]+)", body)
                    kind = "belt" if mass and float(mass.group(1)) < BELT_MASS else "vest"
                out.append((addon, kind, cls, parent, dn.group(1) if dn else cls, body, patch_name(cfg)))
    return out


# ---------------------------------------------------------------------------
# ACE Arsenal Extended
# ---------------------------------------------------------------------------
def arsenal_dirs(part):
    for dp, _dirs, files in os.walk(os.path.join(MIG, part)):
        if "extended_arsenal" in dp and "xtdgearinfos.hpp" in [f.lower() for f in files]:
            yield dp


def find(dp, name):
    return next(os.path.join(dp, f) for f in os.listdir(dp) if f.lower() == name)


def infos(dp):
    """{class: {attr: value}} from an xtdgearinfos.hpp - MIG writes them as macros or as plain classes."""
    t = read(find(dp, "xtdgearinfos.hpp"))
    out = {}
    for m in re.finditer(r"#define (\w+)\(([^)]*)\)((?:[^\n]*\\\n)*[^\n]*)", t):
        name, params, body = m.group(1), [p.strip() for p in m.group(2).split(",")], m.group(3)
        cls_p = re.search(r"class (\w+)", body).group(1)
        attrs = re.findall(r"(\w+)\s*=\s*#(\w+)", body)
        for call in re.finditer(r"(?m)^\s*%s\(([^)]*)\)" % name, t):
            args = dict(zip(params, [a.strip() for a in call.group(1).split(",")]))
            out[args[cls_p]] = {a: args[p] for a, p in attrs}
    for m in re.finditer(r"class (\w+)\s*\{\s*((?:\w+\s*=\s*\"[^\"]*\";\s*)+)\}", t):
        out[m.group(1)] = dict(re.findall(r"(\w+)\s*=\s*\"([^\"]*)\"", m.group(2)))
    return out


def models(dp):
    """(the CfgWeapons body of an xtdgearmodels.hpp, its top-level model class names)."""
    t = read(find(dp, "xtdgearmodels.hpp"))
    i = t.index("{", t.index("class CfgWeapons")) + 1
    d, j = 1, i
    while d:
        d += {"{": 1, "}": -1}.get(t[j], 0)
        j += 1
    body = t[i:j - 1]
    names, depth = [], 0
    for tok in re.finditer(r"class (\w+)|[{}]", body):
        if tok.group(0) == "{":
            depth += 1
        elif tok.group(0) == "}":
            depth -= 1
        elif depth == 0:
            names.append(tok.group(1))
    return body, names


# ---------------------------------------------------------------------------
# writing
# ---------------------------------------------------------------------------
def write(path, lines):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\r\n") as fh:
        fh.write("\n".join(lines).rstrip("\n") + "\n")


GEN = "// Generated by tools/gen_mig.py from MIG's own configs - re-run rather than hand-edit."

PROTECTION = {
    "helmet": ["        class ItemInfo: ItemInfo {", "            JMFSB_HELMET_STANDARD_PROTECTION", "        };"],
    "vest": ["        class ItemInfo: ItemInfo {", "            JMFSB_PLATE_CARRIER_STANDARD_PROTECTION", "        };"],
}


# ECOTI ON EVERY MIG NVG (user, 2026-10-12: "ECOTI can we make our nvgs have this feature"). The real thing
# is a clip-on thermal fused over the image intensifier; Arma cannot blend two vision modes, so the goggle
# gets a third mode instead - the NVG key cycles Normal > NVG > TI, white-hot then black-hot - the same way
# jmfsb_nvg's anvgTI / nvg5TI goggles already do it.
NVG_THERMAL = ['        visionMode[] = {"Normal", "NVG", "TI"};',
               "        thermalMode[] = {0, 1};",
               # Opts the goggle into jmfsb_ecoti's clip-on thermal overlay. The literal name, not a
               # GVAR: ecoti reads it off the hmd class with getNumber.
               "        jmfsb_ecoti_enabled = 1;",
               # FULL SCREEN (user, 2026-10-15: "every NVG the players use must render full screen"). The empty
               # reticle as modelOptics draws no tube picture, and ACE draws its border/eyecups only when
               # modelOptics is "" - both are cleared too so nothing brings them back. Generation and phosphor
               # stay the goggle's own.
               '        modelOptics = "\\A3\\weapons_f\\reticle\\optics_empty.p3d";',
               '        ACE_nightvision_border = "";',
               "        ACE_nightvision_eyeCups = 0;",
               # Marks it a JMSB full-screen goggle: jmfsb_nvg's "NVG full screen" client setting, when off,
               # puts a tube mask back over exactly these. The literal name, read with getNumber, like
               # jmfsb_ecoti_enabled above.
               "        jmfsb_nvg_fullScreen = 1;"]


def weapons(rows, beaut):
    L = [GEN, "", "class CfgWeapons {", "    class ItemInfo; // defined for real in jmfsb_main (see its CfgWeapons.hpp)"]
    L += ["    class %s;" % p for p in sorted({r[2] for r in rows})]
    for _a, kind, cls, _parent, dn, body, _patch in rows:
        L += ["", "    class GVAR(%s): %s {" % (cls, cls),
              "        author = QAUTHOR;",
              "        scope = 2;",
              "        scopeArsenal = 2;",
              '        displayName = "[JMSB] %s";' % dn]
        if kind in ("helmet", "bump") and "ace_hearing_protection" in body:
            L += ["        MACRO_ACE_HEARING"]
        L += PROTECTION.get(kind, [])
        if kind == "nvg":
            L += NVG_THERMAL
        L += ["    };"]
    L += ["};"]
    return L


# WHAT MIG GIVES NO ARSENAL DATA OF ITS OWN. The Caiman visor is two classes, up and down, with no
# XtdGearInfos anywhere in MIG, so it sat in the arsenal as two loose items beside every other MIG piece's
# one entry (user, 2026-10-08: "all the mig gear needs to have extended arsenal configs"). One model of
# ours with a position option folds them into one entry like the rest.
EXTRA_MODELS = {
    "MIG_Helmets": [
        "        class GVAR(MIG_GALVION_VISOR)",
        "        {",
        '            label = "Caiman Visor";',
        '            author = "Galvion";',
        '            options[] = {"position"};',
        "            class position",
        "            {",
        '                label = "Position";',
        '                values[] = {"UP","DOWN"};',
        "                class UP",
        "                {",
        '                    label = "Up";',
        "                };",
        "                class DOWN",
        "                {",
        '                    label = "Down";',
        "                };",
        "            };",
        "        };",
    ],
}
EXTRA_INFOS = {
    "MIG_Helmets": {
        "MIG_Galvion_Visor_UP": {"model": "MIG_GALVION_VISOR", "position": "UP"},
        "MIG_Galvion_Visor_DOWN": {"model": "MIG_GALVION_VISOR", "position": "DOWN"},
    },
}


def xtdgear(part, keep):
    """The jmfsb mirror of MIG's arsenal data for the classes in keep."""
    # MIG NAMES SOME CLASSES IN A DIFFERENT CASE in its arsenal data than in its CfgWeapons -
    # MIG_Galvion_BALLISTIC_BLK_CLEAN against MIG_Galvion_Ballistic_BLK_CLEAN, MIG_SFHC_BLK_PELTOR against
    # MIG_SFHC_BLK_Peltor. Arma reads class names without case; a Python set does not, and the first run
    # silently dropped ten helmets from the extended arsenal for it (user, 2026-10-08: "some of the helmets
    # you customized did not have it"). Matched without case here, written in the CfgWeapons spelling so
    # the two files agree to the eye as well.
    keep_ci = {k.lower(): k for k in keep}
    mod_lines, info_lines = [], []
    for dp in sorted(arsenal_dirs(part)):
        body, names = models(dp)
        for n in names:
            body = re.sub(r"\bclass %s\b" % re.escape(n), "class GVAR(%s)" % n, body, count=1)
        mod_lines += [body.replace("\t", "    ").rstrip()]
        for cls, attrs in sorted(infos(dp).items()):
            name = keep_ci.get(cls.lower())
            if name is None:
                continue
            info_lines += ["        class GVAR(%s) {" % name]
            for k, v in attrs.items():
                info_lines += ["            %s = %s;" % (k, "QGVAR(%s)" % v if k == "model" else '"%s"' % v)]
            info_lines += ["        };"]
    if part in EXTRA_MODELS:
        mod_lines += [""] + EXTRA_MODELS[part]
    for cls, attrs in sorted(EXTRA_INFOS.get(part, {}).items()):
        name = keep_ci.get(cls.lower())
        if name is None:
            continue
        info_lines += ["        class GVAR(%s) {" % name]
        for k, v in attrs.items():
            info_lines += ["            %s = %s;" % (k, "QGVAR(%s)" % v if k == "model" else '"%s"' % v)]
        info_lines += ["        };"]
    return [GEN, "// MIG's own ACE Arsenal Extended data, its model classes renamed into jmfsb's namespace.",
            "", "class XtdGearModels {", "    class CfgWeapons {"] + mod_lines + ["    };", "};", "",
            "class XtdGearInfos {", "    class CfgWeapons {"] + info_lines + ["    };", "};"]


def config(addon, beaut, rows, extra_req):
    req = ["jmfsb_main"] + sorted({r[6] for r in rows} | set(extra_req))
    L = ['#include "script_component.hpp"', "", "class CfgPatches {", "    class ADDON {",
         "        name = COMPONENT_NAME;", "        units[] = {};", "        weapons[] = {"]
    L += ["            QGVAR(%s)%s" % (r[2], "," if i < len(rows) - 1 else "") for i, r in enumerate(rows)]
    L += ["        };", "        requiredVersion = REQUIRED_VERSION;",
          "        // MIG's own patches: every jmfsb class here inherits one of their classes, so this addon",
          "        // drops with MIG rather than leaving parentless items in the arsenal.",
          "        requiredAddons[] = {"]
    L += ['            "%s"%s' % (a, "," if i < len(req) - 1 else "") for i, a in enumerate(req)]
    L += ["        };", "        skipWhenMissingDependencies = 1;",
          '        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";', "        author = QAUTHOR;",
          '        authors[] = {"Brucey"};', "        VERSION_CONFIG;", "    };", "};", "",
          '#include "CfgEventHandlers.hpp"', '#include "CfgWeapons.hpp"', '#include "XtdGear.hpp"']
    return L


def main():
    rows = items()
    for addon, part, beaut in ((HEADWARE, "MIG_Helmets", "Headware - MIG"), (VESTS, "MIG_Vests", "Vests - MIG")):
        mine = [r for r in rows if r[0] == addon]
        d = os.path.join(ADDONS, addon)
        if not os.path.isdir(d):
            sys.exit("scaffold it first: python tools/new_component.py %s" % addon)
        write(os.path.join(d, "CfgWeapons.hpp"), weapons(mine, beaut))
        write(os.path.join(d, "XtdGear.hpp"), xtdgear(part, {r[2] for r in mine}))
        write(os.path.join(d, "config.cpp"), config(addon, beaut, mine, [part]))
        kinds = {}
        for r in mine:
            kinds[r[1]] = kinds.get(r[1], 0) + 1
        print("%-14s %3d classes  %s" % (addon, len(mine), ", ".join("%s %d" % kv for kv in sorted(kinds.items()))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
