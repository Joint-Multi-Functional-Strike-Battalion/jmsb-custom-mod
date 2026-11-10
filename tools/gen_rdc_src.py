#!/usr/bin/env python3
"""The RDC's frame render, cut from the MPU5 asset's texture.

The Rugged Display Controller - Persistent Systems' chest screen for the MPU5 -
has no render of its own. The 3DMA MPU5 asset (Radio_MPU5_v01 at the repo root,
purchased, gitignored; tools/gen_radios.py reads the same files) paints its
front face flat in the base-colour atlas, and that face is the frame (user,
2026-10-30: "look at the mpu5 textures"). This writes it the way
tools/gen_devices.py wants a render: RGB on white, the body as painted, the
screen white inside a black bezel ring. The atlas reuses the screen's black for
other islands' labels (the PTT box's "PTT-A / PTT-B / USB / MPU5" plate sits in
it), so the screen and its recess are repainted, not copied.

THE KEYS COME WITH IT. gen_devices.py finds the six frame keys as bright-rimmed
dark squares; the RDC's are round black buttons with white letters, so this
finds them here - A B X Y on the right are F1-F4, the two joysticks LEFT and
RIGHT - and writes them beside the render for gen_devices.py to take as they
are. The Android keys on the left (back, home, recents, fn) are drawn and
nothing more.

Outputs (art/devices, committed; check_art.py cannot check them - the source
is outside the repo - so re-run this after any change here):
  rdc_src.png    the render, RGB on white
  rdc_src.json   {"keys": [[x, y, w, h], ...]} six keys in rdc_src.png pixels

Run:  python tools/gen_rdc_src.py
"""

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
ATLAS = os.path.join(ROOT, "Radio_MPU5_v01", "Textures", "MPU5_BaseColor.png")
ART = os.path.join(ROOT, "art", "devices")
DEVICE = "rdc"

# The RDC's front face in the 4096 atlas (x0, y0, x1, y1), lying on its side:
# rotated a quarter turn counter-clockwise it stands as the device is held, and
# FACE_RECT then trims the neighbouring islands off its four sides.
ATLAS_RECT = (2600, 1830, 3360, 2990)
ROTATE = 90
# The bottom is the body's own lowest row: the dark island under it is tan to
# the mask too, and what sliver of it is left is thinner than JUNK_R.
FACE_RECT = (14, 10, 1104, 667)
# The face is 1080 px wide trimmed; drawn at this scale it is 1950 on
# gen_devices.py's 2048 canvas, the size the large tablet's render is.
SCALE = 1.8

# The body is the tan paint: red well above blue, and not the atlas's black.
# The shaded tan beside the keys is as dark as 70 red, so the floor stays low.
TAN_RED_OVER_BLUE = 15
TAN_MIN_RED = 55
# Specks and seams of other islands still touching the body after the trim
# are thinner than this (px); the body is hundreds thick. An opening of this
# radius on the filled silhouette drops them and keeps the body.
JUNK_R = 5
# The screen proper is the atlas's black; the recess painted round it is
# brown shading that brightens out from the screen for 25-35 px and then
# levels off at the body's own tone - which is itself darker on the right
# than the lit recess is on the left, so no one brightness tells recess from
# body. A side's depth is where its lines reach this share of the brightest
# within RECESS_MAX; the repaint covers the deepest side's depth on all four,
# so the hole gen_devices.py cuts is straight and square round the screen
# and nothing dark is left outside the ring for its growth to run on through.
SCREEN_DARK = 30
RECESS_RISE = 0.95
RECESS_MAX = 60
# The bezel ring painted round the white screen, px: enough for the generator
# to find, thinner than the rubber it keeps (gen_devices.py RUBBER_OPEN_R).
BEZEL_PX = 8
# THE BUTTONS are found by their white letters: a bright blob of this size
# (px) right of the screen is a letter, its centre the disc's; the disc is as
# tall as the gap between the tan above and below it, and as wide as it is
# tall, because the slot the column sits in is dark too and runs on sideways.
LETTER_BRIGHT = 170
LETTER_PX = (8, 45)
# THE STICKS sit above the button columns: the dark discs an opening of this
# radius leaves above the top button (less this gap, px) - the slot the
# right column sits in runs up into its stick and is as wide as it.
STICK_DARK = 75
STICK_OPEN_R = 20
STICK_GAP = 10
STICK_PX = (60, 140)
# A disc is as wide as it is tall, to this many px.
ROUND_TOL = 12
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)


def tan_mask(arr):
    r, b = arr[:, :, 0].astype(int), arr[:, :, 2].astype(int)
    return (r - b > TAN_RED_OVER_BLUE) & (r > TAN_MIN_RED)


def as_image(mask):
    """A writable L image of the mask: one straight from the array is read
    only, and floodfill on it silently fills nothing."""
    return Image.fromarray(np.where(mask, 255, 0).astype(np.uint8), "L").copy()


def component(mask, seed):
    """The connected part of `mask` holding `seed` (x, y)."""
    img = as_image(mask)
    if img.getpixel(seed) != 255:
        raise SystemExit("seed %s is not in the mask" % (seed,))
    ImageDraw.floodfill(img, seed, 128)
    return np.asarray(img) == 128


def morph(mask, radius, grow):
    img = as_image(mask)
    size = 2 * radius + 1
    img = img.filter(ImageFilter.MaxFilter(size) if grow else ImageFilter.MinFilter(size))
    return np.asarray(img) > 127


def fill_holes(mask):
    """The mask and everything it encloses."""
    h, w = mask.shape
    outside = np.zeros((h + 2, w + 2), bool)
    outside[1:-1, 1:-1] = mask
    img = as_image(outside)
    ImageDraw.floodfill(img, (0, 0), 128)
    reached = np.asarray(img) == 128
    return ~reached[1:-1, 1:-1]


