#!/usr/bin/env python3
"""Labelled device diagrams - the phone, a side device, the tablet - for the
game-voice boards (tools/gen_signs.py, the "devices" kind; user, 2026-10-22:
"include drawings" in the signs) and the voice guide. The real frame art
(art/devices/<id>_frame.png, screen rects from devices.json) with the screen
drawn the way addons/devices lays it out, and numbered callouts the boards'
keys refer to.

Outputs art/signs/diag_phone.png, diag_side.png, diag_tablet.png (sources,
never shipped; the boards are rendered from them).

Run:  python tools/gen_device_diagrams.py   (then tools/gen_signs.py)
"""
import json
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.normpath(os.path.join(HERE, "..", "art", "devices"))
OUT = os.path.normpath(os.path.join(HERE, "..", "art", "signs"))
DEV = json.load(open(os.path.join(ART, "devices.json")))

GROUND = (236, 231, 218, 255)
INK = (32, 38, 28, 255)
MUTED = (120, 124, 110, 255)
MAPG = (217, 215, 207, 255)
GRID = (178, 176, 168, 255)
ROAD = (232, 211, 174, 255)
WATER = (186, 203, 214, 255)
GREEN = (61, 122, 58, 255)
AMBER = (168, 112, 15, 255)
TX = (179, 38, 30, 255)
TAN = (194, 168, 120, 255)
RECESS = (38, 39, 40, 255)
DIM = (150, 150, 140, 255)
WHITE = (255, 255, 255, 255)
OUT_W = 1500
# Callout markers, sized for a board that shows the diagram at half size.
MARKER_R = 26
MARKER_FONT = 30


def font(size, bold=True):
    return ImageFont.truetype("arialbd.ttf" if bold else "arial.ttf", max(8, int(size)))


def text(d, box, s, fill, size, align="left", bold=True, pad=6):
    x, y, w, h = box
    f = font(size, bold)
    l, t, r, b = f.getbbox(s)
    tw, th = r - l, b - t
    tx = {"left": x + pad, "center": x + (w - tw) / 2, "right": x + w - tw - pad}[align] - l
    d.text((tx, y + (h - th) / 2 - t), s, font=f, fill=fill)


def map_art(d, x, y, w, h, water=True):
    d.rectangle([x, y, x + w, y + h], fill=MAPG)
    if water:
        d.polygon([(x + w * 0.62, y), (x + w, y), (x + w, y + h), (x + w * 0.5, y + h), (x + w * 0.7, y + h * 0.5)], fill=WATER)
    step = max(40, int(min(w, h) / 5))
    for gx in range(int(x), int(x + w), step):
        d.line([(gx, y), (gx, y + h)], fill=GRID, width=2)
    for gy in range(int(y), int(y + h), step):
        d.line([(x, gy), (x + w, gy)], fill=GRID, width=2)
    d.line([(x, y + h * 0.7), (x + w * 0.3, y + h * 0.55), (x + w * 0.55, y + h * 0.6), (x + w * 0.8, y + h * 0.3)], fill=ROAD, width=max(6, int(h * 0.04)))
    cx, cy = x + w * 0.42, y + h * 0.5
    r = min(w, h) * 0.28
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(120, 120, 110, 255), width=2)
    pr = max(6, h * 0.03)
    d.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=TAN, outline=INK, width=2)
    text(d, [cx + pr, cy - pr * 2, 300, pr * 2], "YonV", INK, pr * 2.2, pad=4)
    for (mx, my, name) in ((x + w * 0.68, y + h * 0.42, "Bravo 1-1"), (x + w * 0.22, y + h * 0.8, "Alpha 4-2")):
        s = max(8, h * 0.035)
        d.rectangle([mx - s, my - s * 0.7, mx + s, my + s * 0.7], fill=(200, 240, 255, 255), outline=(40, 180, 230, 255), width=3)
        d.line([(mx - s, my - s * 0.7), (mx + s, my + s * 0.7)], fill=(40, 180, 230, 255), width=2)
        d.line([(mx - s, my + s * 0.7), (mx + s, my - s * 0.7)], fill=(40, 180, 230, 255), width=2)
        text(d, [mx + s, my - s, 300, s * 2], name, (40, 180, 230, 255), s * 1.6, pad=4)
    return cx, cy


