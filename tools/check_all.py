#!/usr/bin/env python3
"""Run every check in one command, and exit non-zero if any of them fails.

    python tools/check_all.py

WHY THIS IS A SCRIPT AND NOT A BUILD HOOK: HEMTT's Rhai hooks can read project
config and touch the file system, but there is no way to run a process from one
(`command` is not a function), so `hemtt release` cannot be made to run these.
Until that changes, enforcement is this one command before a build - or a git
pre-commit hook calling it, which is a line in .git/hooks/pre-commit:

    python tools/check_all.py || exit 1

`hemtt check` is run first because it is the one that catches the crashes.
"""

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CHECKS = [
    ("hemtt check", ["hemtt", "check"]),
    ("ctab configs", [sys.executable, "tools/check_ctab_configs.py"]),
    ("sqf", [sys.executable, "tools/sqf_validator.py"]),
    ("config style", [sys.executable, "tools/config_style_checker.py"]),
    ("stringtables", [sys.executable, "tools/stringtable_validator.py"]),
    ("generated art", [sys.executable, "tools/check_art.py"]),
    ("addon readmes", [sys.executable, "tools/check_readmes.py"]),
    # Architecture, not style. These encode decisions that were expensive to
    # make and are cheap to break by accident - see the file's header.
    ("invariants", [sys.executable, "tools/check_invariants.py"]),
    ("plumbing", [sys.executable, "tools/check_plumbing.py"]),
    # Inheritance across addon boundaries. A parent that is not declared in the
    # same config builds a class with NO parent, silently.
    ("externals", [sys.executable, "tools/check_externals.py"]),
    # CfgPatches units[]/weapons[] against the classes that exist. The same
    # drift has shipped three times; HEMTT calls it L-C15.
    ("cfgpatches", [sys.executable, "tools/check_patches.py"]),
    # A client DLL changed is a new BattlEye submission (docs/SIGNING.md).
    ("dll lock", [sys.executable, "tools/check_dll_lock.py"]),
]


def main():
    failed = []
    skipped = []
    for name, cmd in CHECKS:
        try:
            result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        except FileNotFoundError:
            # A MISSING TOOL MUST NOT TAKE THE SUITE WITH IT. hemtt is not on
            # every machine that touches this repo, and letting the exception
            # escape meant one absent binary silently skipped all nine of the
            # checks that were going to run after it.
            skipped.append(name)
            print("%-16s SKIPPED - %s is not on PATH" % (name, cmd[0]))
            continue
        out = (result.stdout or "") + (result.stderr or "")

        # hemtt exits 0 on warnings, so its own exit code is not the whole story.
        # HINTS FAIL TOO (user, 2026-11-01: "why do you keep doing this, fix
        # it"): help[...] lints passed the gate and came back to the user to
        # paste in by the dozen. Nothing ships with one.
        noisy = name == "hemtt check" and ("warning[" in out or "error[" in out or "help[" in out)

        if result.returncode != 0 or noisy:
            failed.append(name)
            print("\n=== %s FAILED ===" % name)
            print(out.strip()[-4000:])
        else:
            print("%-16s ok" % name)

    print()
    if skipped:
        print("SKIPPED: %s - not run, so not proven" % ", ".join(skipped))
    if failed:
        print("FAILED: %s" % ", ".join(failed))
        return 1
    print("all checks that could run passed" if skipped else "all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
