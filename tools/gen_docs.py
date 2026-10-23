"""Generate docs/ from the addon sources.

    python tools/gen_docs.py

Everything here is scanned out of addons/ and optionals/ -- nothing is typed by
hand except the GROUPS table, so re-running it after a change keeps the docs
honest instead of letting them rot like the README did.

Writes:
    docs/README.md      index + counts
    docs/ADDONS.md      every addon, grouped, with deps and what it ships
    docs/SETTINGS.md    every CBA setting, by addon, plus the forced values
    docs/MODULES.md     every Eden module and its attributes
"""
import io, os, re, collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDONS = os.path.join(ROOT, "addons")
OPTIONALS = os.path.join(ROOT, "optionals")
DOCS = os.path.join(ROOT, "docs")

# The one hand-maintained thing: which bucket an addon belongs in.
GROUPS = {
    "Core": ["main", "common", "cba_settings", "media", "modules", "compatibility"],
    "Gear - worn": ["headware", "headware_jca_ie", "headware_mig", "uniform", "uniform_eu", "uniform_sof",
                    "vests", "vests_efa", "vests_jca", "vests_mig", "vests_sof",
                    "backpack", "boc", "faces", "flags", "nvg", "vs17"],
    "Gear - carried": ["weapons", "weapons_jca", "weapons_mcc", "weapons_sps", "optics", "optics_ef", "equipment",
                       "medbags", "flares", "smoke", "tagging"],
    "Systems": ["hacking", "patrol_base", "evac", "respawn", "spectator", "towing",
                "killtracker", "insurgents", "tasks", "admin", "curator", "chat",
                "back_to_game", "safestart", "remotesensors", "iads", "airdefence", "adsite"],
        "Gameplay tweaks": ["ballistics", "suppress", "fatigue", "difficulty", "friendly_fire",
                        "grass", "hiteffects", "medical_treatment", "acm", "nobuttstuff",
                        "pointing", "pronelauncher", "safe_grenades", "safeboating",
                        "ai_disembark", "dtvd", "tanks", "spotlight_block"],
    "Interface": ["ui_tweaks", "notify", "loading", "main_menu", "map", "nightvision",
                  "debug_console"],
}
GROUP_OF = {a: g for g, lst in GROUPS.items() for a in lst}


def read(p):
    try:
        return io.open(p, encoding="utf-8", errors="replace").read()
    except OSError:
        return ""


def strip_comments(s):
    s = re.sub(r"/\*.*?\*/", "", s, flags=re.S)
    return re.sub(r"//[^\n]*", "", s)


# ---------------------------------------------------------------------------
# scanning
# ---------------------------------------------------------------------------
def scan_addon(base, name):
    d = os.path.join(base, name)
    cfg = strip_comments(read(os.path.join(d, "config.cpp")))
    sc = read(os.path.join(d, "script_component.hpp"))

    m = re.search(r"#define COMPONENT_BEAUTIFIED (.+)", sc)
    nice = m.group(1).strip() if m else name.replace("_", " ").title()

    deps = []
    m = re.search(r"requiredAddons\[\]\s*=\s*\{(.*?)\}", cfg, re.S)
    if m:
        deps = [x.strip().strip('"') for x in m.group(1).split(",") if x.strip()]

    def arr(field):
        mm = re.search(field + r"\[\]\s*=\s*\{(.*?)\};", cfg, re.S)
        if not mm or not mm.group(1).strip():
            return 0
        return len([x for x in mm.group(1).split(",") if x.strip()])

    fdir = os.path.join(d, "functions")
    fns = len([f for f in os.listdir(fdir) if f.startswith("fnc_")]) if os.path.isdir(fdir) else 0

    return {
        "name": name, "nice": nice, "deps": deps,
        "units": arr("units"), "weapons": arr("weapons"),
        "fns": fns,
        "settings": settings_of(d),
        "modules": modules_of(d),
        "skip": "skipWhenMissingDependencies" in cfg,
    }