def chip(d, box, label, outline, fill, colour, size, ear="", tx=False):
    x, y, w, h = box
    d.rectangle([x, y, x + w, y + h], fill=outline)
    e = max(2, h * 0.08)
    d.rectangle([x + e, y + e, x + w - e, y + h - e], fill=fill)
    text(d, box, label, colour, size, "center")
    if ear:
        text(d, [x + w - h, y, h, h], ear, DIM if not tx else WHITE, size, "center")


# ------------------------------------------------------------------ phone --
def phone_screen(d, W, H, m):
    uW, uH = W / 1030, H / 440
    gx, gy = 6 * uW, 6 * uH
    inset = 0.05 * min(W, H)
    sx, sy, sw, sh = inset, 0, W - 2 * inset, H
    line = 25 * uH
    statusH = netsH = line + 2 * gy
    cells = [("NET 70%", INK), ("MESH 1H", INK), ("JAM 0%", INK), ("GPS 0413 1168", INK), ("DRONES 0", MUTED), ("MSG 2", TX)]
    cw = (sw - 5 * gx) / 6
    for i, (s, col) in enumerate(cells):
        text(d, [sx + i * (cw + gx), sy + gy, cw, line], s, col, line * 0.72, "center")
    m["status"] = (sx + cw * 0.5, sy + gy + line / 2)
    mapY, mapH = sy + statusH, sh - statusH - netsH
    map_art(d, sx, mapY, sw, mapH)
    m["map"] = (sx + sw * 0.42, mapY + mapH * 0.62)
    lw, lh = 210 * uW, 26 * uH
    rows = [("1 YONV", GREEN), ("2 REYES", GREEN), ("3 KOWALSKI", TX)]
    d.rectangle([sx + gx, mapY + gy, sx + gx + lw, mapY + gy + lh * len(rows)], fill=(32, 38, 28, 215))
    for i, (s, dot) in enumerate(rows):
        y = mapY + gy + i * lh
        d.ellipse([sx + gx + 8, y + lh * 0.3, sx + gx + 8 + lh * 0.4, y + lh * 0.7], fill=dot)
        text(d, [sx + gx + lh * 0.6, y, lw, lh], s, GROUND, lh * 0.7)
    m["squad"] = (sx + gx + lw / 2, mapY + gy + lh * 1.5)
    tw = 300 * uW
    d.rectangle([sx + sw - gx - tw, mapY + gy, sx + sw - gx, mapY + gy + lh], fill=(32, 38, 28, 215))
    text(d, [sx + sw - gx - tw, mapY + gy, tw, lh], "REYES  ·  GHOST 1", GROUND, lh * 0.7, "center")
    m["talk"] = (sx + sw - gx - tw / 2, mapY + gy + lh / 2)
    ny, nh = sy + sh - netsH, netsH
    cols = 3
    nx, nw = sx - gx, sw + 2 * gx
    cellW = min((nw - (cols + 1) * gx) / cols, 260 * uW)
    cellH = line
    top = ny + (nh - cellH) / 2
    nets = [("TX 1 GHOST 1", TX, TX, WHITE, "B", True), ("2 C2", GREEN, GROUND, INK, "B", False), ("3 A2G", AMBER, GROUND, INK, "L", False)]
    for i, (lab, outl, fill, col, ear, tx) in enumerate(nets):
        x0 = nx + gx + i * (cellW + gx)
        chip(d, [x0, top, cellW, cellH], lab, outl, fill, col, cellH * 0.7, ear, tx)
    m["tx"] = (nx + gx + cellW / 2, top + cellH / 2)
    m["net"] = (nx + gx + cellW + gx + cellW / 2, top + cellH / 2)
    m["ear"] = (nx + gx + 3 * cellW + 2 * gx - cellH / 2, top + cellH / 2)
    m["weak"] = (nx + gx + 2 * (cellW + gx) + cellW * 0.25, top + cellH / 2)


