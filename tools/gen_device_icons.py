#!/usr/bin/env python3
"""Arsenal pictures for the walking-view devices (phone, side, side2).

The items used their frame textures as the picture, and a frame's screen is a
transparent hole - so in the arsenal each read as a dark empty rectangle (user,
2026-10-21: "fill in the screen with anything to make them easier to see").

Each picture is the device's own frame (art/devices/<id>_frame.png, from
tools/gen_devices.py) over a lit screen drawn into its measured screen rect
(devices.json): the walking view's map ground with grid lines, a road, the
range rings and the player at the centre, and the net row along the bottom
edge. The result is cropped to the device body, centred on a square and
scaled to ICON px.

Outputs:
  art/devices/<id>_icon.png              the source (committed)
  addons/devices/data/<id>_icon_ca.paa   when hemtt is on PATH

Run:  python tools/gen_device_icons.py   (after tools/gen_devices.py)
"""

import json
import os
import shutil
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.normpath(os.path.join(HERE, "..", "art", "devices"))
DATA = os.path.normpath(os.path.join(HERE, "..", "addons", "devices", "data"))

DEVICES = ["phone", "side", "side2"]
ICON = 256

# The walking view's own colours (docs/DESIGN_PHONE_WALKING.md, "Colours").
MAP_GROUND = (217, 215, 207, 255)
GRID = (178, 176, 168, 255)
ROAD = (232, 211, 174, 255)
ROAD_EDGE = (201, 173, 127, 255)
RING = (90, 90, 82, 255)
BAR = (32, 30, 29, 255)
CHIP_OK = (67, 160, 71, 255)
CHIP_FILL = (243, 242, 242, 255)
PLAYER = (194, 168, 120, 255)

# Proportions of the screen rect: grid spacing, ring radii (of the shorter
# side), the net row's height, and line widths (of the shorter side).
GRID_STEP = 0.16
RING_INNER = 0.18
RING_OUTER = 0.36
NET_ROW = 0.11
LINE = 0.006
ROAD_W = 0.07
PLAYER_R = 0.035


def screen(size):
    """The lit screen at the screen rect's own size."""
    w, h = size
    s = min(w, h)
    img = Image.new("RGBA", size, MAP_GROUND)
    d = ImageDraw.Draw(img)
    line = max(1, round(s * LINE))
    step = round(s * GRID_STEP)
    for x in range(step, w, step):
        d.line([(x, 0), (x, h)], fill=GRID, width=line)
    for y in range(step, h, step):
        d.line([(0, y), (w, y)], fill=GRID, width=line)
    # A road across the screen, low left to high right.
    road = [(0, round(h * 0.78)), (round(w * 0.45), round(h * 0.55)), (w, round(h * 0.25))]
    d.line(road, fill=ROAD_EDGE, width=round(s * ROAD_W) + 2 * line, joint="curve")
    d.line(road, fill=ROAD, width=round(s * ROAD_W), joint="curve")
    net_h = round(h * NET_ROW) if h <= w else round(w * NET_ROW * 2)
    cx, cy = w // 2, (h - net_h) // 2
    for r in (RING_INNER, RING_OUTER):
        rr = round(s * r)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=RING, width=line * 2)
    pr = round(s * PLAYER_R)
    d.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=PLAYER, outline=BAR, width=line * 2)
    # The net row: a dark bar with one active chip, green-edged.
    d.rectangle([0, h - net_h, w, h], fill=BAR)
    pad = max(2, net_h // 6)
    d.rectangle([pad, h - net_h + pad, round(w * 0.42), h - pad], fill=CHIP_FILL, outline=CHIP_OK, width=line * 2)
    return img


def icon(device, rects):
    frame = Image.open(os.path.join(ART, device + "_frame.png")).convert("RGBA")
    x0, y0, x1, y1 = rects[device]["screen_px"]
    fx0, fy0, fx1, fy1 = rects[device]["frame_px"]
    canvas = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    canvas.paste(screen((x1 - x0 + 1, y1 - y0 + 1)), (x0, y0))
    canvas.alpha_composite(frame)
    body = canvas.crop((fx0, fy0, fx1 + 1, fy1 + 1))
    side = max(body.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(body, ((side - body.size[0]) // 2, (side - body.size[1]) // 2))
    return square.resize((ICON, ICON), Image.LANCZOS)


def to_paa(png, paa):
    hemtt = shutil.which("hemtt")
    if not hemtt:
        print("  hemtt not on PATH - %s not written" % os.path.relpath(paa))
        return
    # hemtt refuses to overwrite and still exits 0, so the target goes first.
    if os.path.exists(paa):
        os.remove(paa)
    subprocess.run([hemtt, "utils", "paa", "convert", png, paa], check=True,
                   stdout=subprocess.DEVNULL)
    if not os.path.exists(paa):
        raise SystemExit("hemtt did not write %s" % paa)
    print("  wrote %s" % os.path.relpath(paa))


def main():
    with open(os.path.join(ART, "devices.json"), encoding="utf-8") as f:
        rects = json.load(f)
    for device in DEVICES:
        out = os.path.join(ART, device + "_icon.png")
        icon(device, rects).save(out, optimize=False)
        print("  wrote %s" % os.path.relpath(out))
        if os.path.isdir(DATA):
            to_paa(out, os.path.join(DATA, device + "_icon_ca.paa"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
