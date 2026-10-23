#!/usr/bin/env python3
"""Device frame textures for the jmfsb device shells.

The renders arrive as RGB on white at whatever size the renderer gave them
(`<id>_src.png`). Arma wants power-of-two textures, so each becomes a 2048x2048
RGBA canvas at NATIVE resolution - nothing is scaled, the frame is only centred
and the surplus white cropped or padded. The white outside the frame and the
white inside the screen are cut to transparent by flood fill from the canvas
edges and from the screen centre, so the frame can sit over the world and the
apps can draw through the screen.

THE SCREEN RECTANGLE IS MEASURED, NOT TYPED. Every frame has a black bezel
ring around a white screen; walking out from the screen centre to the first dark
pixel on each axis gives the inner edge of that ring. The spec JSON carried
rects typed from earlier renders and two of them were wrong.

Outputs, beside this file:
  <id>_frame.png   the texture source (committed; check_art.py compares it)
  devices.json     per device: canvas, frame bbox, screen rect in px and in
                   canvas fractions [x, y, w, h] - what the shell reads
And, when the addon folder exists and hemtt is on PATH:
  addons/devices/data/<id>.paa
  addons/devices/frames.hpp   the same rects as config, for config.cpp

Run:  python tools/gen_devices.py [--preview DIR]
      --preview writes a 512px composite of each frame over grey into DIR for
      a visual check; never into this folder.
"""

import argparse
import json
import math
import os
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ADDON = os.path.normpath(os.path.join(HERE, "..", "addons", "devices"))
# The renders, the generated frames and devices.json live with the rest of the
# unit's art, never in tools/ (user, 2026-10-19).
ART = os.path.normpath(os.path.join(HERE, "..", "art", "devices"))

CANVAS = 2048
# uav: the large tablet with hand grips, for players with the UAV trait. Its
# source is the grips render flattened onto white (from large_grips_transparent.png).
DEVICES = ["large", "vehicle", "phone", "side", "side2", "uav"]

# SCREEN ASPECT, width over height, where the render's is not the device's.
# The large tablet was shot at 1.36:1 and the spec's screen is 16:10; it is
# WIDENED, NOT STRETCHED: the column through the screen's centre - bezel,
# screen, bezel, all straight-edged there - is repeated until the screen is
# the right shape, so every bevel, button and corner keeps its drawing.
ASPECT = {"large": 16 / 10}

# Anything brighter than this on every channel is "background white". The
# renders are clean studio white; antialiased frame edges fall below it.
WHITE = 235
# A bezel pixel. The ring is near-black; the olive body is well above this.
DARK = 60
# Bezel band: a hole edge is grown while more than BEZEL_CLEAR of its line is
# dark, ignoring BEZEL_TRIM of the line at each end (corner shading).
BEZEL_CLEAR = 0.01
BEZEL_TRIM = 0.05
# Sentinel the flood fill paints the cut regions with; no frame pixel is it.
SENTINEL = (255, 0, 255)
# Marks a white region the pocket pass measured and kept as artwork.
KEEP = (4, 5, 6)
# THE RUBBER STAYS OVER THE CORNERS (user, 2026-10-22 and 23, red circles round
# the bumpers, the fifth day of "the corners"). On every render the corner
# guards' inner lobes are drawn right over the bezel band at the hole's left
# corners, so a square cut took a bite out of each lobe and left the screen's
# corner hard against a notched bumper; an olive band painted in to part them
# (the 2026-10-22 try) read as a seam. A real corner guard wraps over the
# glass. The rubber - anything darker than RUBBER that is at least
# 2 x RUBBER_OPEN_R thick (the bezel band is dark too, but thinner, and the
# opening drops it) - is never cut, so each lobe keeps its shape and sits over
# the screen's corner; the frame is drawn above the screen (the Frame control
# comes last in overlay.hpp and dialog.hpp) and the devices' content insets
# keep text clear of the lobes.
RUBBER = 90
RUBBER_OPEN_R = 12
# THE HOLE'S CORNERS ARE SLIGHTLY ROUND (user, 2026-10-23: "on all devices on
# the outside dark border add a slight roundness to the corners"). The square
# cut is a rounded rectangle of this radius, so the render's own dark bezel
# pixels stay in each corner as a small fillet over the screen's sharp corner
# - the band itself is still cut away along the edges.
SCREEN_CORNER_R = 14
# --preview also writes <device>_corners.png: the four corners of the frame
# over a dark screen, at this many canvas px a side, scaled up.
PREVIEW_CORNER_PX = 160
# Edge un-mixing (cut_alpha): how many pixels in from the cut are treated as
# device blended with the white, and the least room below white a channel of
# the device's colour needs to measure coverage by.
EDGE_BAND = 3
EDGE_MIN_ROOM = 8
# Pocket pass: grid step for seeds, and the smallest white region cut.
POCKET_GRID = 8
POCKET_MIN = 3000


