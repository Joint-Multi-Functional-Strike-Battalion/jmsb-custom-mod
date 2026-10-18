#!/usr/bin/env python3
"""tools/_dump/optics.txt from the PBOs on disk - the in-game dump (tools/dump_optics.sqf) without starting the game.

    python tools/optics_from_pbos.py [--preset <launcher .preset2>]
    python tools/gen_nvg_optics.py

The load order is the JMSB launcher preset (default: jmsb_b1_edit): the base game and its DLC, every Workshop mod
in the preset, and the local JMSB release. Each config.bin's CfgPatches and CfgWeapons are read (the rapified
walker is tools/aegis_port/vanilla_config.py's), the files are merged in requiredAddons order the way the engine
merges them, and every optic (ItemInfo type 201) is written out with the classes it inherits from - the same
CLASS / NEST lines the in-game dump writes, so gen_nvg_optics.py reads either.

WHAT IT CANNOT SEE. Creator DLC is encrypted (.ebo) and is skipped; a file whose requiredAddons name a patch that
nothing in the load order defines is skipped too, as the game would. Text config.cpp inside a PBO (rare in a
release) goes through HEMTT's converter; one that will not convert alone is counted. For those, run the in-game
dump instead.
"""
import argparse
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "aegis_port"))
from vanilla_config import A3, FOLDERS, N, child, pbo_index, pbo_read  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKSHOP = r"E:/SteamLibrary/steamapps/workshop/content/107410"
PRESET = r"C:/Users/jwise/AppData/Local/Arma 3 Launcher/Presets/jmsb_b1_edit.preset2"
OUT = os.path.join(ROOT, "tools", "_dump", "optics.txt")
OPTIC_TYPE = 201
KEEP = {"cfgweapons", "cfgpatches"}


class Rap:
    """A rapified config.bin: CfgPatches and CfgWeapons in full, everything else skipped."""

    def __init__(self, b):
        self.b = b

    def cstr(self, p):
        e = self.b.index(b"\0", p)
        return self.b[p:e].decode("utf-8", "replace"), e + 1

    def cint(self, p):
        v, s = 0, 0
        while True:
            c = self.b[p]
            p += 1
            v |= (c & 0x7F) << s
            if not c & 0x80:
                return v, p
            s += 7

    def arr(self, p):
        n, p = self.cint(p)
        out = []
        for _ in range(n):
            t = self.b[p]
            p += 1
            if t in (0, 4):
                v, p = self.cstr(p)
            elif t == 1:
                v = struct.unpack_from("<f", self.b, p)[0]
                p += 4
            elif t == 2:
                v = struct.unpack_from("<i", self.b, p)[0]
                p += 4
            elif t == 3:
                v, p = self.arr(p)
            elif t == 6:
                v = struct.unpack_from("<q", self.b, p)[0]
                p += 8
            else:
                raise ValueError("array element type %d" % t)
            out.append(v)
        return out, p

    def body(self, off, node, depth):
        parent, p = self.cstr(off)
        node.p = parent
        n, p = self.cint(p)
        for _ in range(n):
            t = self.b[p]
            p += 1
            if t == 0:
                name, p = self.cstr(p)
                o = struct.unpack_from("<I", self.b, p)[0]
                p += 4
                if depth == 0 and name.lower() not in KEEP:
                    continue
                c = child(node, name)
                c.b, c.n = True, name
                self.body(o, c, depth + 1)
            elif t == 1:
                st = self.b[p]
                p += 1
                name, p = self.cstr(p)
                if st in (0, 3, 4):
                    v, p = self.cstr(p)
                elif st in (1, 2):
                    v = struct.unpack_from("<f" if st == 1 else "<i", self.b, p)[0]
                    p += 4
                elif st == 6:
                    v = struct.unpack_from("<q", self.b, p)[0]
                    p += 8
                else:
                    raise ValueError("value subtype %d" % st)
                node.v[name.lower()] = v
            elif t == 2:
                name, p = self.cstr(p)
                v, p = self.arr(p)
                node.v[name.lower()] = v
            elif t == 3:
                name, p = self.cstr(p)
                if depth > 0:
                    child(node, name)
            elif t == 4:
                name, p = self.cstr(p)
            elif t == 5:
                p += 4
                name, p = self.cstr(p)
                v, p = self.arr(p)
                key = name.lower()
                node.v[key] = list(node.v.get(key, [])) + v
            else:
                raise ValueError("entry type %d" % t)

    def load(self):
        if self.b[:4] != b"\0raP":
            raise ValueError("not rapified")
        root = N("")
        self.body(16, root, 0)
        return root