def components(mask):
    """Bounding boxes [x, y, w, h] of every connected part of `mask`."""
    img = as_image(mask)
    boxes = []
    while True:
        left = np.argwhere(np.asarray(img) == 255)
        if not len(left):
            return boxes
        y, x = left[0]
        ImageDraw.floodfill(img, (int(x), int(y)), 128)
        part = np.asarray(img) == 128
        ys, xs = np.where(part)
        boxes.append([int(xs.min()), int(ys.min()), int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1)])
        px = np.asarray(img).copy()
        px[part] = 0
        img = Image.fromarray(px, "L").copy()


def bbox(mask):
    ys, xs = np.where(mask)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def main():
    if not os.path.exists(ATLAS):
        raise SystemExit("%s not in this checkout - the RDC render cannot be made" % ATLAS)
    face = Image.open(ATLAS).convert("RGB").crop(ATLAS_RECT).rotate(ROTATE, expand=True).crop(FACE_RECT)
    arr = np.asarray(face)
    h, w = arr.shape[:2]

    # THE BODY: the tan silhouette with its holes (screen, keys, sticks)
    # filled, opened to drop what else touches it, picked by a point of the
    # bezel left of centre.
    tan = tan_mask(arr)
    solid = fill_holes(tan)
    opened = morph(morph(solid, JUNK_R, False), JUNK_R, True)
    body = fill_holes(component(opened, (int(w * 0.13), h // 2)))

    lum = arr.mean(axis=2)
    # THE SCREEN: the black under the body's centre, whatever the atlas left
    # inside it, plus the recess round it: the deepest side's depth on all
    # four (a line's ends are trimmed, where the corners shade).
    lx0, ly0, lx1, ly1 = bbox(component((lum < SCREEN_DARK) & body, (w // 2, h // 2)))

    def depth(lines):
        means = [float(line.mean()) for _, line in zip(range(RECESS_MAX), lines)]
        level = max(means) * RECESS_RISE
        return next(i for i, m in enumerate(means) if m >= level)

    tx, ty = (lx1 - lx0) // 10, (ly1 - ly0) // 10
    recess = max(
        depth(lum[ly0 + ty:ly1 - ty, x] for x in range(lx0 - 1, -1, -1)),
        depth(lum[ly0 + ty:ly1 - ty, x] for x in range(lx1 + 1, w)),
        depth(lum[y, lx0 + tx:lx1 - tx] for y in range(ly0 - 1, -1, -1)),
        depth(lum[y, lx0 + tx:lx1 - tx] for y in range(ly1 + 1, h)),
    )
    sx0, sy0, sx1, sy1 = lx0 - recess, ly0 - recess, lx1 + recess, ly1 + recess

    out = np.full_like(arr, 255)
    out[body] = arr[body]
    img = Image.fromarray(out, "RGB")
    draw = ImageDraw.Draw(img)
    draw.rectangle([sx0, sy0, sx1, sy1], fill=WHITE)
    for i in range(BEZEL_PX):
        draw.rectangle([sx0 + i, sy0 + i, sx1 - i, sy1 - i], outline=BLACK)

    # THE KEYS. Buttons right of the screen, top to bottom, are A B X Y.
    off_screen = body.copy()
    off_screen[sy0:sy1 + 1, sx0:sx1 + 1] = False
    bright = (lum > LETTER_BRIGHT) & off_screen
    letters = [b for b in components(bright)
               if b[0] > sx1 and LETTER_PX[0] <= b[2] <= LETTER_PX[1] and LETTER_PX[0] <= b[3] <= LETTER_PX[1]]
    buttons = []
    for b in sorted(letters, key=lambda k: k[1]):
        cx, cy = b[0] + b[2] // 2, b[1] + b[3] // 2
        top = cy
        while top > 0 and not tan[top - 1, cx]:
            top -= 1
        bottom = cy
        while bottom < h - 1 and not tan[bottom + 1, cx]:
            bottom += 1
        size = bottom - top + 1
        buttons.append([cx - size // 2, top, size, size])
    # The two sticks, left then right.
    above = off_screen.copy()
    if buttons:
        above[buttons[0][1] - STICK_GAP:, :] = False
    stick_mask = morph(morph((lum < STICK_DARK) & above, STICK_OPEN_R, False), STICK_OPEN_R, True)
    # What is left of the slot under the right stick still hangs off it, so
    # a stick is the square at the top of its blob, as wide as the blob.
    sticks = []
    for b in sorted(components(stick_mask), key=lambda k: k[0]):
        if STICK_PX[0] <= b[2] <= STICK_PX[1] and b[3] >= b[2] - ROUND_TOL:
            sticks.append([b[0], b[1], b[2], b[2]])
    if len(buttons) != 4 or len(sticks) != 2:
        raise SystemExit("found %d lettered buttons right of the screen and %d sticks; want 4 and 2 (%s / %s)" % (
            len(buttons), len(sticks), letters, components(stick_mask)))
    keys = buttons + sticks

    big = img.resize((int(round(w * SCALE)), int(round(h * SCALE))), Image.LANCZOS)
    os.makedirs(ART, exist_ok=True)
    big.save(os.path.join(ART, DEVICE + "_src.png"), optimize=False)
    with open(os.path.join(ART, DEVICE + "_src.json"), "w", encoding="utf-8") as f:
        json.dump({"keys": [[int(round(v * SCALE)) for v in k] for k in keys]}, f)
        f.write("\n")
    print("%s_src.png %dx%d  screen %s (recess %d)  keys %s" % (DEVICE, big.size[0], big.size[1], (sx0, sy0, sx1, sy1), recess, keys))
    return 0


if __name__ == "__main__":
    sys.exit(main())