def load(device):
    path = os.path.join(ART, device + "_src.png")
    if not os.path.exists(path):
        raise SystemExit("%s missing - the render as supplied, RGB on white" % path)
    return Image.open(path).convert("RGB")


def frame_bbox(arr):
    """Bounding box of everything that is not background white."""
    lum = arr.min(axis=2)
    ys, xs = np.where(lum < WHITE)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def screen_rect(arr):
    """Inner edge of the bezel ring, walking out from the image centre."""
    lum = arr.mean(axis=2)
    dark = lum < DARK
    h, w = dark.shape
    cy, cx = h // 2, w // 2
    row, col = dark[cy], dark[:, cx]
    l = cx
    while l > 0 and not row[l]:
        l -= 1
    r = cx
    while r < w - 1 and not row[r]:
        r += 1
    t = cy
    while t > 0 and not col[t]:
        t -= 1
    b = cy
    while b < h - 1 and not col[b]:
        b += 1
    if not (row[l] and row[r] and col[t] and col[b]):
        raise SystemExit("no bezel ring found around the image centre")
    return l + 1, t + 1, r - 1, b - 1


def through_bezel(arr, rect):
    """Grow the screen rectangle out through the black bezel band to the
    frame's straight inner edge, plus the one antialiased pixel at that edge.

    THE HOLE IS THE INSIDE OF THE FRAME, NOT THE INSIDE OF THE BEZEL (user,
    2026-10-20, fifth time asked). Every render has a 10-20 px near-black band
    between the olive frame and the white screen, and that band follows the
    frame's rounded inner corners. Cutting the hole at the band's inner edge
    left the band showing as a dark gap round the map and the rounded corners
    crowding the map's square ones. Cut out to the frame's edge, the band is
    gone and the hole's square cut takes the rounded corners with it, so the
    map meets straight frame on four sides with square corners."""
    lum = arr.mean(axis=2)
    h, w = lum.shape
    l, t, r, b = rect

    # AN EDGE IS CLEAR when almost none of the line along it is band. The band
    # is not ruled straight in the renders - it drifts a pixel along a long
    # edge - so a walk along the centre line alone left a dark row at the ends.
    # The outer BEZEL_TRIM of each line is ignored: that is where the frame's
    # own corner shading starts, and it is cut away by the square hole anyway.
    def dark_share(line):
        n = len(line)
        k = int(n * BEZEL_TRIM)
        core = line[k:n - k]
        return float((core < DARK).sum()) / max(1, len(core))

    grow = True
    while grow:
        grow = False
        if l > 0 and dark_share(lum[t:b + 1, l - 1]) > BEZEL_CLEAR:
            l -= 1
            grow = True
        if r < w - 1 and dark_share(lum[t:b + 1, r + 1]) > BEZEL_CLEAR:
            r += 1
            grow = True
        if t > 0 and dark_share(lum[t - 1, l:r + 1]) > BEZEL_CLEAR:
            t -= 1
            grow = True
        if b < h - 1 and dark_share(lum[b + 1, l:r + 1]) > BEZEL_CLEAR:
            b += 1
            grow = True
    # The antialiased pixel where the band meets the frame.
    return max(0, l - 1), max(0, t - 1), min(w - 1, r + 1), min(h - 1, b + 1)