def stringtable_of(d):
    """key -> English text, so LSTRING() labels resolve to real words."""
    txt = read(os.path.join(d, "stringtable.xml"))
    out = {}
    for m in re.finditer(r'<Key ID="([^"]+)">(.*?)</Key>', txt, re.S):
        e = re.search(r"<English>(.*?)</English>", m.group(2), re.S)
        if e:
            out[m.group(1).lower()] = re.sub(r"\s+", " ", e.group(1)).strip()
    return out


def _lit(tok, st, comp):
    """A setting label/category is a quoted string or an LSTRING/ELSTRING macro."""
    tok = tok.strip().rstrip(",").strip()
    m = re.match(r'^"(.*)"$', tok, re.S)
    if m:
        return m.group(1)
    m = re.match(r"^L?C?STRING\((\w+)\)$", tok)
    if m:
        return st.get(("str_jmfsb_%s_%s" % (comp, m.group(1))).lower(), m.group(1))
    m = re.match(r"^E?L?C?STRING\(\s*(\w+)\s*,\s*(\w+)\s*\)$", tok)
    if m:
        return st.get(("str_jmfsb_%s_%s" % (m.group(1), m.group(2))).lower(), m.group(2))
    if tok == "COMPONENT_NAME":
        return comp.replace("_", " ").title()
    if "format" in tok or "QUOTE" in tok:
        return "(built at runtime)"
    return tok


def _split_top(s):
    """Split an SQF array body on top-level commas."""
    out, depth, cur, instr = [], 0, "", False
    for ch in s:
        if ch == '"':
            instr = not instr
        if not instr:
            if ch in "[{(":
                depth += 1
            elif ch in "]})":
                depth -= 1
            elif ch == "," and depth == 0:
                out.append(cur); cur = ""; continue
        cur += ch
    if cur.strip():
        out.append(cur)
    return out


def settings_of(d):
    txt = strip_comments(read(os.path.join(d, "initSettings.inc.sqf")))
    if not txt.strip():
        return []
    comp = os.path.basename(d)
    st = stringtable_of(d)
    out = []
    for block in txt.split("] call CBA_fnc_addSetting;"):
        i = block.find("[")
        if i < 0:
            continue
        parts = _split_top(block[i + 1:])
        if len(parts) < 5:
            continue
        var = parts[0].strip()
        m = re.match(r"QGVAR\((\w+)\)", var)
        var = m.group(1) if m else var.strip('"')
        typ = parts[1].strip().strip('"')
        lbl = _split_top(parts[2].strip().lstrip("[").rstrip("]"))
        cat = _split_top(parts[3].strip().lstrip("[").rstrip("]"))
        out.append({
            "var": var, "type": typ,
            "label": _lit(lbl[0], st, comp) if lbl else var,
            "tip": _lit(lbl[1], st, comp) if len(lbl) > 1 else "",
            "cat": " > ".join(_lit(c, st, comp) for c in cat),
            "default": re.sub(r"\s+", " ", parts[4].strip()),
        })
    return out


# A module class is written out (jmfsb_moduleCAS) or, in an addon that owns it
# outright, as GVAR(x) - expanded below to jmfsb_<addon>_x, or every module
# written the guideline way would be missing from MODULES.md.
MODULE_RE = re.compile(r"class\s+(\w+|GVAR\(\w+\))\s*:\s*Module_F\s*\{(.*?)\n    \};", re.S)