def phone_callouts(m, keys):
    return [
        (1, m["status"], (-40, 40)), (2, m["map"], (60, -40)), (3, m["net"], (0, -46)), (4, m["tx"], (-40, -46)),
        (5, m["ear"], (40, -46)), (6, m["weak"], (-40, -46)), (7, m["squad"], (60, 40)), (8, m["talk"], (0, 46)),
        (9, key_centre(keys, 0), (-56, 0)), (10, key_centre(keys, 4), (-56, 0)),
    ]


# ------------------------------------------------------------------- side --
def side_screen(d, W, H, m):
    uW, uH = W / 600, H / 1000
    gx, gy = 6 * uW, 6 * uH
    inset = 0.05 * min(W, H)
    sx, sy, sw, sh = inset, inset, W - 2 * inset, H - 2 * inset
    statusH, squadH, netsH = 70 * uH, 90 * uH, 120 * uH
    cells = [("NET 70%", INK), ("MESH 1H", INK), ("JAM 0%", INK), ("GPS 0413 1168", INK), ("DRONES 0", MUTED), ("MSG 2", TX)]
    cw = (sw - 2 * gx) / 3
    ch = (statusH - 3 * gy) / 2
    for i, (s, col) in enumerate(cells):
        text(d, [sx + (i % 3) * (cw + gx), sy + gy + (i // 3) * (ch + gy), cw, ch], s, col, ch * 0.62, "center")
    m["status"] = (sx + cw / 2, sy + gy + ch / 2)
    mapY, mapH = sy + statusH, sh - statusH - squadH - netsH
    map_art(d, sx, mapY, sw, mapH)
    m["map"] = (sx + sw * 0.45, mapY + mapH * 0.62)
    lh = 26 * uH
    tw = min(300 * uW, sw - 2 * gx)
    d.rectangle([sx + gx, mapY + gy, sx + gx + tw, mapY + gy + lh], fill=(32, 38, 28, 215))
    text(d, [sx + gx, mapY + gy, tw, lh], "REYES  ·  GHOST 1", GROUND, lh * 0.7, "center")
    m["talk"] = (sx + gx + tw / 2, mapY + gy + lh / 2)
    qy = mapY + mapH
    colW = (sw - gx) / 2
    rows = [("1 YONV", GREEN), ("2 REYES", GREEN), ("3 KOWALSKI", TX), ("4 ORTIZ", GREEN), ("5 LEE", AMBER), ("6 PARK", GREEN)]
    rh = squadH / 3
    for i, (s, dot) in enumerate(rows):
        x = sx + (i // 3) * (colW + gx)
        y = qy + (i % 3) * rh
        d.ellipse([x + 6, y + rh * 0.3, x + 6 + rh * 0.4, y + rh * 0.7], fill=dot)
        text(d, [x + rh * 0.55, y, colW, rh], s, INK, rh * 0.62)
    m["squad"] = (sx + colW / 2, qy + rh * 1.5)
    ny = sy + sh - netsH
    nx, nw = sx - gx, sw + 2 * gx
    cellW = (nw - 3 * gx) / 2
    cellH = min(32 * uH, (netsH - 3 * gy) / 2)
    top = ny + (netsH - 2 * cellH - gy) / 2
    nets = [("TX 1 GHOST 1", TX, TX, WHITE, "B", True), ("2 C2", GREEN, GROUND, INK, "B", False), ("3 A2G", AMBER, GROUND, INK, "L", False)]
    for i, (lab, outl, fill, col, ear, tx) in enumerate(nets):
        x0 = nx + gx + (i % 2) * (cellW + gx)
        y0 = top + (i // 2) * (cellH + gy)
        chip(d, [x0, y0, cellW, cellH], lab, outl, fill, col, cellH * 0.62, ear, tx)
    m["tx"] = (nx + gx + cellW / 2, top + cellH / 2)
    m["net"] = (nx + 2 * gx + cellW * 1.5, top + cellH / 2)
    m["ear"] = (nx + 2 * gx + 2 * cellW - cellH / 2, top + cellH / 2)
    m["weak"] = (nx + gx + cellW * 0.25, top + cellH + gy + cellH / 2)


def side_callouts(m, keys):
    return [
        (1, m["status"], (-70, -40)), (2, m["map"], (60, -40)), (3, m["net"], (0, -46)), (4, m["tx"], (-40, -46)),
        (5, m["ear"], (40, -46)), (6, m["weak"], (-40, 46)), (7, m["squad"], (0, 46)), (8, m["talk"], (0, 46)),
        (9, key_centre(keys, 0), (-60, 0)), (10, key_centre(keys, 4), (-60, 0)),
    ]


# ----------------------------------------------------------------- tablet --
def tablet_screen(d, W, H, m):
    d.rectangle([0, 0, W, H], fill=RECESS)
    uW = W / 1364
    rw = 11 * uW
    rh = 11 * (H / 1000)
    sx, sy, sw, sh = rw, rh, W - 2 * rw, H - 2 * rh
    uW, uH = sw / 1364, sh / 1000
    gap = 8 * uW
    barH, notifyH, tilesH, ruleH, netsH, border = 34 * uH, 30 * uH, 96 * uH, 3 * uH, 48 * uH, 8 * uW
    d.rectangle([sx, sy, sx + sw, sy + sh], fill=INK)
    d.rectangle([sx, sy, sx + sw, sy + barH], fill=GROUND)
    text(d, [sx, sy, sw * 0.1, barH], "TAC//APP", TAN, barH * 0.5, pad=12)
    text(d, [sx + sw * 0.1, sy, sw * 0.5, barH], "1200     GRID 0413 1168     YONV · GHOST 1     CH 3/10 30%", INK, barH * 0.5)
    text(d, [sx, sy, sw, barH], "TABLET      ESC CLOSES", INK, barH * 0.5, "right", pad=12)
    m["bar"] = (sx + sw * 0.45, sy + barH / 2)
    y = sy + barH
    d.rectangle([sx, y, sx + sw * 0.031, y + notifyH], fill=TAN)
    text(d, [sx, y, sw * 0.031, notifyH], "4", INK, notifyH * 0.5, "center")
    text(d, [sx + sw * 0.031, y, sw * 0.6, notifyH], "EW: JAMMER   UHF JAMMER HEARD, TRACK T1 - DF IT, SEND THE FIX", GROUND, notifyH * 0.45, pad=14)
    text(d, [sx, y, sw, notifyH], "1200", GROUND, notifyH * 0.45, "right", pad=12)
    m["notify"] = (sx + sw * 0.3, y + notifyH / 2)
    y = sy + barH + notifyH
    tiles = [("DRONES", "WARN", "BRG 85 · 1.5 KM", True), ("JAM", "0%", "SPECTRUM CLEAR", False), ("WEATHER", "OVC", "317 AT 3 M/S", False),
             ("TIMER", "00:00", "READY", False), ("RADIO", "GHOST 1", "QUIET", False), ("MEDIC", "0", "SQUAD OK", False),
             ("HACK", "0", "NOTHING IN RANGE", False), ("INTEL", "0", "NO FILES", False), ("SUPPORT", "6", "6 IDLE", False), ("PAC", "3", "OP OPEN", True)]
    tw = (sw - 9 * gap) / 10
    for i, (lab, val, sub, hot) in enumerate(tiles):
        x = sx + i * (tw + gap)
        fill = TAN if hot else (40, 46, 36, 255)
        col = INK if hot else GROUND
        d.rectangle([x, y + gap, x + tw, y + tilesH - gap], fill=fill, outline=(70, 76, 64, 255), width=2)
        text(d, [x, y + gap, tw, tilesH * 0.3], lab, col, tilesH * 0.13, pad=10)
        text(d, [x, y + tilesH * 0.3, tw, tilesH * 0.4], val, col, tilesH * 0.26, pad=10)
        text(d, [x, y + tilesH * 0.7, tw, tilesH * 0.25], sub, col if hot else DIM, tilesH * 0.11, pad=10)
        if lab == "RADIO":
            m["radio"] = (x + tw / 2, y + tilesH * 0.5)
    y = sy + barH + notifyH + tilesH + ruleH
    hx, hy = sx + border, y
    hw, hh = sw - 2 * border, sh - (y - sy) - netsH - border
    map_art(d, hx, hy, hw, hh)
    m["map"] = (hx + hw * 0.5, hy + hh * 0.75)

    def place(fx, fy, fw, fh):
        return [hx + fx * hw, hy + fy * hh, fw * hw, fh * hh]
    panel = (32, 38, 28, 235)
    rx, ry, rwid, rhei = place(0.006, 0.010, 0.2493, 0.62)
    d.rectangle([rx, ry, rx + rwid, ry + rhei], fill=panel, outline=TAN, width=2)
    text(d, [rx, ry, rwid, rhei * 0.07], "SQUAD", GROUND, rhei * 0.035, pad=10)
    rows = [("SGT YONV", GREEN), ("CPL REYES", GREEN), ("SPC KOWALSKI", TX), ("SPC ORTIZ", GREEN)]
    rowh = rhei * 0.08
    for i, (s, dot) in enumerate(rows):
        yy = ry + rhei * 0.09 + i * rowh
        d.ellipse([rx + 10, yy + rowh * 0.3, rx + 10 + rowh * 0.4, yy + rowh * 0.7], fill=dot)
        text(d, [rx + rowh * 0.6, yy, rwid, rowh], s, GROUND, rowh * 0.5)
        if i:
            bw = rwid * 0.22
            d.rectangle([rx + rwid - bw - 10, yy + rowh * 0.15, rx + rwid - 10, yy + rowh * 0.85], outline=GROUND, width=2)
            text(d, [rx + rwid - bw - 10, yy + rowh * 0.15, bw, rowh * 0.7], "CALL", GROUND, rowh * 0.38, "center")
    m["rail"] = (rx + rwid - rwid * 0.21, ry + rhei * 0.09 + rowh * 1.5)
    tx, ty, tw2, th = place(0.2613, 0.010, 0.17, 0.04)
    d.rectangle([tx, ty, tx + tw2, ty + th], fill=panel)
    text(d, [tx, ty, tw2, th], "REYES  ·  GHOST 1", GROUND, th * 0.5, "center")
    m["talk"] = (tx + tw2 / 2, ty + th / 2)
    for i, lab in enumerate(["TOOLS", "SETTINGS", "ADMIN", "HIDE ALL"]):
        bx, by, bw, bh = place(0.6934 + i * 0.0762, 0.010, 0.0722, 0.04)
        d.rectangle([bx, by, bx + bw, by + bh], fill=panel, outline=TAN if lab == "ADMIN" else GROUND, width=2)
        text(d, [bx, by, bw, bh], lab, TAN if lab == "ADMIN" else GROUND, bh * 0.42, "center")
        if lab == "SETTINGS":
            m["settings"] = (bx + bw / 2, by + bh / 2)
    bx, by, bw, bh = place(0.6934, 0.060, 0.3006, 0.068)
    d.rectangle([bx, by, bx + bw, by + bh], fill=TAN)
    text(d, [bx, by, bw, bh * 0.55], "TROOPS IN CONTACT", INK, bh * 0.3, "center")
    text(d, [bx, by + bh * 0.5, bw, bh * 0.5], "MARKS THE MAP, ALERTS THE SIDE, FILES ON C2", INK, bh * 0.2, "center")
    bx, by, bw, bh = place(0.6934, 0.130, 0.3006, 0.15)
    d.rectangle([bx, by, bx + bw, by + bh], fill=panel)
    text(d, [bx, by, bw, bh * 0.25], "MAP TOOLS", GROUND, bh * 0.14, pad=10)
    for i, lab in enumerate(["CENTRE", "RULER", "PROTRACTOR", "ROUTE", "MARK", "GRID", "VIEWSHED", "CLEAR"]):
        cx = bx + 8 + (i % 4) * (bw - 16) / 4
        cy = by + bh * 0.3 + (i // 4) * bh * 0.34
        d.rectangle([cx + 3, cy, cx + (bw - 16) / 4 - 3, cy + bh * 0.28], outline=GROUND, width=2)
        text(d, [cx + 3, cy, (bw - 16) / 4 - 6, bh * 0.28], lab, GROUND, bh * 0.1, "center")
    bx, by, bw, bh = place(0.6934, 0.290, 0.3006, 0.69)
    d.rectangle([bx, by, bx + bw, by + bh], fill=panel)
    text(d, [bx, by, bw, bh * 0.06], "TAC//MSG - READER", GROUND, bh * 0.03, pad=10)
    d.rectangle([bx, by + bh * 0.06, bx + bw, by + bh * 0.11], fill=TAN)
    text(d, [bx, by + bh * 0.06, bw, bh * 0.05], ">   ALL", INK, bh * 0.028, pad=14)
    text(d, [bx, by + bh * 0.12, bw, bh * 0.05], "SITREP  REYES  1158   CALL", GROUND, bh * 0.025, pad=14)
    for i, lab in enumerate(["OPEN FULL", "NEW", "LOG"]):
        cx = bx + 8 + i * (bw - 16) / 3
        d.rectangle([cx + 3, by + bh * 0.92, cx + (bw - 16) / 3 - 3, by + bh * 0.98], fill=TAN if i == 0 else panel, outline=GROUND, width=2)
        text(d, [cx + 3, by + bh * 0.92, (bw - 16) / 3 - 6, bh * 0.06], lab, INK if i == 0 else GROUND, bh * 0.022, "center")
    m["reader"] = (bx + bw / 2, by + bh * 0.5)
    ny = sy + sh - netsH
    gy = netsH * 8 / 48
    cellH = netsH - 2 * gy
    globalW = 120 * uW
    inner = sw - globalW - gap
    cellW = min((inner - 4 * gap) / 3, 180 * uW)
    nets = [("TX 1 GHOST 1", TX, TX, WHITE, "B", True), ("2 C2", GREEN, INK, GROUND, "B", False), ("3 A2G", AMBER, INK, GROUND, "L", False)]
    for i, (lab, outl, fill, col, ear, tx) in enumerate(nets):
        chip(d, [sx + gap + i * (cellW + gap), ny + gy, cellW, cellH], lab, outl, fill, col, cellH * 0.5, ear, tx)
    gx0 = sx + sw - gap - globalW
    d.rectangle([gx0, ny + gy, gx0 + globalW, ny + gy + cellH], fill=GROUND, outline=DIM, width=2)
    text(d, [gx0, ny + gy, globalW, cellH], "GLOBAL", INK, cellH * 0.5, "center")
    m["tx"] = (sx + gap + cellW / 2, ny + gy + cellH / 2)
    m["net"] = (sx + 2 * gap + cellW * 1.5, ny + gy + cellH / 2)
    m["global"] = (gx0 + globalW / 2, ny + gy + cellH / 2)


def tablet_callouts(m, keys):
    return [
        (1, m["bar"], (0, -44)), (2, m["notify"], (60, 44)), (3, m["radio"], (0, 50)), (4, m["rail"], (50, 40)),
        (5, m["map"], (60, -40)), (6, m["talk"], (0, 46)), (7, m["reader"], (-60, -40)), (8, m["settings"], (0, -44)),
        (9, m["net"], (0, -46)), (10, m["tx"], (-40, -46)), (11, m["global"], (-50, -46)),
        (12, key_centre(keys, 0), (-56, 0)), (13, key_centre(keys, 4), (-56, 0)),
    ]


def key_centre(keys, i):
    x, y, w, h = keys[i]
    return ("canvas", x + w / 2, y + h / 2)


# THE SIMPLE SIGNS (user, 2026-10-23: "make sure i have simple signs with
# pictures for in game"): the same drawing with four callouts - picked from
# the full set by their numbers, then numbered 1-4 - for a board a man reads
# from the road.
SIMPLE_PICKS = {"diag_phone": [1, 3, 4, 9], "diag_side": [1, 3, 4, 9], "diag_tablet": [3, 9, 10, 11]}


def render(device, draw_screen, callouts, name, picks=None):
    frame = Image.open(os.path.join(ART, device + "_frame.png")).convert("RGBA")
    info = DEV[device]
    x0, y0, x1, y1 = info["screen_px"]
    W, H = x1 - x0 + 1, y1 - y0 + 1
    screen = Image.new("RGBA", (W, H), GROUND)
    marks = {}
    draw_screen(ImageDraw.Draw(screen), W, H, marks)
    base = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    base.alpha_composite(screen, (x0, y0))
    base.alpha_composite(frame)
    fx0, fy0, fx1, fy1 = info["frame_px"]
    pad = 40
    cx0, cy0 = max(0, fx0 - pad), max(0, fy0 - pad)
    crop = base.crop((cx0, cy0, min(base.width, fx1 + pad), min(base.height, fy1 + pad)))
    k = OUT_W / crop.width
    out = crop.resize((OUT_W, int(crop.height * k)), Image.LANCZOS)
    d = ImageDraw.Draw(out)
    r = MARKER_R
    items = callouts(marks, info["keys_px"])
    if picks:
        items = [(i + 1,) + tuple(item[1:]) for i, item in enumerate(it for it in items if it[0] in picks)]
    for item in items:
        n, p = item[0], item[1]
        dx, dy = item[2] if len(item) > 2 else (-40, -40)
        if p[0] == "canvas":
            px, py = p[1], p[2]
        else:
            px, py = x0 + p[0], y0 + p[1]
        ax, ay = (px - cx0) * k, (py - cy0) * k
        cx, cy = ax + dx, ay + dy
        # The marker sits off the thing it names, a leader back to it.
        d.line([(cx, cy), (ax, ay)], fill=TX, width=5)
        d.ellipse([ax - 5, ay - 5, ax + 5, ay + 5], fill=TX, outline=WHITE, width=2)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=TX, outline=WHITE, width=3)
        text(d, [cx - r, cy - r, 2 * r, 2 * r], str(n), WHITE, MARKER_FONT, "center", pad=0)
    os.makedirs(OUT, exist_ok=True)
    out.save(os.path.join(OUT, name + ".png"), optimize=True)
    print("%s %s" % (name, out.size))


if __name__ == "__main__":
    for device, screen, callouts, name in (
        ("phone", phone_screen, phone_callouts, "diag_phone"),
        ("side", side_screen, side_callouts, "diag_side"),
        ("large", tablet_screen, tablet_callouts, "diag_tablet"),
    ):
        render(device, screen, callouts, name)
        render(device, screen, callouts, name + "_simple", SIMPLE_PICKS[name])
    # The UAV operator's tablet: the same screen in the frame with grips
    # (user, 2026-10-23: "include a image of the uav operator version").
    render("uav", tablet_screen, tablet_callouts, "diag_tablet_uav")
