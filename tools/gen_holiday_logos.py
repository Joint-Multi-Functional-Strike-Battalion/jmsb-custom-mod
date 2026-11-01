#!/usr/bin/env python3
"""Holiday crests for the mission loading screen.

art/JMSB-holidays/<size>/jmsb-NN-<holiday>.png are the sources, in three
sizes. The 1024 ships: the crest is drawn 512 px square (LOGO_SIZE_PX in
addons/loading) and the engine's mipmaps take it there, with one doubling of
headroom. Each becomes addons/loading/ui/holidays/<className>.paa, named for
its class under jmfsb_loading_CfgLoadingScreen >> Holidays
(addons/loading/CfgLoadingScreen.hpp), which is how the config spells the
path: QPATHTOF(ui\\holidays\\<className>.paa). A new crest is a line in LOGOS
here and a class there.

Run:  python tools/gen_holiday_logos.py    (hemtt on PATH)
"""

import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ART = os.path.join(ROOT, "art", "JMSB-holidays", "1024")
OUT = os.path.join(ROOT, "addons", "loading", "ui", "holidays")

# source stem -> config class (= .paa name)
LOGOS = {
    "jmsb-01-new-years-day": "newYearsDay",
    "jmsb-02-memorial-day": "memorialDay",
    "jmsb-03-independence-day": "independenceDay",
    "jmsb-04-indigenous-peoples-day": "indigenousPeoplesDay",
    "jmsb-05-veterans-day": "veteransDay",
    "jmsb-06-thanksgiving": "thanksgiving",
    "jmsb-07-christmas": "christmas",
    "jmsb-08-valentines-day": "valentinesDay",
    "jmsb-09-st-patricks-day": "stPatricksDay",
    "jmsb-10-easter": "easter",
    "jmsb-11-halloween": "halloween",
}


def to_paa(hemtt, png, paa):
    # hemtt refuses to overwrite and still exits 0, so the target goes first.
    if os.path.exists(paa):
        os.remove(paa)
    subprocess.run([hemtt, "utils", "paa", "convert", png, paa], check=True,
                   stdout=subprocess.DEVNULL)
    if not os.path.exists(paa):
        raise SystemExit("hemtt did not write %s" % paa)
    print("  wrote %s" % os.path.relpath(paa, ROOT))


def main():
    if not os.path.isdir(ART):
        raise SystemExit("%s not found - run from the repo" % os.path.relpath(ART, ROOT))
    hemtt = shutil.which("hemtt")
    if not hemtt:
        raise SystemExit("hemtt not on PATH - nothing written")
    os.makedirs(OUT, exist_ok=True)
    for stem, name in LOGOS.items():
        png = os.path.join(ART, stem + ".png")
        if not os.path.isfile(png):
            raise SystemExit("%s missing" % os.path.relpath(png, ROOT))
        to_paa(hemtt, png, os.path.join(OUT, name + ".paa"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
