#!/usr/bin/env python3
"""Small icons for the eleven PAC skills (JMSB.skills in the jmsb Mongo; user,
2026-10-22: "make a small icon for each").

Each icon is a white symbol on transparent, the game's icon convention, so it
can be tinted with the skill's own colour where it is drawn. Drawn at DRAW px
and scaled down to ICON px, so the edges are smooth at the small size.

  cls       Combat Lifesaver   a medical cross in a ring
  medic     Medic              a solid medical cross
  eng       Engineer           a wrench
  breacher  Breacher / EOD     a blast
  jfo       JFO                binoculars
  isr       ISR                an eye
  uav       UAV operator       a quadcopter
  marksman  Marksman           a rifle round
  sniper    Sniper             a scope reticle
  heavy     Heavy Weapons      a rocket
  rto       RTO                a handheld radio, antenna up

Outputs:
  art/skills/<id>.png                       the source (committed)
  art/skills/preview.png                    all eleven on their skill colours, for eyes only
  addons/pac/data/skill_<id>_ca.paa         when hemtt is on PATH

Run:  python tools/gen_skill_icons.py
"""
import math
import os

from PIL import Image, ImageDraw

from gen_devices import to_paa

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.normpath(os.path.join(HERE, "..", "art", "skills"))
DATA = os.path.normpath(os.path.join(HERE, "..", "addons", "pac", "data"))

ICON = 64
DRAW = 512
INK = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
# The skills' colours as JMSB.skills holds them, for the preview sheet only.
COLOURS = {
    "cls": (76, 175, 80), "medic": (76, 175, 80), "eng": (66, 133, 244),
    "breacher": (244, 81, 30), "jfo": (255, 152, 0), "isr": (171, 71, 188),
    "uav": (38, 198, 218), "marksman": (121, 85, 72), "sniper": (93, 64, 55),
    "heavy": (158, 158, 158), "rto": (0, 150, 136),
}
PREVIEW_CELL = 96


def cross(d, cx, cy, arm, half):
    d.rectangle([cx - half, cy - arm, cx + half, cy + arm], fill=INK)
    d.rectangle([cx - arm, cy - half, cx + arm, cy + half], fill=INK)


def draw_cls(d):
    d.ellipse([40, 40, 472, 472], outline=INK, width=44)
    cross(d, 256, 256, 130, 44)


def draw_medic(d):
    cross(d, 256, 256, 200, 70)


def draw_eng(d):
    # A wrench on the diagonal: a handle and an open jaw at the top right.
    a = math.radians(-45)
    ux, uy = math.cos(a), math.sin(a)
    px, py = -uy, ux
    def pt(t, s):
        return (256 + ux * t + px * s, 256 + uy * t + py * s)
    d.polygon([pt(-190, -40), pt(-190, 40), pt(140, 40), pt(140, -40)], fill=INK)
    hx, hy = pt(-190, 0)
    d.ellipse([hx - 52, hy - 52, hx + 52, hy + 52], fill=INK)
    # The head: a disc with the jaw's slot cut through its far side.
    jx, jy = pt(150, 0)
    d.ellipse([jx - 100, jy - 100, jx + 100, jy + 100], fill=INK)
    d.polygon([pt(150, -42), pt(150, 42), pt(270, 42), pt(270, -42)], fill=CLEAR)


def draw_breacher(d):
    pts = []
    for i in range(20):
        r = 236 if i % 2 == 0 else 120
        a = math.radians(i * 18 - 90)
        pts.append((256 + r * math.cos(a), 256 + r * math.sin(a)))
    d.polygon(pts, fill=INK)


def draw_jfo(d):
    for cx in (150, 362):
        d.ellipse([cx - 112, 190, cx + 112, 414], fill=INK)
        d.ellipse([cx - 56, 246, cx + 56, 358], fill=CLEAR)
    d.rounded_rectangle([100, 110, 200, 230], radius=24, fill=INK)
    d.rounded_rectangle([312, 110, 412, 230], radius=24, fill=INK)
    d.rectangle([200, 140, 312, 200], fill=INK)


def draw_isr(d):
    d.chord([24, 120, 488, 392], 180, 360, fill=INK)
    d.chord([24, 120, 488, 392], 0, 180, fill=INK)
    d.ellipse([60, 156, 452, 356], fill=CLEAR)
    d.ellipse([176, 176, 336, 336], fill=INK)
    d.ellipse([228, 228, 284, 284], fill=CLEAR)