def modules_of(d):
    out = []
    for f in os.listdir(d) if os.path.isdir(d) else []:
        if not f.endswith(".hpp"):
            continue
        txt = strip_comments(read(os.path.join(d, f)))
        for m in MODULE_RE.finditer(txt):
            cls, body = m.group(1), m.group(2)
            g = re.match(r"GVAR\((\w+)\)", cls)
            if g:
                cls = "jmfsb_%s_%s" % (os.path.basename(d), g.group(1))
            def get(k):
                mm = re.search(k + r'\s*=\s*"([^"]*)"', body)
                if mm:
                    return mm.group(1)
                # BIS's array-of-lines form: description[] = {"a", "", "b"};
                # An empty element is a paragraph break, so it joins to a blank
                # line rather than a stray double space.
                mm = re.search(k + r'\[\]\s*=\s*\{(.*?)\};', body, re.S)
                if not mm:
                    return ""
                parts = re.findall(r'"([^"]*)"', mm.group(1))
                out, cur = [], []
                for s in parts:
                    # A blank element ends a paragraph; an INDENTED one is a list
                    # item and keeps its own line, or every dropdown option runs
                    # together into one unreadable sentence.
                    if s.strip() == "" or s.startswith(" "):
                        if cur:
                            out.append(" ".join(cur)); cur = []
                    if s.strip():
                        cur.append(s.strip())
                        if s.startswith(" ") and not s.rstrip().endswith(","):
                            out.append(" ".join(cur)); cur = []
                if cur:
                    out.append(" ".join(cur))
                return "<br>".join(out)
            # AEDIT / APICK / ABOOL / AMB_TYPE / DEF_TYPE / TYPE_ARGS ... every
            # addon rolls its own attribute macro, so match the shape not the name
            attrs = re.findall(r"^\s*[A-Z][A-Z_0-9]*\((\w+),", body, re.M)
            attrs += re.findall(r"\n            class (\w+):\s*(?:Combo|Edit)", body)
            out.append({"class": cls, "display": get("displayName"),
                        "category": get("category"), "desc": get("description"),
                        "attrs": sorted(set(a for a in attrs if a not in ("Attributes",)))})
    return out


def forced_settings():
    txt = read(os.path.join(ADDONS, "cba_settings", "cba_settings.sqf"))
    out = []
    for m in re.finditer(r"^\s*force\s+(?:force\s+)?(\w+)\s*=\s*([^;]+);", txt, re.M):
        out.append((m.group(1), m.group(2).strip()))
    return out


# ---------------------------------------------------------------------------
# writing
# ---------------------------------------------------------------------------
def w(name, lines):
    io.open(os.path.join(DOCS, name), "w", encoding="utf-8", newline="\n").write(
        "\n".join(lines).rstrip("\n") + "\n")
    print("  docs/%s" % name)


