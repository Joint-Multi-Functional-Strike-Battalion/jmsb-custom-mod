"""Schematic figures for the infantry course boards (inf_* in tools/gen_signs.py,
the "diagram" kind). Drawn from scratch - dots for men, arrows, room outlines,
vehicle boxes, element labels - in the board's own palette on a transparent
ground, so they sit on the green face. The old 61st 11B slides only set the
topics; nothing is lifted from them.

Outputs art/signs/inf/<name>.png (sources, never shipped; the boards are
rendered from them).

Run:  python tools/gen_inf_figs.py   (then tools/gen_signs.py --only inf_...)
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "art", "signs", "inf"))

F_BOLD = r"C:\Windows\Fonts\arialbd.ttf"
F_BLACK = r"C:\Windows\Fonts\ariblk.ttf"

# the board palette (tools/gen_signs.py)
TAN = (0xC2, 0xA8, 0x78, 255)
BONE = (0xE9, 0xE4, 0xD3, 255)
SLATE = (0xA9, 0xAE, 0x95, 255)
INK = (0x20, 0x26, 0x1C, 255)        # the board face, for marks inside a dot
RULE = (0x3A, 0x44, 0x33, 255)       # roads, ground
TREE = (0x2C, 0x35, 0x26, 255)       # wood line
TREE_EDGE = (0x4A, 0x56, 0x40, 255)
FIRE = (0xD0, 0x6A, 0x4A, 255)       # lines of fire
ENEMY = (0xE0, 0x46, 0x36, 255)

S = 2              # drawn at twice the size, then scaled down for clean edges
MAN_R = 22         # a man's dot
FORM_R = 30        # on the formation boards, where the men are the subject
TEXT = 1.3         # labels up a size, to read on the board at a distance
W_, H_ = 1100, 480  # the usual figure: the room right of a board's notes


def font(path, size):
    return ImageFont.truetype(path, int(size * S * TEXT))


class Fig:
    def __init__(self, w=W_, h=H_):
        self.w, self.h = w, h
        self.im = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    @staticmethod
    def p(pt):
        return (pt[0] * S, pt[1] * S)

    # ---- lines and arrows ------------------------------------------------
    def line(self, pts, col=TAN, width=5, dash=None):
        pts = [self.p(q) for q in pts]
        if not dash:
            self.d.line(pts, fill=col, width=int(width * S), joint="curve")
            return
        on, off = dash[0] * S, dash[1] * S
        draw, left = True, on
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            seg = math.hypot(x1 - x0, y1 - y0)
            pos = 0.0
            while pos < seg:
                step = min(left, seg - pos)
                if draw:
                    a = pos / seg
                    b = (pos + step) / seg
                    self.d.line([(x0 + (x1 - x0) * a, y0 + (y1 - y0) * a),
                                 (x0 + (x1 - x0) * b, y0 + (y1 - y0) * b)],
                                fill=col, width=int(width * S))
                pos += step
                left -= step
                if left <= 0:
                    draw = not draw
                    left = on if draw else off

    def head(self, tip, frm, col=TAN, size=20):
        ang = math.atan2(tip[1] - frm[1], tip[0] - frm[0])
        l, r = ang + math.radians(150), ang - math.radians(150)
        pts = [tip, (tip[0] + size * math.cos(l), tip[1] + size * math.sin(l)),
               (tip[0] + size * math.cos(r), tip[1] + size * math.sin(r))]
        self.d.polygon([self.p(q) for q in pts], fill=col)

    def arrow(self, pts, col=TAN, width=5, dash=None, size=None):
        size = size or max(18, width * 3.2)
        # stop the shaft short of the tip so the head stays sharp
        (x0, y0), (x1, y1) = pts[-2], pts[-1]
        seg = math.hypot(x1 - x0, y1 - y0) or 1
        back = min(size * 0.6, seg)
        end = (x1 - (x1 - x0) / seg * back, y1 - (y1 - y0) / seg * back)
        self.line(pts[:-1] + [end], col, width, dash)
        self.head(pts[-1], pts[-2], col, size)

    # ---- marks -------------------------------------------------------------
    def text(self, xy, s, size=24, col=TAN, anchor="mm", bold=True):
        self.d.text(self.p(xy), s, font=font(F_BOLD if bold else F_BLACK, size), fill=col, anchor=anchor)

    def man(self, x, y, face=0, role=None, col=BONE, r=MAN_R):
        """A man: a dot, a small triangle the way he faces (0 up, 90 right),
        a role mark inside: SL X, TL slash, MED star, JTAC triangle, ENG bar."""
        a = math.radians(face - 90)
        tip = (x + (r + 13) * math.cos(a), y + (r + 13) * math.sin(a))
        bl = (x + (r + 2) * math.cos(a + 0.55), y + (r + 2) * math.sin(a + 0.55))
        br = (x + (r + 2) * math.cos(a - 0.55), y + (r + 2) * math.sin(a - 0.55))
        self.d.polygon([self.p(tip), self.p(bl), self.p(br)], fill=col)
        self.d.ellipse([self.p((x - r, y - r)), self.p((x + r, y + r))], fill=col)
        k, w = r * 0.62, max(3, r * 0.22)
        if role == "SL":
            self.line([(x - k, y - k), (x + k, y + k)], INK, w)
            self.line([(x - k, y + k), (x + k, y - k)], INK, w)
        elif role == "TL":
            self.line([(x - k, y + k), (x + k, y - k)], INK, w * 1.3)
        elif role == "MED":
            for t in (90, 30, 150):
                c, s_ = math.cos(math.radians(t)) * k, math.sin(math.radians(t)) * k
                self.line([(x - c, y - s_), (x + c, y + s_)], INK, w)
        elif role == "JTAC":
            self.d.polygon([self.p((x, y - k)), self.p((x + k, y + k * 0.75)), self.p((x - k, y + k * 0.75))], fill=INK)
        elif role == "ENG":
            self.line([(x - k * 0.7, y), (x + k * 0.7, y)], INK, w)
            for sx in (-1, 1):
                cx = x + sx * k * 0.75
                q = k * 0.42
                self.d.arc([self.p((cx - q, y - q)), self.p((cx + q, y + q))],
                           270 if sx < 0 else 90, 90 if sx < 0 else 270, fill=INK, width=int(w * S))

    def enemy(self, x, y, r=11):
        self.d.ellipse([self.p((x - r, y - r)), self.p((x + r, y + r))], fill=ENEMY)

    def enemy_pos(self, x, y, k=44, label="ENEMY"):
        """A hostile position: the red diamond."""
        pts = [(x, y - k), (x + k, y), (x, y + k), (x - k, y)]
        self.d.polygon([self.p(q) for q in pts], outline=ENEMY, width=int(6 * S))
        self.text((x, y), "EN", 22, ENEMY)
        if label:
            self.text((x, y - k - 18), label, 20, ENEMY)

    def unit(self, x, y, label=None, w=86, h=54, col=TAN, below=True):
        """An infantry element: the box with the X."""
        x0, y0, x1, y1 = x - w / 2, y - h / 2, x + w / 2, y + h / 2
        self.d.rectangle([self.p((x0, y0)), self.p((x1, y1))], outline=col, width=int(5 * S))
        self.line([(x0, y0), (x1, y1)], col, 3)
        self.line([(x0, y1), (x1, y0)], col, 3)
        if label:
            self.text((x, y1 + 20) if below else (x, y0 - 20), label, 20, col)

    def disc(self, x, y, s, col=TAN, r=17, ink=INK):
        self.d.ellipse([self.p((x - r, y - r)), self.p((x + r, y + r))], fill=col)
        self.text((x, y + 1), s, r * 1.2, ink)

    def ring(self, x, y, label=None, r=14, col=SLATE):
        self.d.ellipse([self.p((x - r, y - r)), self.p((x + r, y + r))], outline=col, width=int(4 * S))
        if label:
            self.text((x, y + r + 16), label, 18, col)

    def vehicle(self, x, y, face=0, n=None, l=120, w=62):
        """A vehicle from above, nose toward face (0 up, 90 right)."""
        a = math.radians(face)
        fx, fy = math.sin(a), -math.cos(a)      # forward
        rx, ry = math.cos(a), math.sin(a)       # right

        def at(f, r):
            return (x + fx * f + rx * r, y + fy * f + ry * r)
        body = [at(l / 2 - 8, -w / 2), at(l / 2, -w / 2 + 10), at(l / 2, w / 2 - 10), at(l / 2 - 8, w / 2),
                at(-l / 2, w / 2), at(-l / 2, -w / 2)]
        self.d.polygon([self.p(q) for q in body], fill=TAN, outline=INK)
        self.line([at(l * 0.18, -w / 2 + 6), at(l * 0.18, w / 2 - 6)], INK, 3)    # windscreen
        self.line([at(l / 2 - 12, -w / 4), at(l / 2 - 4, 0), at(l / 2 - 12, w / 4)], INK, 3)  # nose chevron
        if n is not None:
            self.text(at(-l * 0.12, 0), str(n), 30, INK, bold=False)

    def wall(self, pts, width=7):
        self.line(pts, BONE, width)

    def room(self, x0, y0, x1, y1, door, width=7):
        """A room outline, the door a gap in the bottom wall: door = (xa, xb)."""
        xa, xb = door
        self.wall([(xa, y1), (x0, y1), (x0, y0), (x1, y0), (x1, y1), (xb, y1)], width)

    def road(self, y0, y1, x0=0, x1=None, centre=True):
        x1 = self.w if x1 is None else x1
        self.d.rectangle([self.p((x0, y0)), self.p((x1, y1))], fill=RULE)
        if centre:
            self.line([(x0, (y0 + y1) / 2), (x1, (y0 + y1) / 2)], SLATE, 2, dash=(14, 10))

    def woods(self, box, seed=1, avoid=None):
        """A wood line: a field of tree crowns; avoid = (cx, cy, rx, ry) clearing."""
        x0, y0, x1, y1 = box
        rnd = random.Random(seed)
        step = 34
        for gy in range(int(y0), int(y1), step):
            for gx in range(int(x0), int(x1), step):
                cx = gx + rnd.uniform(4, step - 4)
                cy = gy + rnd.uniform(4, step - 4)
                if avoid:
                    ax, ay, arx, ary = avoid
                    if ((cx - ax) / arx) ** 2 + ((cy - ay) / ary) ** 2 < 1:
                        continue
                r = rnd.uniform(11, 17)
                self.d.ellipse([self.p((cx - r, cy - r)), self.p((cx + r, cy + r))], fill=TREE, outline=TREE_EDGE, width=S * 2)

    def save(self, name):
        os.makedirs(OUT, exist_ok=True)
        self.im.resize((self.w, self.h), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))


def bez(*c, n=40):
    """Points along a Bezier curve through control points c."""
    out = []
    for i in range(n + 1):
        t = i / n
        pts = list(c)
        while len(pts) > 1:
            pts = [(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t) for a, b in zip(pts, pts[1:])]
        out.append(pts[0])
    return out


# ---------------------------------------------------------------------------
# the figures
# ---------------------------------------------------------------------------
def roles():
    f = Fig(2000, 300)
    names = [("SL", "SQUAD LEADER"), ("TL", "TEAM LEADER"), ("MED", "MEDIC"),
             ("JTAC", "JTAC"), ("ENG", "ENGINEER"), (None, "DISMOUNT")]
    for i, (role, name) in enumerate(names):
        x = 170 + i * 332
        f.man(x, 110, 0, role, r=58)
        f.text((x, 238), name, 26, BONE)
    f.save("roles")


def open_area():
    f = Fig()
    f.woods((0, 0, 300, H_), seed=2)
    f.woods((900, 0, W_, H_), seed=3)
    f.road(0, H_, 330, 380, centre=False)
    f.line([(355, 0), (355, H_)], SLATE, 2, dash=(14, 10))
    f.text((355, 465), "ROAD", 18, SLATE)
    f.text((640, 40), "LARGE OPEN AREA", 24, SLATE)
    f.ring(40, 240, "NRP")
    f.unit(150, 240, "SQUAD")
    f.arrow([(200, 210), (330, 170)], TAN, 4, dash=(12, 9))
    f.arrow([(200, 270), (330, 310)], TAN, 4, dash=(12, 9))
    f.text((265, 120), "TRAVELLING", 18, TAN)
    f.text((265, 140), "OVERWATCH", 18, TAN)
    # the two teams bound across: A on the top lane, B on the bottom
    for (x0, x1, y) in ((385, 560, 170), (385, 720, 310), (560, 880, 170), (720, 960, 310)):
        f.arrow([(x0 + 18, y), (x1 - 20, y)], TAN, 5, dash=(16, 10))
    for (x, y) in ((560, 170), (720, 310), (880, 170)):
        f.ring(x, y, r=16, col=TAN)
    f.ring(960, 310, r=16, col=TAN)
    f.text((640, 400), "BOUNDING OVERWATCH", 22, TAN)
    f.line([(380, 440), (900, 440)], SLATE, 2)
    for x in (380, 900):
        f.line([(x, 428), (x, 452)], SLATE, 2)
    f.text((640, 464), "ABOUT 250 m", 18, SLATE)
    f.ring(1050, 240, "FRP")
    f.save("open_area")


def small_open():
    f = Fig()
    for x0, seed in ((0, 4), (560, 5)):
        cx = x0 + 270
        f.woods((x0, 0, x0 + 540, H_), seed=seed, avoid=(cx, 240, 170, 95))
        f.text((cx, 230), "SMALL OPEN", 20, SLATE)
        f.text((cx, 254), "AREA", 20, SLATE)
    f.line([(550, 0), (550, H_)], SLATE, 3, dash=(16, 12))
    # contour: round the open area inside the tree line
    f.ring(400, 430, r=13)
    f.text((450, 430), "NRP", 18, SLATE, anchor="lm")
    f.unit(270, 430, w=60, h=38)
    f.arrow(bez((270, 405), (270, 330), (60, 330), (60, 240)) + bez((60, 240), (60, 150), (270, 150), (270, 50))[1:], TAN, 6)
    f.ring(270, 30, r=13)
    f.text((360, 30), "FRP", 18, SLATE)
    f.text((20, 22), "CONTOUR", 26, BONE, anchor="lm")
    # detour bypass: out at 90 degrees, past, and back on the line
    f.ring(700, 430, r=13)
    f.text((650, 430), "NRP", 18, SLATE, anchor="rm")
    f.unit(830, 430, w=60, h=38)
    f.arrow([(830, 405), (830, 380), (1060, 380), (1060, 100), (830, 100), (830, 50)], TAN, 6)
    f.ring(830, 30, r=13)
    f.text((920, 30), "FRP", 18, SLATE)
    f.text((580, 22), "DETOUR BYPASS", 26, BONE, anchor="lm")
    f.save("small_open")


def defilade():
    # TERRAIN FROM THE SHOOTER'S EYE (user, 2026-11-07: "you confusing concepts
    # of terrain with fire methods" - the slide is "Defilade = dead space,
    # Enfilade = in direct sight", both about ground, not a way of firing).
    # One profile: the line of sight grazes the crest; the ground it sees is
    # ENFILADE (in direct sight, marked), the dip it cannot see behind the crest
    # is DEFILADE - dead space - until the far slope rises back into the line.
    f = Fig()
    eye, crest = (110, 380), (560, 230)
    slope = (crest[1] - eye[1]) / (crest[0] - eye[0])

    def los(x):
        return eye[1] + slope * (x - eye[0])
    meet_x = 985
    ground = [(0, 410), (80, 402), (200, 412), (330, 385), (450, 320), crest, (620, 262), (680, 320),
              (740, 370), (820, 374), (880, 330), (940, 250), (meet_x, los(meet_x)), (1040, los(1040) - 18),
              (1100, los(1100) - 34)]
    f.d.polygon([f.p(q) for q in ground + [(1100, H_), (0, H_)]], fill=RULE)
    f.line(ground, SLATE, 3)
    # defilade - dead space: under the line of sight, over the ground, crest to the far slope
    dead = [crest, (meet_x, los(meet_x))] + [q for q in reversed(ground) if crest[0] < q[0] < meet_x]
    shade = Image.new("RGBA", f.im.size, (0, 0, 0, 0))
    ImageDraw.Draw(shade).polygon([f.p(q) for q in dead], fill=(0xD0, 0x6A, 0x4A, 110))
    f.im.alpha_composite(shade)
    f.d = ImageDraw.Draw(f.im)
    # enfilade - the ground in direct sight, marked
    f.line([q for q in ground if eye[0] - 40 <= q[0] <= crest[0]], TAN, 9)
    f.line([q for q in ground if q[0] >= meet_x], TAN, 9)
    f.line([eye, (1100, los(1100))], BONE, 3, dash=(12, 8))
    f.man(96, 388, 90, r=20)
    f.enemy(770, 358)
    f.enemy(800, 362)
    f.text((170, 262), "LINE OF SIGHT", 20, BONE, anchor="lm")
    f.text((560, 290), "CREST", 18, SLATE)
    f.text((330, 446), "ENFILADE - IN DIRECT SIGHT", 22, TAN)
    f.text((1040, 190), "IN SIGHT", 18, TAN)
    f.text((1040, 212), "AGAIN", 18, TAN)
    f.text((785, 430), "DEFILADE - DEAD SPACE", 22, BONE)
    f.text((785, 456), "HIDDEN FROM THE SHOOTER", 16, SLATE)
    f.save("defilade")


def _fires(f, frm, to):
    for dx in (-26, 0, 26):
        f.arrow([frm, (to[0] + dx, to[1] + 20)], FIRE, 3)


def single_env():
    f = Fig()
    f.enemy_pos(560, 120)
    f.unit(300, 380, "SUPPORT")
    _fires(f, (330, 350), (530, 140))
    f.unit(820, 400, "MANOEUVRE")
    f.arrow(bez((820, 365), (900, 230), (870, 120), (624, 120)), TAN, 14)
    f.save("single_env")


def deep_env():
    f = Fig()
    f.enemy_pos(520, 230, label=None)
    f.text((580, 230), "ENEMY", 20, ENEMY, anchor="lm")
    f.unit(240, 400, "SUPPORT")
    _fires(f, (270, 370), (490, 250))
    f.unit(800, 410, "MANOEUVRE")
    f.arrow(bez((800, 375), (1090, 330), (1090, 20), (520, 20), (520, 165)), TAN, 14)
    f.text((820, 180), "WIDE AND DEEP", 20, TAN)
    f.save("deep_env")


def double_env():
    f = Fig()
    f.enemy_pos(550, 120)
    f.unit(550, 400, "SUPPORT")
    _fires(f, (550, 365), (550, 150))
    f.unit(170, 400, "MANOEUVRE")
    f.arrow(bez((170, 365), (120, 150), (300, 120), (484, 120)), TAN, 14)
    f.unit(930, 400, "MANOEUVRE")
    f.arrow(bez((930, 365), (980, 150), (800, 120), (616, 120)), TAN, 14)
    f.save("double_env")


def bounding():
    f = Fig()

    def row(y0, title, a, b):
        f.text((0, y0), title, 24, BONE, anchor="lm")
        for (lane, stops, name) in ((y0 + 60, a, "A"), (y0 + 150, b, "B")):
            f.unit(70, lane, w=70, h=44)
            f.text((70, lane + 38), name, 18, SLATE)
            x = 70
            for (n, xs) in stops:
                f.arrow([(x + 42, lane), (xs - 42, lane)], TAN, 7)
                f.unit(xs, lane, w=70, h=44)
                f.disc(xs + 42, lane - 32, str(n))
                x = xs
    row(20, "SUCCESSIVE", [(1, 450), (3, 830)], [(2, 450), (4, 830)])
    row(260, "ALTERNATING", [(1, 330), (3, 790)], [(2, 560), (4, 1020)])
    f.save("bounding")


def travelling():
    f = Fig()
    f.text((0, 30), "TRAVELLING", 24, BONE, anchor="lm")
    f.unit(200, 120, w=70, h=44)
    f.unit(330, 120, w=70, h=44)
    f.arrow([(380, 120), (620, 120)], TAN, 10)
    f.text((265, 172), "TOGETHER, CLOSE", 18, SLATE)
    f.text((0, 260), "TRAVELLING OVERWATCH", 24, BONE, anchor="lm")
    f.unit(200, 360, w=70, h=44)
    f.arrow([(250, 360), (380, 360)], TAN, 10)
    f.unit(720, 360, w=70, h=44)
    f.arrow([(770, 360), (1000, 360)], TAN, 10)
    f.line([(200, 420), (720, 420)], SLATE, 2)
    for x in (200, 720):
        f.line([(x, 408), (x, 432)], SLATE, 2)
    f.text((460, 446), "TRAIL STAYS FAR ENOUGH BACK TO SUPPORT", 18, SLATE)
    f.text((200, 322), "TRAIL", 18, SLATE)
    f.text((720, 322), "LEAD", 18, SLATE)
    f.save("travelling")


def support_fire():
    f = Fig()
    for i, (rx, ry) in enumerate(((210, 90), (160, 64), (105, 40))):
        f.d.ellipse([f.p((300 - rx, 360 - ry)), f.p((300 + rx, 360 + ry))], outline=RULE, width=S * 3)
    f.enemy_pos(640, 120)
    f.unit(300, 360, "SUPPORTING ELEMENT")
    f.arrow([(340, 330), (560, 110)], TAN, 4)
    f.arrow([(345, 340), (640, 190)], TAN, 4)
    f.text((400, 175), "LEFT LIMIT", 18, TAN)
    f.text((560, 300), "RIGHT LIMIT", 18, TAN)
    _fires(f, (340, 335), (610, 135))
    f.unit(920, 410, "MOVING ELEMENT")
    f.arrow(bez((920, 375), (980, 200), (860, 120), (700, 120)), TAN, 14)
    f.save("support_fire")


def linear_ambush():
    f = Fig()
    f.road(110, 200)
    f.text((60, 90), "KILL ZONE", 22, SLATE, anchor="lm")
    for x in range(260, 900, 90):
        f.enemy(x, 155)
    for i, x in enumerate(range(300, 820, 100)):
        f.man(x, 340, 0, "TL" if i == 3 else None)
        f.arrow([(x, 314), (x, 210)], FIRE, 3)
    f.text((550, 400), "AMBUSH LINE - PARALLEL TO THE KILL ZONE", 20, TAN)
    f.man(110, 330, 270)
    f.man(990, 330, 90)
    f.text((110, 380), "SECURITY", 18, SLATE)
    f.text((990, 380), "SECURITY", 18, SLATE)
    f.save("linear_ambush")


def l_ambush():
    f = Fig()
    f.road(110, 200, 0, 840)
    f.text((40, 90), "KILL ZONE", 22, SLATE, anchor="lm")
    for x in range(160, 800, 90):
        f.enemy(x, 155)
    for x in range(200, 620, 100):
        f.man(x, 340, 0)
        f.arrow([(x, 314), (x, 210)], FIRE, 3)
    f.text((400, 400), "LONG LEG - FIRES ACROSS", 20, TAN)
    for i, y in enumerate((60, 130, 190, 260)):
        f.man(920, y, 270, "TL" if i == 1 else None)
    for y in (130, 190):
        f.arrow([(890, y - 2), (640, y - 20 if y < 160 else y - 30)], FIRE, 3)
    f.text((920, 320), "SHORT LEG", 20, TAN)
    f.text((920, 346), "FIRES ALONG", 20, TAN)
    f.save("l_ambush")


def _travel(f, x0, x1, y, label="DIRECTION OF TRAVEL", vertical=False):
    if vertical:
        f.arrow([(x0, x1), (x0, y)], SLATE, 4)
        return
    f.arrow([(x0, y), (x1, y)], SLATE, 4)
    f.text(((x0 + x1) / 2, y - 22), label, 18, SLATE)


def wedge():
    f = Fig()
    f.man(550, 80, 0, "TL", r=FORM_R)
    for (x, y) in ((410, 210), (270, 340), (690, 210), (830, 340)):
        f.man(x, y, 0, r=FORM_R)
    f.line([(560, 112), (680, 190)], SLATE, 2, dash=(8, 6))
    f.text((660, 130), "10 m", 20, SLATE, anchor="lm")
    f.text((550, 440), "TEAM LEADER AT THE POINT", 20, TAN)
    f.arrow([(1030, 400), (1030, 90)], SLATE, 4)
    f.text((1030, 440), "TRAVEL", 18, SLATE)
    f.save("wedge")


def file_():
    f = Fig()
    xs = [150, 330, 510, 690, 870]
    for i, x in enumerate(xs):
        f.man(x, 260, 270 if i == 0 else 90, "TL" if i == 4 else None, r=FORM_R)
    f.line([(330, 310), (510, 310)], SLATE, 2)
    for x in (330, 510):
        f.line([(x, 300), (x, 320)], SLATE, 2)
    f.text((420, 336), "3-5 m", 20, SLATE)
    f.text((150, 310), "REAR", 18, SLATE)
    f.text((870, 310), "TL", 18, SLATE)
    _travel(f, 300, 840, 120)
    f.save("file")


def staggered():
    f = Fig()
    f.road(150, 350)
    pts = [(150, 300), (330, 200), (510, 300), (690, 200), (870, 300)]
    for i, (x, y) in enumerate(pts):
        f.man(x, y, 270 if i == 0 else 90, "TL" if i == 4 else None, r=FORM_R)
    f.line([(150, 390), (330, 390)], SLATE, 2)
    for x in (150, 330):
        f.line([(x, 380), (x, 400)], SLATE, 2)
    f.text((240, 418), "3-5 m", 20, SLATE)
    f.text((690, 418), "BOTH SIDES OF THE ROAD", 20, TAN)
    _travel(f, 300, 840, 80)
    f.save("staggered")


def line_():
    f = Fig()
    xs = [150, 350, 550, 750, 950]
    for i, x in enumerate(xs):
        f.man(x, 330, 0, "TL" if i == 2 else None, r=FORM_R)
        f.arrow([(x, 300), (x, 150)], FIRE, 3)
    f.text((550, 100), "12 O'CLOCK", 24, TAN)
    f.line([(150, 390), (350, 390)], SLATE, 2)
    for x in (150, 350):
        f.line([(x, 380), (x, 400)], SLATE, 2)
    f.text((250, 418), "5-10 m", 20, SLATE)
    f.save("line")


def _no_cover(f, x, y, w=136, h=56):
    f.line([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2), (x - w / 2, y - h / 2)], FIRE, 2, dash=(8, 6))
    f.text((x, y), "NO COVER", 16, FIRE)


def dismount():
    f = Fig()
    f.vehicle(550, 240, 0, l=150, w=76)
    _no_cover(f, 550, 100)
    _no_cover(f, 550, 380)
    f.man(420, 110, 0, "ENG")
    f.man(400, 220, 270, "MED")
    f.man(450, 330, 180, "SL")
    f.man(390, 410, 180, "JTAC")
    for i, (y, face) in enumerate(((80, 0), (170, 90), (250, 90), (330, 90), (420, 180))):
        f.man(700, y, face, "TL" if i == 2 else None)
    f.text((240, 240), "COMMAND TEAM", 20, TAN)
    f.text((240, 264), "DRIVER'S SIDE", 18, SLATE)
    f.text((900, 240), "DISMOUNT TEAM", 20, TAN)
    f.text((900, 264), "OTHER SIDE AND REAR", 18, SLATE)
    f.save("dismount")


def dismount_front():
    f = Fig()
    f.vehicle(550, 320, 0, l=150, w=76)
    for i, x in enumerate((280, 400, 700, 820, 940)):
        f.man(x, 150, 0, "TL" if i == 2 else None)
    f.text((550, 30), "CONTACT FRONT", 22, FIRE)
    f.arrow([(550, 110), (550, 58)], FIRE, 4)
    f.text((550, 205), "CLEAR OF THE GUN", 14, SLATE)
    f.man(420, 320, 270, "JTAC")
    f.man(690, 320, 90, "ENG")
    f.man(430, 440, 225, "SL")
    f.man(680, 440, 135, "MED")
    f.text((210, 320), "COMMAND", 18, TAN)
    f.text((210, 346), "TEAM", 18, TAN)
    f.text((880, 220), "DISMOUNT TEAM", 18, TAN)
    f.save("dismount_front")


def _dismount_side(name, side):
    f = Fig()
    m = (lambda x: x) if side == "left" else (lambda x: W_ - x)
    face_out = 270 if side == "left" else 90
    vx = m(860)
    f.vehicle(vx, 190, 0, l=150, w=76)
    for i, y in enumerate((50, 135, 220, 305, 390)):
        f.man(m(300), y, face_out, "TL" if i == 2 else None)
    f.text((m(300), 452), "DISMOUNT TEAM", 18, TAN)
    f.man(m(770), 300, face_out, "SL")
    f.man(m(620), 400, 180, "ENG")
    f.man(m(750), 400, 180, "MED")
    f.man(m(880), 400, 360 - face_out, "JTAC")
    f.text((m(750), 460), "COMMAND TEAM - REAR", 18, TAN)
    f.text((m(95), 190), "CONTACT", 22, FIRE)
    f.arrow([(m(170), 230), (m(20), 230)], FIRE, 4)
    f.save(name)


def stack(name, n=4, breacher=False):
    f = Fig()
    f.wall([(60, 230), (700, 230)])
    f.wall([(800, 230), (1040, 230)])
    f.wall([(60, 230), (60, 40), (1040, 40), (1040, 230)], 4)
    f.text((550, 135), "ROOM", 24, SLATE)
    f.text((750, 210), "DOOR", 18, SLATE)
    xs = [650, 560, 470, 380][:n]
    labels = ["1", "2", "3 TL", "LAST"] if n == 4 else ["1", "2"]
    for i, x in enumerate(xs):
        last = n == 4 and i == 3
        f.man(x, 290, 270 if last else 90, "TL" if (n == 4 and i == 2) else None)
        f.text((x, 340), labels[i], 20, TAN)
    if breacher:
        f.man(840, 280, 300, "ENG")
        f.text((840, 330), "BREACHER", 20, TAN)
        f.text((840, 354), "SETS THE CHARGE,", 16, SLATE)
        f.text((840, 374), "GETS CLEAR", 16, SLATE)
    f.text((520 if n == 4 else 605, 420), "THE STACK", 20, SLATE)
    f.save(name)


def strong_points():
    f = Fig()
    f.room(200, 40, 900, 440, (480, 620))
    for (x, y, dx, dy) in ((200, 40, 1, 1), (900, 40, -1, 1), (200, 440, 1, -1), (900, 440, -1, -1)):
        f.arrow([(x + dx * 90, y + dy * 80), (x + dx * 22, y + dy * 20)], TAN, 8)
    f.d.ellipse([f.p((470, 190)), f.p((630, 290))], outline=TAN, width=S * 4)
    f.text((550, 240), "CENTRE", 22, TAN)
    f.text((550, 465), "DOOR", 18, SLATE)
    f.save("strong_points")


def room_types():
    f = Fig()
    for i, (name, fed) in enumerate((("LEFT", "CORNER FED"), ("CENTRE", "CENTRE FED"), ("RIGHT", "CORNER FED"))):
        x0 = 30 + i * 360
        x1 = x0 + 320
        door = ((x0 + 22, x0 + 92), (x0 + 125, x0 + 195), (x1 - 92, x1 - 22))[i]
        f.room(x0, 40, x1, 340, door, 6)
        f.arrow([((door[0] + door[1]) / 2, 400), ((door[0] + door[1]) / 2, 310)], TAN, 5)
        f.text(((x0 + x1) / 2, 190), name, 30, BONE)
        f.text(((x0 + x1) / 2, 440), fed, 20, SLATE)
    f.save("room_types")


def feed_side(name, side):
    f = Fig()
    m = (lambda x: x) if side == "right" else (lambda x: W_ - x)
    door = sorted((m(140), m(240)))
    f.room(100, 30, 1000, 370, door)
    out = 270 if side == "right" else 90     # the stack faces the door
    into = 90 if side == "right" else 270    # the room opens this way
    # 1st man (solid path) goes deep, 2nd (dashed) takes the near corner
    f.man(m(300), 435, out)
    f.man(m(420), 435, out)
    f.arrow(bez((m(272), 435), (m(150), 430), (m(150), 280), (m(155), 115)), TAN, 4)
    f.arrow(bez((m(392), 412), (m(270), 380), (m(210), 340), (m(185), 325)), TAN, 4, dash=(10, 7))
    f.man(m(160), 80, into)
    f.man(m(160), 310, into)
    f.disc(m(215), 45, "1", r=15)
    f.disc(m(215), 275, "2", r=15)
    for y in (80, 310):
        f.arrow([(m(195), y), (m(620), y)], FIRE, 2)
    f.text((m(780), 200), "ROOM OPENS " + ("RIGHT" if side == "right" else "LEFT"), 24, SLATE)
    f.save(name)


def feed_centre():
    f = Fig()
    f.room(100, 30, 1000, 370, (480, 620))
    # 1st man (solid) turns left, 2nd (dashed) goes the opposite way
    f.man(680, 435, 270)
    f.man(800, 435, 270)
    f.arrow([(652, 435), (520, 435), (520, 335), (175, 335)], TAN, 4)
    f.arrow([(772, 412), (580, 412), (580, 300), (925, 300)], TAN, 4, dash=(10, 7))
    f.man(145, 320, 45)
    f.man(955, 320, 315)
    f.disc(145, 268, "1", r=15)
    f.disc(955, 268, "2", r=15)
    f.arrow([(170, 295), (960, 60)], FIRE, 2)
    f.arrow([(930, 295), (140, 60)], FIRE, 2)
    f.text((550, 100), "OPPOSITE WAYS", 22, SLATE)
    f.save("feed_centre")


def hallway():
    f = Fig()
    f.wall([(30, 160), (1070, 160)])
    f.wall([(30, 320), (1070, 320)])
    f.man(500, 240, 270)
    f.man(600, 240, 90)
    f.arrow([(470, 240), (60, 240)], FIRE, 3)
    f.arrow([(630, 240), (1040, 240)], FIRE, 3)
    f.text((200, 200), "FRONT", 22, TAN)
    f.text((900, 200), "REAR", 22, TAN)
    f.text((550, 380), "BACK TO BACK", 22, SLATE)
    f.save("hallway")


def corner():
    f = Fig()
    f.wall([(300, 470), (300, 40), (1070, 40)])
    f.wall([(500, 470), (500, 220), (1070, 220)])
    # 1: pie the corner, the other man covers behind
    f.man(360, 380, 0)
    f.man(440, 430, 180)
    f.disc(225, 405, "1")
    f.text((225, 440), "PIE", 18, TAN)
    # 2: two guns round the corner, one high, one low
    f.man(420, 100, 90)
    f.man(440, 175, 90, r=13)
    f.disc(225, 140, "2")
    f.text((225, 175), "HIGH, LOW", 16, TAN)
    f.arrow(bez((360, 350), (330, 230), (360, 130), (395, 105)), TAN, 3)
    f.arrow(bez((440, 400), (470, 300), (470, 220), (445, 195)), TAN, 3, dash=(8, 6))
    # 3: round together, the rear man turns to cover behind
    f.man(820, 130, 270)
    f.man(900, 130, 90)
    f.disc(860, 76, "3")
    f.arrow(bez((462, 180), (600, 190), (700, 150), (792, 132)), TAN, 3)
    f.save("corner")


def intersection():
    f = Fig()
    for ox in (0, 570):
        for (x0, y0, x1, y1) in ((20, 20, 200, 170), (330, 20, 510, 170), (20, 310, 200, 460), (330, 310, 510, 460)):
            f.d.rectangle([f.p((ox + x0, y0)), f.p((ox + x1, y1))], outline=BONE, width=S * 4)
    f.line([(550, 0), (550, H_)], SLATE, 3, dash=(16, 12))
    # 1 at the mouth, 2 out together
    f.man(250, 400, 0)
    f.man(285, 445, 180)
    f.disc(220, 450, "1", r=15)
    f.arrow(bez((250, 375), (250, 260), (190, 240), (130, 240)), TAN, 3)
    f.arrow(bez((285, 420), (290, 300), (330, 240), (390, 240)), TAN, 3)
    f.man(110, 240, 270)
    f.man(410, 240, 90)
    f.disc(265, 70, "2", r=15)
    f.text((265, 110), "TOGETHER", 16, TAN)
    # 3 across: both push into the far hall
    f.man(680, 240, 270)
    f.man(980, 240, 90)
    f.arrow(bez((700, 240), (800, 240), (820, 200), (825, 160)), TAN, 3)
    f.arrow(bez((960, 240), (860, 240), (850, 140), (840, 85)), TAN, 3, dash=(8, 6))
    f.man(835, 60, 0)
    f.man(825, 135, 180)
    f.disc(877, 100, "3", r=15)
    f.text((835, 400), "ACROSS", 16, TAN)
    f.save("intersection")


def herringbone():
    f = Fig()
    f.road(200, 290)
    _travel(f, 600, 1000, 60)
    for (n, x, up) in ((1, 930, True), (2, 740, False), (3, 540, True), (4, 350, False)):
        y = 120 if up else 380
        f.arrow([(x - 160, 245), (x - 40, 245), (x - 40, 205 if up else 285)], TAN, 3)
        f.vehicle(x, y, 45 if up else 135, n)
    f.text((150, 160), "ROAD STAYS OPEN", 18, SLATE)
    f.save("herringbone")


def coil():
    f = Fig()
    f.road(190, 290, centre=False)
    f.d.rectangle([f.p((500, 0)), f.p((600, H_))], fill=RULE)
    _travel(f, 700, 1060, 60)
    f.vehicle(830, 240, 90, 1)
    f.vehicle(550, 410, 180, 2)
    f.vehicle(550, 75, 0, 3)
    f.vehicle(270, 240, 270, 4)
    for to in ((760, 240), (550, 340), (550, 145)):
        f.arrow([(550, 240), to], TAN, 3)
    f.text((850, 400), "ALL ROUND, FACING OUT", 18, SLATE)
    f.save("coil")


def _convoy_dismount(name, hard):
    f = Fig()
    f.road(200, 290)
    _travel(f, 650, 1000, 50)
    f.vehicle(760, 245, 90, 1)
    f.vehicle(380, 245, 90, 2)
    spots = [(300, 120, 315), (840, 120, 45), (300, 380, 225), (840, 380, 135)]
    if hard:
        spots += [(460, 120, 0), (680, 120, 0), (460, 380, 180), (680, 380, 180)]
    for (x, y, face) in spots:
        vx = 380 if x < 570 else 760
        f.arrow([(vx + (x - vx) * 0.25, 245 + (y - 245) * 0.35), (x + (vx - x) * 0.2, y + (245 - y) * 0.3)], TAN, 2)
        f.man(x, y, face, r=15)
    f.text((570, 455), "EVERYONE OUT" if hard else "GUNNER AND DRIVER STAY IN", 20, TAN)
    f.save(name)


def main():
    roles()
    open_area()
    small_open()
    defilade()
    single_env()
    deep_env()
    double_env()
    bounding()
    travelling()
    support_fire()
    linear_ambush()
    l_ambush()
    wedge()
    file_()
    staggered()
    line_()
    dismount()
    dismount_front()
    _dismount_side("dismount_left", "left")
    _dismount_side("dismount_right", "right")
    stack("stack_normal")
    stack("stack_breacher", breacher=True)
    stack("stack_expedient", n=2)
    strong_points()
    room_types()
    feed_side("feed_right", "right")
    feed_centre()
    feed_side("feed_left", "left")
    hallway()
    corner()
    intersection()
    herringbone()
    coil()
    _convoy_dismount("soft_dismount", False)
    _convoy_dismount("hard_dismount", True)
    print("figures -> %s" % OUT)


if __name__ == "__main__":
    main()