def json_tree(data):
    """A text config.cpp, as HEMTT's JSON (a class is an object with __parent, a declaration is null)."""
    def fill(node, obj, depth):
        for key, val in obj.items():
            if key == "__parent":
                continue
            if isinstance(val, dict):
                if depth == 0 and key.lower() not in KEEP:
                    continue
                c = child(node, key)
                c.b, c.n, c.p = True, key, val.get("__parent", "") or ""
                fill(c, val, depth + 1)
            elif val is None:
                if depth > 0:
                    child(node, key)
            else:
                node.v[key.lower()] = val
    root = N("")
    fill(root, data, 0)
    return root


def text_config(path, entry, tmp):
    """A text config.cpp from a PBO, through HEMTT's converter. None when it will not convert alone (an
    #include of another file in the PBO, a macro from elsewhere)."""
    src, out = os.path.join(tmp, "config.cpp"), os.path.join(tmp, "config.json")
    for f in (src, out):
        if os.path.exists(f):
            os.remove(f)
    with open(src, "wb") as fh:
        fh.write(pbo_read(path, entry))
    subprocess.run(["hemtt", "utils", "config", "convert", src, out, "-f", "json"], capture_output=True)
    if not os.path.isfile(out):
        # most that fail include a file of their own PBO (BIS_AddonInfo.hpp) - again without the includes
        text = open(src, encoding="utf-8", errors="replace").read()
        with open(src, "w", encoding="utf-8") as fh:
            fh.write(re.sub(r"(?m)^\s*#include.*$", "", text))
        subprocess.run(["hemtt", "utils", "config", "convert", src, out, "-f", "json"], capture_output=True)
    if not os.path.isfile(out):
        return None
    try:
        return json_tree(json.load(open(out, encoding="utf-8")))
    except ValueError:
        return None


def preset_mods(path):
    out = []
    for e in ET.parse(path).getroot().iter("id"):
        kind, _, ref = (e.text or "").partition(":")
        if kind == "steam":
            out.append((os.path.join(WORKSHOP, ref), ref))
        elif kind == "local":
            out.append((ref.rstrip("\\/"), "jmsb"))
    return out


def mod_label(folder, ref):
    if ref == "jmsb":
        return "jmsb"
    for f in ("meta.cpp", "mod.cpp"):
        p = os.path.join(folder, f)
        if os.path.isfile(p):
            m = re.search(r'(?im)^\s*name\s*=\s*"([^"]+)"', open(p, encoding="utf-8", errors="replace").read())
            if m:
                return m.group(1)
    return ref