def main():
    os.makedirs(DOCS, exist_ok=True)
    addons = [scan_addon(ADDONS, a) for a in sorted(os.listdir(ADDONS))
              if os.path.isdir(os.path.join(ADDONS, a))]
    opts = [scan_addon(OPTIONALS, a) for a in sorted(os.listdir(OPTIONALS))
            if os.path.isdir(os.path.join(OPTIONALS, a))] if os.path.isdir(OPTIONALS) else []
    by = {a["name"]: a for a in addons}

    n_set = sum(len(a["settings"]) for a in addons)
    n_mod = sum(len(a["modules"]) for a in addons)
    n_fn = sum(a["fns"] for a in addons)

    # ---- index -----------------------------------------------------------
    idx = ["# 1st Joint Multi-Functional Strike Battalion - mod documentation", "",
           "Generated by `tools/gen_docs.py` from the addon sources. Re-run it after",
           "changing an addon; do not hand-edit these files.", "",
           "| | |", "|---|---|",
           "| Addons | %d |" % len(addons),
           "| Optional addons | %d |" % len(opts),
           "| CBA settings | %d |" % n_set,
           "| Eden modules | %d |" % n_mod,
           "| Functions | %d |" % n_fn, "",
           "## Contents", "",
           "- [CHANGELOG.md](CHANGELOG.md) - change notes by day, from the fix records and the dated requests in the code",
           "- [ADDONS.md](ADDONS.md) - every addon, what it ships, what it needs",
           "- [SETTINGS.md](SETTINGS.md) - every CBA setting and the server-forced values",
           "- [MODULES.md](MODULES.md) - every Eden module and its attributes",
           "- [SETUP.md](SETUP.md) - **start here**: setting up a jmfsb mission",
           "- [SMOKE_TEST.md](SMOKE_TEST.md) - the acceptance walk-through; run this before planning anything else",
           "- [DESIGN_INTEL_SYSTEM_PART4.md](DESIGN_INTEL_SYSTEM_PART4.md) - the current design. Parts 1-3 are superseded",
           "- [HANDOFF_PART4.md](HANDOFF_PART4.md) - what the Part 4 build delivered, deviated on, and left open",
           "- [SETUP_HACKING.md](SETUP_HACKING.md) - mission-maker walkthrough for the hacking system",
           "- [FA_MAGAZINE_MAP.md](FA_MAGAZINE_MAP.md) - vanilla to futureAmmo magazine map",
           "- [DRONES_BY_SIDE.md](DRONES_BY_SIDE.md) - drone classes by side (archived factions)",
           "",
           "The root [README.md](../README.md) covers credits and licensing only."]
    w("README.md", idx)

    # ---- addons ----------------------------------------------------------
    L = ["# Addons", "",
         "`units` / `weapons` are the CfgPatches counts, `fns` the number of functions.",
         "A dependency in **bold** is an external mod.", ""]
    seen = set()
    for group in list(GROUPS) + ["Other"]:
        names = [a for a in addons if GROUP_OF.get(a["name"], "Other") == group]
        if not names:
            continue
        L += ["## %s" % group, "", "| Addon | Name | units | weapons | fns | Requires |", "|---|---|--:|--:|--:|---|"]
        for a in names:
            seen.add(a["name"])
            deps = [d for d in a["deps"] if d != "jmfsb_main"]
            ext = ["**%s**" % d if not d.startswith(("jmfsb_", "A3_", "a3_")) else d for d in deps]
            L.append("| `%s` | %s | %s | %s | %s | %s |" % (
                a["name"], a["nice"], a["units"] or "", a["weapons"] or "", a["fns"] or "",
                ", ".join(ext[:6]) + (" ..." if len(ext) > 6 else "") or "-"))
        L.append("")
    if opts:
        L += ["## Optionals", "",
              "Not loaded by default - copy out of `optionals/` to use.", "",
              "| Addon | Name | units | weapons | fns |", "|---|---|--:|--:|--:|"]
        for a in opts:
            L.append("| `%s` | %s | %s | %s | %s |" % (
                a["name"], a["nice"], a["units"] or "", a["weapons"] or "", a["fns"] or ""))
        L.append("")
    L += ["## Graceful degradation", "",
          "These declare `skipWhenMissingDependencies`, so they drop out quietly when an",
          "external mod is absent instead of breaking the load:", "",
          ", ".join("`%s`" % a["name"] for a in addons + opts if a["skip"]) or "none"]
    w("ADDONS.md", L)

    # ---- settings --------------------------------------------------------
    L = ["# CBA settings", "",
         "Everything under **Options > Addon Options**. `Default` is the value the addon",
         "ships with, which a mission or the forced list below can override.", ""]
    for a in addons:
        if not a["settings"]:
            continue
        L += ["## %s (`%s`)" % (a["nice"], a["name"]), "",
              "| Setting | Type | Category | Default | What it does |", "|---|---|---|---|---|"]
        for s in a["settings"]:
            L.append("| %s | %s | %s | `%s` | %s |" % (
                s["label"], s["type"], s["cat"], s["default"][:40],
                s["tip"].replace("|", "\\|")[:150]))
        L.append("")
    forced = forced_settings()
    if forced:
        L += ["## Forced by `cba_settings`", "",
              "`addons/cba_settings/cba_settings.sqf` force-sets %d values at mission start."
              % len(forced),
              "A forced setting cannot be changed in-game, and overrides the defaults above.", "",
              "| Variable | Value |", "|---|---|"]
        for k, v in forced:
            L.append("| `%s` | `%s` |" % (k, v[:60]))
    w("SETTINGS.md", L)

    # ---- modules ---------------------------------------------------------
    L = ["# Eden modules", "",
         "Place from the 3DEN entity list under the listed category.", ""]
    for a in addons:
        if not a["modules"]:
            continue
        L += ["## %s (`%s`)" % (a["nice"], a["name"]), ""]
        for m in a["modules"]:
            L += ["### %s" % (m["display"] or m["class"]), "",
                  "- **Class** `%s`" % m["class"],
                  "- **Category** %s" % (m["category"] or "-")]
            if m["desc"]:
                L.append("- %s" % m["desc"])
            if m["attrs"]:
                L.append("- **Attributes** " + ", ".join("`%s`" % x for x in m["attrs"]))
            L.append("")
    w("MODULES.md", L)
    print("\n%d addons, %d optionals, %d settings, %d modules, %d functions"
          % (len(addons), len(opts), n_set, n_mod, n_fn))


if __name__ == "__main__":
    main()