def widen(src, aspect):
    """Repeat the screen's centre column until the screen is `aspect` wide."""
    arr = np.asarray(src)
    x0, y0, x1, y1 = screen_rect(arr)
    w, h = x1 - x0 + 1, y1 - y0 + 1
    extra = int(round(h * aspect)) - w
    if extra <= 0:
        return src
    cx = (x0 + x1) // 2
    col = arr[:, cx:cx + 1, :]
    out = np.concatenate([arr[:, :cx, :], np.repeat(col, extra, axis=1), arr[:, cx:, :]], axis=1)
    print("  widened by %d columns to %d:%d" % (extra, w + extra, h))
    return Image.fromarray(out, "RGB")


def centre_on_canvas(src):
    """Paste the source so its frame is centred on a CANVAS square. Negative
    offsets crop surplus white; positive ones pad with white. A frame wider
    than the canvas is scaled down UNIFORMLY to fit - the one resize there is,
    and it keeps every proportion."""
    arr = np.asarray(src)
    bx0, by0, bx1, by1 = frame_bbox(arr)
    bw, bh = bx1 - bx0 + 1, by1 - by0 + 1
    if bw > CANVAS or bh > CANVAS:
        k = min(CANVAS / bw, CANVAS / bh)
        src = src.resize((int(round(src.size[0] * k)), int(round(src.size[1] * k))), Image.LANCZOS)
        arr = np.asarray(src)
        bx0, by0, bx1, by1 = frame_bbox(arr)
        bw, bh = bx1 - bx0 + 1, by1 - by0 + 1
        print("  scaled by %.4f to fit the canvas" % k)
    # A source already the canvas size is left exactly where it is: the vehicle
    # cradle fills its render edge to edge and a one-pixel nudge gains nothing.
    if src.size == (CANVAS, CANVAS):
        ox = oy = 0
    else:
        ox = (CANVAS - bw) // 2 - bx0
        oy = (CANVAS - bh) // 2 - by0
    canvas = Image.new("RGB", (CANVAS, CANVAS), (255, 255, 255))
    canvas.paste(src, (ox, oy))
    return canvas, (ox, oy), (bx0 + ox, by0 + oy, bx1 + ox, by1 + oy)