def merge(dst, src, patches, depth, sources):
    for c in src.c.values():
        d = child(dst, c.n)
        if c.b:
            if not d.b:
                d.n = c.n
            d.b = True
            d.p = c.p
            if depth == 1:
                sources.setdefault(c.n.lower(), []).extend(patches)
        d.v.update(c.v)
        merge(d, c, patches, depth + 1, sources)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preset", default=PRESET)
    a = ap.parse_args()

    sources = [(os.path.join(A3, f), "") for f in FOLDERS]
    sources += [(os.path.join(folder, "addons"), mod_label(folder, ref)) for folder, ref in preset_mods(a.preset)]

    files, text_configs, ebo, bad = [], 0, 0, []
    tmp = tempfile.mkdtemp(prefix="optics_")
    for folder, label in sources:
        for r, _d, fs in os.walk(folder):
            for f in sorted(fs):
                lo = f.lower()
                if lo.endswith(".ebo"):
                    ebo += 1
                if not lo.endswith(".pbo"):
                    continue
                path = os.path.join(r, f)
                try:
                    _props, entries = pbo_index(path)
                except Exception as e:  # noqa: BLE001
                    bad.append("%s: %s" % (path, e))
                    continue
                for e in entries:
                    name = e[0].lower().replace("/", "\\")
                    if name.endswith("config.cpp"):
                        tree = text_config(path, e, tmp)
                        if tree is None:
                            text_configs += 1
                            continue
                    elif name.endswith("config.bin"):
                        try:
                            tree = Rap(pbo_read(path, e)).load()
                        except Exception as ex:  # noqa: BLE001
                            bad.append("%s:%s: %s" % (path, e[0], ex))
                            continue
                    else:
                        continue
                    pat = tree.c.get("cfgpatches")
                    names = [c.n for c in pat.c.values()] if pat else []
                    req = sorted({str(x).lower() for c in (pat.c.values() if pat else []) for x in c.v.get("requiredaddons", [])})
                    files.append({"label": label, "path": path, "tree": tree, "patches": names, "req": req})

    shutil.rmtree(tmp, ignore_errors=True)
    # NOT OUR OWN NVG PATCHES: they are what gen_nvg_optics.py writes from this dump, so reading them back would
    # show every scope already patched - and the next run would write nothing and drop them
    files = [f for f in files if not any(p.lower().startswith("jmfsb_compatibility_nvg_optics") for p in f["patches"])]
    defined = {p.lower() for f in files for p in f["patches"]}
    loadable = [f for f in files if all(r in defined for r in f["req"])]
    skipped = len(files) - len(loadable)

    # requiredAddons order: a file goes after every file whose patches it requires
    owner = {p.lower(): i for i, f in enumerate(loadable) for p in f["patches"]}
    order, state = [], {}

    def visit(i):
        if state.get(i) == 2:
            return
        if state.get(i) == 1:
            return                                         # a cycle: the game warns and goes on
        state[i] = 1
        for r in loadable[i]["req"]:
            j = owner.get(r)
            if j is not None and j != i:
                visit(j)
        state[i] = 2
        order.append(i)

    sys.setrecursionlimit(100000)
    for i in range(len(loadable)):
        visit(i)

    root = N("")
    label_of, sources = {}, {}
    for i in order:
        f = loadable[i]
        weapons = f["tree"].c.get("cfgweapons")
        if weapons is None:
            continue
        for c in weapons.c.values():
            if c.b:
                label_of.setdefault(c.n.lower(), f["label"])
        merge(child(root, "CfgWeapons"), weapons, f["patches"], 1, sources)
    cfg = root.c["cfgweapons"].c

    def root_chain(name):
        out = []
        while name and name.lower() in cfg and len(out) < 64:
            out.append(cfg[name.lower()])
            name = cfg[name.lower()].p
        return out

    def nested(cls, parts):
        """The nodes a nested path resolves through, nearest first: the nearest class that writes it, and
        from there its parent - the same name in the class's parent (class X: X), or a root class."""
        out, name, hops = [], cls, 0
        while name and name.lower() in cfg and hops < 64:
            hops += 1
            node = cfg[name.lower()]
            here = node
            for part in parts:
                here = here.c.get(part.lower())
                if here is None or not here.b:
                    here = None
                    break
            if here is not None:
                out.append(here)
                base = here.p
                if not base:
                    return out
                if base.lower() != parts[-1].lower():
                    return out + (root_chain(base) if len(parts) == 1 else [])
            name = node.p
        return out

    def value(cls, parts, key):
        for node in nested(cls, parts):
            if key in node.v:
                return node.v[key]
        return None

    optics = [c.n for c in cfg.values() if c.b and value(c.n, ["ItemInfo"], "type") == OPTIC_TYPE]

    lines, seen = [], set()
    for optic in optics:
        name = optic
        while name and name.lower() in cfg and name.lower() not in seen:
            seen.add(name.lower())
            node = cfg[name.lower()]
            lines.append("CLASS;%s;%s;%s;%s" % (node.n, node.p, label_of.get(name.lower(), ""), "|".join(dict.fromkeys(sources.get(name.lower(), [])))))
            info = node.c.get("iteminfo")
            if info is not None and info.b:
                lines.append("NEST;%s;ItemInfo;%s" % (node.n, info.p))
                modes = info.c.get("opticsmodes")
                if modes is not None and modes.b:
                    lines.append("NEST;%s;ItemInfo/OpticsModes;%s" % (node.n, modes.p))
                    for mode in modes.c.values():
                        if not mode.b:
                            continue
                        own = "visionmode" in mode.v
                        vm = mode.v.get("visionmode", []) if own else []
                        lines.append("NEST;%s;ItemInfo/OpticsModes/%s;%s;%d;%s" % (node.n, mode.n, mode.p, int(own), "|".join(str(x) for x in vm)))
            name = node.p

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")
    print("%d config.bin read, %d skipped (missing requiredAddons), %d text config.cpp would not convert, %d .ebo not readable"
          % (len(files), skipped, text_configs, ebo))
    if bad:
        print("%d unreadable: %s" % (len(bad), "; ".join(bad[:5])))
    print("%d optics, %d lines -> %s" % (len(optics), len(lines), OUT))


if __name__ == "__main__":
    main()
