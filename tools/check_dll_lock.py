#!/usr/bin/env python3
"""The mod root's Windows extension DLLs must match tools/dlls.sha256.

    python tools/check_dll_lock.py

A client DLL is whitelisted by BattlEye per build (docs/SIGNING.md): a new hash
is a new submission, and until it is whitelisted the DLL does not load on a
BattlEye server. So a DLL must never change by accident - a rebuild, a copy
from the wrong folder, a re-sign. Changing one is a decision: rebuild, sign,
submit, then put the new hash in tools/dlls.sha256 in the same commit.

The Linux .so files run only on the server and are not locked.
"""
import glob
import hashlib
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCK = os.path.join(ROOT, "tools", "dlls.sha256")


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def main():
    locked = {}
    with open(LOCK, encoding="utf-8") as f:
        for line in f:
            if line.strip():
                digest, name = line.split()
                locked[name] = digest

    present = {os.path.basename(p) for p in glob.glob(os.path.join(ROOT, "*_x64.dll"))}
    errors = []
    for name in sorted(present | set(locked)):
        if name not in locked:
            errors.append("%s is not in tools/dlls.sha256" % name)
        elif name not in present:
            errors.append("%s is in tools/dlls.sha256 but not in the mod root" % name)
        elif sha256(os.path.join(ROOT, name)) != locked[name]:
            errors.append("%s changed: a new BattlEye submission (docs/SIGNING.md). "
                          "If meant, put its new hash in tools/dlls.sha256" % name)

    for e in errors:
        print(e)
    if not errors:
        print("%d DLLs match tools/dlls.sha256" % len(present))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