def cut_alpha(canvas, rect):
    """Flood the background and the screen interior with the sentinel, turn
    those pixels transparent, and feather the one-pixel ring around the cut so
    antialiased edges do not carry a white fringe."""
    work = canvas.copy()
    w, h = work.size
    px = work.load()
    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
             (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]
    for s in seeds:
        if min(px[s]) >= WHITE:
            ImageDraw.floodfill(work, s, SENTINEL, thresh=255 - WHITE)
    x0, y0, x1, y1 = rect
    ImageDraw.floodfill(work, ((x0 + x1) // 2, (y0 + y1) // 2), SENTINEL, thresh=255 - WHITE)

    # ENCLOSED POCKETS (user, 2026-10-19: white left between the vehicle
    # frame's cable, bracket and tablet). Background white walled in by the
    # device - inside a cable loop, a handle, a mounting slot - touches no
    # canvas edge, so the seeds above never reach it. Every near-white region
    # larger than POCKET_MIN pixels is cut too; anything smaller is artwork
    # (key legends, highlights) and is left alone.
    probe = (1, 2, 3)
    for gy in range(0, h, POCKET_GRID):
        for gx in range(0, w, POCKET_GRID):
            if min(px[gx, gy]) < WHITE or px[gx, gy] in (SENTINEL, KEEP):
                continue
            ImageDraw.floodfill(work, (gx, gy), probe, thresh=255 - WHITE)
            region = np.all(np.asarray(work) == np.array(probe, dtype=np.uint8), axis=2)
            fill = SENTINEL if region.sum() >= POCKET_MIN else KEEP
            ImageDraw.floodfill(work, (gx, gy), fill, thresh=0)
            px = work.load()

    arr = np.asarray(work)
    cut = np.all(arr == np.array(SENTINEL, dtype=np.uint8), axis=2)
    # THE SCREEN HOLE IS SQUARE (user, 2026-10-19: "make them square and not
    # rounded, then we do not have to work on corners"). The flood above
    # follows the render's rounded screen corners; the map behind is a
    # rectangle, so its corners showed past them. The whole measured screen
    # rectangle is cut, corners included, and the hole is exactly the map -
    # except through the rubber (RUBBER_OPEN_R above): a corner guard's lobe
    # that reaches into the rectangle keeps its pixels and lies over the map;
    # and except the corners' own fillets (SCREEN_CORNER_R).
    rounded = Image.new("L", (w, h), 0)
    ImageDraw.Draw(rounded).rounded_rectangle([x0, y0, x1, y1], radius=SCREEN_CORNER_R, fill=255)
    square = np.asarray(rounded) > 127
    cut |= square & ~rubber_mask(canvas)
    alpha = np.where(cut, 0, 255).astype(np.uint8)

    # NO LIGHT EDGE (user, 2026-10-21: the tablet's corners, a pale outline
    # round every bumper). The renders' edge pixels are the device blended
    # with the studio white - a bumper's last pixels sampled 224 and 129 grey
    # against its own 70 - and kept as they were they drew a light line round
    # the whole silhouette over the dark world. Each pixel within EDGE_BAND of
    # the cut is un-mixed from the white it was rendered on: its true colour is
    # carried out from the device just inside it, and its alpha is how far it
    # sits from white towards that colour.
    rgb = np.asarray(canvas).astype(np.float32)
    band = np.zeros_like(cut)
    grown = cut.copy()
    for _ in range(EDGE_BAND):
        grown = _grow(grown)
    band = grown & ~cut
    known = ~cut & ~band
    fg = np.where(known[..., None], rgb, 0.0)
    while (band & ~known).any():
        total = np.zeros_like(rgb)
        count = np.zeros(cut.shape, np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            k = np.roll(known, (dy, dx), axis=(0, 1))
            total += np.where(k[..., None], np.roll(fg, (dy, dx), axis=(0, 1)), 0.0)
            count += k
        new = band & ~known & (count > 0)
        if not new.any():
            break
        fg = np.where(new[..., None], total / np.maximum(count, 1)[..., None], fg)
        known |= new
    room = 255.0 - fg
    share = np.where(room > EDGE_MIN_ROOM, (255.0 - rgb) / np.maximum(room, 1.0), 0.0).max(axis=2)
    # A colour with no room below white (a white legend) is opaque as it is.
    share = np.where((room > EDGE_MIN_ROOM).any(axis=2), share, 1.0)
    edge_alpha = np.clip(share * 255.0, 0, 255).astype(np.uint8)
    alpha = np.where(band, edge_alpha, alpha)
    out_rgb = np.where(band[..., None], np.clip(fg, 0, 255), rgb).astype(np.uint8)

    return Image.fromarray(np.dstack([out_rgb, alpha]), "RGBA")


def rubber_mask(canvas):
    """The rubber - bumpers, grips, the key panel - as a mask: every pixel
    darker than RUBBER that belongs to something at least 2 x RUBBER_OPEN_R
    thick. An opening (erode, then dilate, a square of that radius) keeps the
    thick lobes and drops the thin bezel band."""
    lum = np.asarray(canvas).mean(axis=2)
    dark = Image.fromarray(np.where(lum < RUBBER, 255, 0).astype(np.uint8), "L")
    size = 2 * RUBBER_OPEN_R + 1
    opened = dark.filter(ImageFilter.MinFilter(size)).filter(ImageFilter.MaxFilter(size))
    return np.asarray(opened) > 127


def _grow(mask):
    """The mask and every pixel touching it."""
    out = mask.copy()
    out[1:, :] |= mask[:-1, :]
    out[:-1, :] |= mask[1:, :]
    out[:, 1:] |= mask[:, :-1]
    out[:, :-1] |= mask[:, 1:]
    return out


def to_paa(png, paa):
    hemtt = shutil.which("hemtt")
    if not hemtt:
        print("  hemtt not on PATH - %s not written" % os.path.relpath(paa))
        return
    # hemtt REFUSES TO OVERWRITE, and says so with exit code 0 - so a rerun
    # after a render change silently kept the old file. The target goes first.
    if os.path.exists(paa):
        os.remove(paa)
    subprocess.run([hemtt, "utils", "paa", "convert", png, paa], check=True,
                   capture_output=True)
    if not os.path.exists(paa):
        raise SystemExit("hemtt did not write %s" % paa)
    print("  wrote %s" % os.path.relpath(paa))


# THE KEYS PRINTED ON THE FRAME (user, 2026-10-19: "F1-F4 needs to be a setting
# for the tablet only, not the keyboard F1-F4"). Every frame prints six keys -
# F1, F2, F3, F4, LEFT, RIGHT - in one evenly spaced line, to the right of the
# screen or below it. Each key is a dark square with a light rim, so the rims
# are found as bands of bright pixels along the strip; artwork that strays into
# the strip (grips, cables) is dropped by keeping only bands that are square and
# key-sized, after narrowing the strip to the key column. Six keys or nothing:
# a frame whose keys cannot all be found gets none rather than wrong ones.
KEY_BRIGHT = 175        # rim luminance
KEY_STRIP = 260         # px searched beyond the screen edge
KEY_GAP = 6             # px gap that still joins one band
KEY_MIN = 12            # px; shorter bands are text or noise
KEY_SQUARE = 8          # px tolerance between a key's width and height
KEY_SIZE_TOL = 0.2      # fraction a key may differ from the median key


def _runs(v):
    out, s0, last = [], None, None
    for i, on in enumerate(v > 0):
        if on:
            if s0 is None:
                s0 = i
            last = i
        elif s0 is not None and i - last > KEY_GAP:
            out.append((s0, last))
            s0 = None
    if s0 is not None:
        out.append((s0, last))
    return out


def _bands(sub, along_rows):
    out = []
    for b0, b1 in _runs(sub.sum(axis=1) if along_rows else sub.sum(axis=0)):
        if b1 - b0 < KEY_MIN:
            continue
        if along_rows:
            cs = np.nonzero(sub[b0:b1 + 1].sum(axis=0))[0]
            out.append((int(cs.min()), b0, int(cs.max() - cs.min() + 1), b1 - b0 + 1))
        else:
            rs = np.nonzero(sub[:, b0:b1 + 1].sum(axis=1))[0]
            out.append((b0, int(rs.min()), b1 - b0 + 1, int(rs.max() - rs.min() + 1)))
    return out


def find_keys(rgba, rect, fbox):
    """[[x, y, w, h] px] x 6 in key order, or [] when not all six are found."""
    a = np.asarray(rgba).astype(int)
    bright = (a[:, :, :3].mean(axis=2) > KEY_BRIGHT) & (a[:, :, 3] == 255)
    x0, y0, x1, y1 = rect
    fx0, fy0, fx1, fy1 = fbox
    strips = {
        "right": (x1 + 5, y0, min(fx1, x1 + KEY_STRIP), y1),
        "below": (x0, y1 + 5, x1, min(fy1, y1 + KEY_STRIP)),
    }
    side = max(strips, key=lambda k: bright[strips[k][1]:strips[k][3], strips[k][0]:strips[k][2]].sum())
    sx0, sy0, sx1, sy1 = strips[side]
    rows = side == "right"
    square = [b for b in _bands(bright[sy0:sy1, sx0:sx1], rows) if abs(b[2] - b[3]) <= KEY_SQUARE]
    if not square:
        return []
    size = int(np.median([min(b[2], b[3]) for b in square]))
    reach = int(size * 1.15)
    if rows:
        cx = sx0 + min(b[0] for b in square)
        got = [(cx - 2 + b[0], sy0 + b[1], b[2], b[3]) for b in _bands(bright[sy0:sy1, cx - 2:cx + reach], rows)]
    else:
        cy = sy0 + min(b[1] for b in square)
        got = [(sx0 + b[0], cy - 2 + b[1], b[2], b[3]) for b in _bands(bright[cy - 2:cy + reach, sx0:sx1], rows)]
    keys = [list(b) for b in got
            if abs(b[2] - b[3]) <= KEY_SQUARE and abs(min(b[2], b[3]) - size) <= KEY_SIZE_TOL * size]
    keys.sort(key=lambda k: k[1] if rows else k[0])
    return keys if len(keys) == 6 else []


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview", help="folder for 512px composites, for eyes only")
    args = ap.parse_args()

    report = {}
    for device in DEVICES:
        src = load(device)
        if device in ASPECT:
            src = widen(src, ASPECT[device])
        canvas, offset, fbox = centre_on_canvas(src)
        rect = through_bezel(np.asarray(canvas), screen_rect(np.asarray(canvas)))
        out = cut_alpha(canvas, rect)
        out_path = os.path.join(ART, device + "_frame.png")
        out.save(out_path, optimize=False)
        x0, y0, x1, y1 = rect
        w, h = x1 - x0 + 1, y1 - y0 + 1
        fx0, fy0, fx1, fy1 = fbox
        fw, fh = fx1 - fx0 + 1, fy1 - fy0 + 1
        report[device] = {
            "source": [src.size[0], src.size[1]],
            "offset": list(offset),
            "canvas": [CANVAS, CANVAS],
            "frame_px": list(fbox),
            # The device itself, inside the transparent padding - what the
            # shell fits to the screen. Same units as screen_frac.
            "frame_frac": [round(fx0 / CANVAS, 6), round(fy0 / CANVAS, 6),
                           round(fw / CANVAS, 6), round(fh / CANVAS, 6)],
            "screen_px": [x0, y0, x1, y1],
            "screen_size": [w, h],
            "screen_frac": [round(x0 / CANVAS, 6), round(y0 / CANVAS, 6),
                            round(w / CANVAS, 6), round(h / CANVAS, 6)],
        }
        keys = find_keys(out, rect, fbox)
        report[device]["keys_px"] = keys
        report[device]["keys_frac"] = [[round(v / CANVAS, 6) for v in k] for k in keys]
        print("%-8s src %dx%d  offset %s  screen %s (%dx%d)  keys %d" % (
            device, src.size[0], src.size[1], offset, rect, w, h, len(keys)))
        if args.preview:
            os.makedirs(args.preview, exist_ok=True)
            grey = Image.new("RGBA", out.size, (96, 96, 96, 255))
            grey.alpha_composite(out)
            grey.convert("RGB").resize((512, 512), Image.LANCZOS).save(
                os.path.join(args.preview, device + "_preview.png"))
            # The four corners over a dark screen, as the device shows them.
            screen = Image.new("RGBA", (w, h), (43, 47, 40, 255))
            world = Image.new("RGBA", out.size, (120, 90, 60, 255))
            world.alpha_composite(screen, (x0, y0))
            world.alpha_composite(out)
            half = PREVIEW_CORNER_PX // 2
            sheet = Image.new("RGB", (PREVIEW_CORNER_PX * 4, PREVIEW_CORNER_PX))
            for i, (cx, cy) in enumerate(((x0, y0), (x1, y0), (x0, y1), (x1, y1))):
                sheet.paste(world.crop((cx - half, cy - half, cx + half, cy + half)).convert("RGB"), (i * PREVIEW_CORNER_PX, 0))
            sheet.resize((sheet.width * 2, sheet.height * 2), Image.LANCZOS).save(
                os.path.join(args.preview, device + "_corners.png"))

    with open(os.path.join(ART, "devices.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
        f.write("\n")

    if os.path.isdir(ADDON):
        data = os.path.join(ADDON, "data")
        os.makedirs(data, exist_ok=True)
        for device in DEVICES:
            to_paa(os.path.join(ART, device + "_frame.png"),
                   os.path.join(data, device + ".paa"))
        lines = ["// GENERATED by tools/gen_devices.py - do not edit.",
                 "// Per frame texture, as fractions of its 2048x2048 canvas, x y w h:",
                 "//   body[]   the device itself inside the transparent padding - what",
                 "//            the shell fits to the screen",
                 "//   screen[] the screen hole: the frame's inner edge, bezel band included",
                 "//   corner   the hole's corner radius (SCREEN_CORNER_R), the same fraction",
                 "//   keys[]   the six keys printed on the frame - F1 F2 F3 F4 LEFT RIGHT -",
                 "//            found in the render; empty when they could not all be found",
                 ""]
        for device in DEVICES:
            body = report[device]["frame_frac"]
            fr = report[device]["screen_frac"]
            lines.append("class %s {" % device)
            lines.append("    frame = QPATHTOF(data\\%s.paa);" % device)
            lines.append("    body[] = {%s};" % ", ".join("%.6f" % v for v in body))
            lines.append("    screen[] = {%s};" % ", ".join("%.6f" % v for v in fr))
            lines.append("    corner = %.6f;" % (SCREEN_CORNER_R / CANVAS))
            lines.append("    keys[] = {%s};" % ", ".join(
                "{%s}" % ", ".join("%.6f" % v for v in k) for k in report[device]["keys_frac"]))
            lines.append("};")
        with open(os.path.join(ADDON, "frames.hpp"), "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        print("  wrote %s" % os.path.relpath(os.path.join(ADDON, "frames.hpp")))
    else:
        print("  %s not present - no .paa or frames.hpp written" % os.path.relpath(ADDON))
    return 0


CORNER_PX = 64
CORNERS = {"tl": (1, 1), "tr": (0, 1), "bl": (1, 0), "br": (0, 0)}


def corner_textures():
    """The tablet's recess band is drawn in game above the frame, so its
    corners would cover the hole's fillets; its four corner pieces are these
    quarter-rounds instead - white (tinted in game), opaque inside the arc,
    clear outside it where the frame's fillet shows. The arc is centred on the
    piece's inner corner (CORNERS: which corner of the square is inner, as a
    fraction of its side), radius the side."""
    for name, (cx, cy) in CORNERS.items():
        a = np.zeros((CORNER_PX, CORNER_PX), np.float32)
        ox, oy = cx * CORNER_PX, cy * CORNER_PX
        for y in range(CORNER_PX):
            for x in range(CORNER_PX):
                d = math.hypot(x + 0.5 - ox, y + 0.5 - oy)
                a[y, x] = min(1.0, max(0.0, CORNER_PX - d + 0.5))
        rgba = np.dstack([np.full((CORNER_PX, CORNER_PX, 3), 255, np.uint8), (a * 255).astype(np.uint8)])
        png = os.path.join(ART, "corner_%s.png" % name)
        Image.fromarray(rgba, "RGBA").save(png)
        if os.path.isdir(ADDON):
            to_paa(png, os.path.join(ADDON, "data", "corner_%s_ca.paa" % name))


if __name__ == "__main__":
    code = main()
    corner_textures()
    sys.exit(code)