def draw_uav(d):
    for (x0, y0, x1, y1) in ((150, 150, 362, 362), (150, 362, 362, 150)):
        d.line([(x0, y0), (x1, y1)], fill=INK, width=44)
    d.rounded_rectangle([196, 196, 316, 316], radius=24, fill=INK)
    for cx, cy in ((120, 120), (392, 120), (120, 392), (392, 392)):
        d.ellipse([cx - 92, cy - 92, cx + 92, cy + 92], outline=INK, width=30)
        d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=INK)


def draw_marksman(d):
    # One round standing: a pointed bullet over a case and its rim.
    d.polygon([(256, 30), (326, 170), (326, 210), (186, 210), (186, 170)], fill=INK)
    d.rectangle([186, 232, 326, 430], fill=INK)
    d.rectangle([170, 448, 342, 482], fill=INK)


def draw_sniper(d):
    d.ellipse([40, 40, 472, 472], outline=INK, width=36)
    d.rectangle([241, 70, 271, 210], fill=INK)
    d.rectangle([241, 302, 271, 442], fill=INK)
    d.rectangle([70, 241, 210, 271], fill=INK)
    d.rectangle([302, 241, 442, 271], fill=INK)
    d.ellipse([240, 240, 272, 272], fill=INK)


def draw_heavy(d):
    # A rocket on the diagonal: nose, body, fins.
    a = math.radians(-45)
    ux, uy = math.cos(a), math.sin(a)
    px, py = -uy, ux
    def pt(t, s):
        return (256 + ux * t + px * s, 256 + uy * t + py * s)
    d.polygon([pt(230, 0), pt(130, -56), pt(130, 56)], fill=INK)
    d.polygon([pt(130, -56), pt(130, 56), pt(-150, 56), pt(-150, -56)], fill=INK)
    d.polygon([pt(-90, -56), pt(-210, -150), pt(-210, -56)], fill=INK)
    d.polygon([pt(-90, 56), pt(-210, 150), pt(-210, 56)], fill=INK)
    d.polygon([pt(-150, -30), pt(-230, -30), pt(-230, 30), pt(-150, 30)], fill=INK)


def draw_rto(d):
    # A handheld: the body with a speaker grille and two keys, the antenna up
    # from its left shoulder, three arcs of signal off its tip.
    d.rounded_rectangle([166, 190, 346, 470], radius=26, fill=INK)
    for y in (250, 282, 314):
        d.rectangle([196, y, 316, y + 14], fill=CLEAR)
    d.rounded_rectangle([196, 360, 246, 404], radius=8, fill=CLEAR)
    d.rounded_rectangle([266, 360, 316, 404], radius=8, fill=CLEAR)
    d.rectangle([192, 60, 220, 196], fill=INK)
    d.ellipse([186, 46, 226, 86], fill=INK)
    for r in (70, 115, 160):
        d.arc([206 - r, 66 - r, 206 + r, 66 + r], start=300, end=30, fill=INK, width=22)


SKILLS = {
    "cls": draw_cls, "medic": draw_medic, "eng": draw_eng, "breacher": draw_breacher,
    "jfo": draw_jfo, "isr": draw_isr, "uav": draw_uav, "marksman": draw_marksman,
    "sniper": draw_sniper, "heavy": draw_heavy, "rto": draw_rto,
}


def main():
    os.makedirs(ART, exist_ok=True)
    os.makedirs(DATA, exist_ok=True)
    sheet = Image.new("RGBA", (PREVIEW_CELL * len(SKILLS), PREVIEW_CELL), (32, 38, 28, 255))
    for i, (sid, draw) in enumerate(SKILLS.items()):
        big = Image.new("RGBA", (DRAW, DRAW), CLEAR)
        draw(ImageDraw.Draw(big))
        icon = big.resize((ICON, ICON), Image.LANCZOS)
        png = os.path.join(ART, sid + ".png")
        icon.save(png)
        to_paa(png, os.path.join(DATA, "skill_%s_ca.paa" % sid))
        tile = Image.new("RGBA", (ICON, ICON), COLOURS[sid] + (255,))
        tile.alpha_composite(Image.new("RGBA", (ICON, ICON), (255, 255, 255, 0)))
        tinted = Image.new("RGBA", (ICON, ICON), COLOURS[sid] + (255,))
        tinted.putalpha(icon.getchannel("A"))
        off = i * PREVIEW_CELL + (PREVIEW_CELL - ICON) // 2
        sheet.alpha_composite(tinted, (off, (PREVIEW_CELL - ICON) // 2))
    sheet.save(os.path.join(ART, "preview.png"))
    print("wrote %d icons and %s" % (len(SKILLS), os.path.relpath(os.path.join(ART, "preview.png"))))


if __name__ == "__main__":
    main()
