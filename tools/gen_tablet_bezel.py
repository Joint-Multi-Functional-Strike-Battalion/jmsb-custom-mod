"""Rebrand the vendored tablet bezel with the jmfsb logo.

MRHMilsimTools' tablet art carries an "MRHTECH" wordmark stamped on the chin
below the screen. This paints it out and stamps the jmfsb logo in its place, so
the device in jmfsb's hands is jmfsb's device.

The stamp area is a flat, near-uniform strip of the moulding, so painting it out
is a per-row fill sampled from clean pixels either side of the wordmark rather
than a blur or a clone: it leaves the strip's own vertical shading intact.

Run:  python tools/gen_tablet_bezel.py
      (reads art/tablet_src.paa, writes data/tablet.paa)

Rerunning is safe - it always starts from the untouched vendored copy.
"""

import os
import shutil
import subprocess
import tempfile

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "addons", "hacking", "data"))
LOGO = os.path.normpath(os.path.join(HERE, "..", "addons", "media", "images", "newlogo_3_512.png"))

SRC = os.path.normpath(os.path.join(HERE, "..", "art", "tablet_src.paa"))  # untouched vendored art
OUT = os.path.join(DATA, "tablet.paa")         # what the dialog uses

# The wordmark, measured off the 2048² art: x 956..1131, y 1455..1488. Painted
# out with margin so no anti-aliased edge survives.
WIPE = (0.450, 0.7020, 0.575, 0.7360)

# Where the badge goes. Centred on the chin - the flat strip runs y 1423..1541,
# so a badge this tall clears both edges.
BADGE_CY = 0.7195
BADGE_H = 0.044


def wipe_wordmark(im):
    """Fill the wordmark box row by row, interpolating between clean pixels to
    its left and right so the moulding's shading carries through."""
    W, H = im.size
    x0, y0, x1, y1 = (int(WIPE[0] * W), int(WIPE[1] * H),
                      int(WIPE[2] * W), int(WIPE[3] * H))
    px = im.load()
    # Sample well clear of the wordmark on both sides.
    lx, rx = x0 - 40, x1 + 40
    for y in range(y0, y1):
        left = px[lx, y]
        right = px[rx, y]
        span = x1 - x0
        for x in range(x0, x1):
            t = (x - x0) / span
            px[x, y] = tuple(
                int(left[c] * (1 - t) + right[c] * t) for c in range(len(left))
            )
    return im


def stamp_logo(im):
    W, H = im.size
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.crop(logo.getbbox())      # the art has a wide transparent margin

    h = int(H * BADGE_H)
    w = max(1, int(logo.size[0] * h / logo.size[1]))
    logo = logo.resize((w, h), Image.LANCZOS)

    im.paste(logo, (int(W / 2 - w / 2), int(H * BADGE_CY - h / 2)), logo)
    return im


def main():
    if not os.path.exists(SRC):
        raise SystemExit(
            "%s not found. That is the untouched vendored art, kept outside "
            "addons/ so it is not packed into the pbo. Restore it from "
            "MRHMilsimTools/Addons/MRHSoldierTab/paa/tablet.paa." % SRC)

    tmp = tempfile.mkdtemp()
    png_in = os.path.join(tmp, "src.png")
    png_out = os.path.join(tmp, "out.png")

    subprocess.run(["hemtt", "utils", "paa", "convert", SRC, png_in],
                   check=True, capture_output=True)

    im = Image.open(png_in).convert("RGBA")
    print("  loaded %dx%d" % im.size)
    im = wipe_wordmark(im)
    print("  wordmark painted out")
    im = stamp_logo(im)
    print("  jmfsb logo stamped")
    im.save(png_out)

    # hemtt's converter silently declines to overwrite an existing file, so
    # write beside it and move the result into place.
    staged = os.path.join(tmp, "out.paa")
    subprocess.run(["hemtt", "utils", "paa", "convert", png_out, staged],
                   check=True, capture_output=True)
    shutil.move(staged, OUT)
    print("  wrote %s" % OUT)


if __name__ == "__main__":
    main()
