"""Rebuild the tsigns / jmfsb sign sets to the sign_style_guide.json board style.

Reads nothing from the old signs except, for the handful whose content IS a
screenshot, a cropped figure lifted out of the original PNG. Everything else is
drawn from the SIGNS spec below.

    python tools/gen_signs.py

Writes PNG masters to addons/media/images/signs_v2/ and converts each to PAA.
"""
import io, os, glob, math, random, subprocess, sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "addons", "media", "images")
OUT = os.path.join(IMG, "signs_v2")
LOGO = os.path.join(ROOT, "art", "JMSB-crossed-arrows-G", "512", "jmsb-crossed-arrows-G-clean-512.png")
ART = os.path.join(ROOT, "tools", "art", "signs")   # swatches lifted from the last good boards
ORIG = os.environ.get("JMFSB_SIGN_ORIG", "")   # folder of old signs converted to PNG

W, H = 2048, 1024

# ---- palette: the unit's ranger green and tan (the G logo rebrand, 2026-10-08;
# user, 2026-10-10: "all these signs need redone to fit the new unit and colour
# scheme"). Names kept from the old brown board so the drawing code reads the same.
BROWN_MARGIN = (0x15, 0x19, 0x12)   # outer edge, darker than the face
BROWN_FACE   = (0x20, 0x26, 0x1C)   # dark green
FRAME_PALE   = (0xC2, 0xA8, 0x78)   # tan frame and title rule
EMBER        = (0xC2, 0xA8, 0x78)   # tan eyebrow / section headings
AMBER        = (0xC2, 0xA8, 0x78)   # tan designations
BONE         = (0xE9, 0xE4, 0xD3)   # paper - titles and body text
SLATE        = (0xA9, 0xAE, 0x95)   # sage - sub-lines and footer
WOOD_RULE    = (0x3A, 0x44, 0x33)   # ranger green footer rule
WARN         = (0xD0, 0x6A, 0x4A)   # a bind still to be set

F_BLACK = r"C:\Windows\Fonts\ariblk.ttf"
F_BOLD  = r"C:\Windows\Fonts\arialbd.ttf"
F_REG   = r"C:\Windows\Fonts\arial.ttf"
F_MONO  = r"C:\Windows\Fonts\consolab.ttf"

MARGIN = 96
EYEBROW_Y, TITLE_Y, SUBLINE_Y = 88, 140, 262
DIVIDER_Y, ROWS_Y = 336, 382
FOOTER_DIV_Y, FOOTER_Y = 872, 896
BADGE_SIZE, BADGE_X, BADGE_Y = 252, W - 96 - 252, 62

EYEBROW = "1ST JOINT MULTI-FUNCTIONAL STRIKE BATTALION - TRAINING AREA"
BODY_BOTTOM = FOOTER_DIV_Y - 16    # nothing in the body may reach past this

_fc = {}
def font(path, size):
    key = (path, size)
    if key not in _fc:
        _fc[key] = ImageFont.truetype(path, size)
    return _fc[key]


def tw(d, s, f):
    return d.textbbox((0, 0), s, font=f)[2]


# ---------------------------------------------------------------------------
# board
# ---------------------------------------------------------------------------
def board():
    im = Image.new("RGB", (W, H), BROWN_MARGIN)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([14, 14, 2034, 1010], radius=26, fill=FRAME_PALE)
    d.rounded_rectangle([30, 30, 2018, 994], radius=18, fill=BROWN_FACE)

    # wood grain: barely-there vertical strokes, fixed seed so rebuilds match
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    rnd = random.Random(7)
    cols = [(0, 0, 0, 10), (0, 0, 0, 14), (200, 210, 180, 6)]
    for _ in range(260):
        x = rnd.randint(40, W - 40)
        y = rnd.randint(40, H - 40)
        ln = rnd.randint(60, 320)
        wd = rnd.randint(1, 3)
        gd.line([(x, y), (x + rnd.randint(-6, 6), min(y + ln, H - 36))],
                fill=rnd.choice(cols), width=wd)
    im.paste(Image.alpha_composite(im.convert("RGBA"), g).convert("RGB"), (0, 0))
    return im


def badge(im):
    lg = Image.open(LOGO).convert("RGBA").resize((BADGE_SIZE, BADGE_SIZE), Image.LANCZOS)
    im.paste(lg, (BADGE_X, BADGE_Y), lg)


def header(im, d, title, sub=None, eyebrow=None):
    d.text((MARGIN, EYEBROW_Y), (eyebrow or EYEBROW).upper(), font=font(F_BOLD, 40), fill=EMBER)
    size = 96
    avail = W - MARGIN - MARGIN - BADGE_SIZE - 48
    while size > 56 and tw(d, title.upper(), font(F_BLACK, size)) > avail:
        size -= 4
    d.text((MARGIN, TITLE_Y + (96 - size) // 2), title.upper(), font=font(F_BLACK, size), fill=BONE)
    if sub:
        d.text((MARGIN, SUBLINE_Y), sub, font=font(F_BOLD, 44), fill=SLATE)
    d.line([(MARGIN, DIVIDER_Y), (W - MARGIN, DIVIDER_Y)], fill=FRAME_PALE, width=4)


def footer(im, d, text):
    if not text:
        return
    d.line([(MARGIN, FOOTER_DIV_Y), (W - MARGIN, FOOTER_DIV_Y)], fill=WOOD_RULE, width=3)
    d.text((MARGIN, FOOTER_Y), text, font=font(F_BOLD, 38), fill=SLATE)


def rows(im, d, items):
    """items: [designation, description] pairs; description may be ''."""
    n = len(items)
    compact = n >= 7
    step = min(64 if compact else 118, (BODY_BOTTOM - 40 - ROWS_Y) / max(n, 1))
    y = ROWS_Y
    if not compact and step * n < (BODY_BOTTOM - 60 - ROWS_Y):
        y += (BODY_BOTTOM - 60 - ROWS_Y - step * n) / 2
    fd = font(F_BLACK, 40 if compact else 52)
    fr = font(F_REG, 36 if compact else 46)
    for des, desc in items:
        d.text((MARGIN, y), des, font=fd, fill=AMBER)
        if desc:
            x = MARGIN + tw(d, des, fd) + 36
            d.text((x, y + 8), "- " + desc, font=fr, fill=BONE)
        y += step


def tracer_dots(d):
    """The seven tracer colours, bottom right of the footer: what every load
    in the arsenal also comes as."""
    cols = [(0xD3, 0x3B, 0x2F), (0xE8, 0xD2, 0x3A), (0x4C, 0xAF, 0x50), (0xEE, 0xEE, 0xEE),
            (0x3D, 0x7D, 0xE0), (0xEE, 0x82, 0x2C)]
    r, gap = 14, 46
    x = W - MARGIN - gap * 6 - r
    y = FOOTER_Y + 22
    for c in cols:
        d.ellipse([x - r, y - r, x + r, y + r], fill=c, outline=BROWN_MARGIN, width=2)
        x += gap
    d.ellipse([x - r, y - r, x + r, y + r], outline=(0x7C, 0xD3, 0x7F), width=3)
    f = font(F_BOLD, 13)
    d.text((x - tw(d, "IR", f) / 2, y - 8), "IR", font=f, fill=(0x7C, 0xD3, 0x7F))


def ammo_cols(im, d, columns):
    """Two lists side by side under their own headings, a rule between them."""
    gap = 72
    col_w = (W - 2 * MARGIN - gap) // len(columns)
    fh, fd, fr = font(F_BLACK, 44), font(F_BLACK, 32), font(F_REG, 29)
    for c, (heading, items) in enumerate(columns):
        x0 = MARGIN + c * (col_w + gap)
        y = ROWS_Y
        d.text((x0, y), heading, font=fh, fill=EMBER)
        y += 74
        step = min(56, (BODY_BOTTOM - y) / max(len(items), 1))
        for des, desc in items:
            d.text((x0, y), des, font=fd, fill=AMBER)
            d.text((x0 + tw(d, des, fd) + 24, y + 4), "- " + desc, font=fr, fill=BONE)
            y += step
        if c:
            d.line([(x0 - gap // 2, ROWS_Y), (x0 - gap // 2, BODY_BOTTOM - 20)], fill=WOOD_RULE, width=3)


def figure(im, box, src):
    """Paste a crop of the original sign into the body area, letterboxed."""
    if not (ORIG and os.path.exists(src)):
        return False
    fig = Image.open(src).convert("RGB").crop(box)
    bx0, by0, bx1, by1 = MARGIN, DIVIDER_Y + 20, W - MARGIN, 986
    scale = min((bx1 - bx0) / fig.width, (by1 - by0) / fig.height)
    fig = fig.resize((int(fig.width * scale), int(fig.height * scale)), Image.LANCZOS)
    im.paste(fig, (bx0 + ((bx1 - bx0) - fig.width) // 2,
                   by0 + ((by1 - by0) - fig.height) // 2))
    return True


def uniform(im, d, name, swatch):
    """Uniform-of-the-day board: pattern name on the left, camo swatch right.

    The swatch is lifted straight out of the old sign -- it is a photo of the
    real pattern, so redrawing it is not an option.
    """
    box_w = 420
    x0 = W - MARGIN - box_w
    y0 = ROWS_Y + 18
    if swatch:
        src, crop = swatch
        if src and os.path.exists(src):
            sw = Image.open(src).convert("RGB")
            if crop:
                sw = sw.crop(crop)
            sw = sw.resize((box_w, box_w), Image.LANCZOS)
            im.paste(sw, (x0, y0))
            d.rectangle([x0 - 3, y0 - 3, x0 + box_w + 2, y0 + box_w + 2], outline=FRAME_PALE, width=3)
    size = 96
    avail = x0 - MARGIN - 64
    while size > 48 and tw(d, name.upper(), font(F_BLACK, size)) > avail:
        size -= 4
    f = font(F_BLACK, size)
    d.text((MARGIN, y0 + (box_w - size) // 2 - 10), name.upper(), font=f, fill=AMBER)


def side_figure(im, d, src):
    """A screenshot standing down the right edge of the body - the panels the
    board is explaining, at the size a poster would print them. The source
    lives in addons/media/images, not JMFSB_SIGN_ORIG - it is new material,
    not a crop of an old sign."""
    if not os.path.exists(src):
        return
    fig = Image.open(src).convert("RGB")
    by0, by1 = DIVIDER_Y + 20, BODY_BOTTOM - 8
    scale = min((by1 - by0) / fig.height, 420 / fig.width)
    fig = fig.resize((int(fig.width * scale), int(fig.height * scale)), Image.LANCZOS)
    x = W - MARGIN - fig.width
    y = by0 + ((by1 - by0) - fig.height) // 2
    im.paste(fig, (x, y))
    d.rectangle([x - 3, y - 3, x + fig.width + 2, y + fig.height + 2], outline=FRAME_PALE, width=3)


def keycols(im, d, columns):
    """Keybind board: side-by-side columns, each a heading over label / key rows,
    the key right-aligned in a monospace face. A key starting with "!" is
    drawn in WARN - a bind the player still has to set."""
    gap = 72
    col_w = (W - 2 * MARGIN - gap) // len(columns)
    fh, fl, fk = font(F_BOLD, 48), font(F_REG, 40), font(F_MONO, 38)
    for c, (heading, items) in enumerate(columns):
        x0 = MARGIN + 24 + c * (col_w + gap)
        x1 = x0 + col_w - 48
        y = ROWS_Y + 4
        d.text((x0, y), heading.upper(), font=fh, fill=EMBER)
        y += 68
        for label, key in items:
            warn = key.startswith("!")
            key = key.lstrip("!")
            d.text((x0, y), label, font=fl, fill=BONE)
            d.text((x1 - tw(d, key, fk), y + 2), key, font=fk, fill=WARN if warn else AMBER)
            y += 58


def sections(im, d, blocks):
    """Two or more headed blocks stacked down the face.

    blocks: [(heading, note, [[designation, description], ...]), ...]
    """
    n_rows = sum(len(b[2]) for b in blocks)
    n_head = len(blocks)
    span = BODY_BOTTOM - ROWS_Y
    head_h = 66
    step = min(58, (span - head_h * n_head - 18 * (n_head - 1)) / max(n_rows, 1))
    fh = font(F_BLACK, 44)
    fn = font(F_BOLD, 32)
    fd = font(F_BLACK, 38)
    fr = font(F_REG, 34)
    y = ROWS_Y
    for heading, note, items in blocks:
        d.text((MARGIN, y), heading.upper(), font=fh, fill=EMBER)
        if note:
            d.text((MARGIN + tw(d, heading.upper(), fh) + 28, y + 12), note, font=fn, fill=SLATE)
        y += head_h
        for des, desc in items:
            d.text((MARGIN + 24, y), des, font=fd, fill=AMBER)
            if desc:
                d.text((MARGIN + 24 + tw(d, des, fd) + 28, y + 4), "- " + desc, font=fr, fill=BONE)
            y += step
        y += 18


def centred_title(im, d, lines, eyebrow=None):
    """Wayfinding sign: eyebrow at the top, the name large and centred."""
    d.text((MARGIN, EYEBROW_Y), (eyebrow or EYEBROW).upper(), font=font(F_BOLD, 40), fill=EMBER)
    d.line([(MARGIN, DIVIDER_Y), (W - MARGIN, DIVIDER_Y)], fill=FRAME_PALE, width=4)
    size = 190
    avail = W - MARGIN * 2
    top_limit = DIVIDER_Y + 30
    avail_h = BODY_BOTTOM - top_limit
    while size > 60:
        if (max(tw(d, l.upper(), font(F_BLACK, size)) for l in lines) <= avail
                and int(size * 1.18) * len(lines) <= avail_h):
            break
        size -= 4
    lh = int(size * 1.18)
    block = lh * len(lines)
    top = top_limit + (avail_h - block) // 2
    for i, l in enumerate(lines):
        f = font(F_BLACK, size)
        d.text(((W - tw(d, l.upper(), f)) // 2, top + i * lh), l.upper(), font=f, fill=BONE)


# ---------------------------------------------------------------------------
# content
# ---------------------------------------------------------------------------
def T(lines, sub=None, foot=None):
    return {"kind": "title", "lines": lines, "sub": sub, "foot": foot}

def R(title, items, sub=None, foot=None):
    return {"kind": "rows", "title": title, "items": items, "sub": sub, "foot": foot}

def S(title, blocks, sub=None, foot=None, fig=None):
    return {"kind": "sections", "title": title, "blocks": blocks, "sub": sub, "foot": foot, "fig": fig}

def U(name, src, box, foot=None, local=False):
    """local=True reads src from addons/media/images (repo material), local="art"
    from tools/art/signs (swatches lifted from the last good boards, the old
    converted signs being gone), else the JMFSB_SIGN_ORIG folder."""
    return {"kind": "uniform", "name": name, "src": src, "box": box, "foot": foot, "local": local}

def K(title, columns, foot=None):
    return {"kind": "keys", "title": title, "columns": columns, "foot": foot}

def FIG(title, src, box, sub=None, foot=None):
    return {"kind": "figure", "title": title, "src": src, "box": box, "sub": sub, "foot": foot}

RANGE_FOOT = "Fire only on a hot range - check your lane before you go loud"

SIGNS = {
    # ---- distance markers -------------------------------------------------
    "200":  T(["200", "Meters"]),
    "400":  T(["400", "Meters"]),
    "600":  T(["600", "Meters"]),
    "800":  T(["800", "Meters"]),
    "1000": T(["1000", "Meters"]),
    "1200": T(["1200", "Meters"]),

    # ---- ranges and courses ----------------------------------------------
    "wep":   T(["Weapons", "Range"], foot=RANGE_FOOT),
    "wepa":  T(["Weapons Range", "Alpha"], foot=RANGE_FOOT),
    "wepb":  T(["Weapons Range", "Bravo"], foot=RANGE_FOOT),
    "wepc":  T(["Weapons Range", "Charlie"], foot=RANGE_FOOT),
    "wepd":  T(["Weapons Range", "Delta"], foot=RANGE_FOOT),
    "wepe":  T(["Weapons Range", "Echo"], foot=RANGE_FOOT),
    "mg":    T(["Machinegun", "Range"], foot=RANGE_FOOT),
    "ugl":   T(["UGL", "Range"], foot=RANGE_FOOT),
    "cqb1":  T(["CQB", "Shoot House #1"]),
    "cqb2":  T(["CQB", "Shoot House #2"]),
    "cqb3":  T(["CQB", "Shoot House #3"]),
    "cqb4":  T(["CQB", "Shoot House #4"]),
    "cqb5":  T(["CQB", "Shoot House #5"]),
    "eng":   T(["Engineering", "Course"]),
    "medc":  T(["Medical", "Course"]),
    "mff":   T(["Military Freefall", "Course"]),
    "mount": T(["MOUT", "Course"]),
    "uoc":   T(["Underwater Operations", "Course"]),

    # ---- facilities -------------------------------------------------------
    "as":   T(["Air Vehicle", "Spawner"]),
    "gs":   T(["Ground Vehicle", "Spawner"]),
    "ss":   T(["Sea Vehicle", "Spawner"]),
    "toc":  T(["TOC"], sub="Tactical Operations Centre"),
    "bolo": T(["Camp BOLO"], foot="Please do not feed the recruits."),
    "taa":  T(["Training Area", "Altis"]),
    "tam":  T(["Training Area", "Malden"]),
    "tas":  T(["Training Area", "Stratis"]),

    # ---- branding ---------------------------------------------------------
    "jmfsbsign":        T(["1st Joint Multi-Functional Strike Battalion"]),
    "jmfsbbsimplesign": T(["1st Joint Multi-Functional Strike Battalion"]),
    "gbbanner3":        T(["1st Joint Multi-Functional Strike Battalion"]),

    # ---- uniform of the day ----------------------------------------------
    "mcw":  U("Multicam Woodland",     "mcw.png",  None, local="art"),
    # swatch cut from the official pattern art the user supplied - same
    # 210px source width as every other cut so the pattern scale matches
    "mtp":  U("Multicam / MTP",        "mtp_swatch.png",  None, local=True),
    "mtpa": U("Multicam Desert / Arid","mtpa.png", None, local="art"),
    "mypt": U("Multicam Tropic",       "mypt.png", None, local="art"),
    # swatch cut from the CTRG OCP uniform texture and kept in the repo -
    # there was never an old OCP sign to lift one from
    "ocp":  U("OCP",                   "ocp_swatch.png",  None, local=True),

    # ---- information boards ----------------------------------------------
    "patrol_base": S("Staging Zones & Patrol Bases", [
        ("Staging Zone", "you get a pop-up when you are stood in one", [
            ["Arsenal", "ACE self-interact - gear and loadout"],
            ["Element Menu", "ACE self-interact"],
            ["Kit is saved", "loadout and roster gear stored when you close any inventory"],
            ["Also here", "view distance, TP menu and vehicle customisation"],
        ]),
        ("Patrol Base", "anyone can build one - no rank needed", [
            ["Kits", "carry a Patrol Base Kit (sand or olive), drop 4 within 3 m"],
            ["Build", "on foot, ACE self-interact - Establish Patrol Base, then name it"],
            ["You get", "a beacon, a 15 m staging zone and a teleport point"],
            ["Unbuild", "action on the beacon - recovers every kit"],
            ["Limit", "3 patrol bases at once"],
        ]),
    ], foot="Outside a staging zone none of the self-interact options appear"),

    "bodies": R("Enemy Bodies", [
        ["DO NOT", "take their clothes, weapons, or virginity's"],
        ["DO", "check for a pulse before you move on"],
        ["DO", "flex-cuff any survivor, then carry on with the mission"],
    ], sub="Handling enemy dead and wounded"),

    "gtk": R("Good to Know", [
        ["VS-17", "portable helipad - deploy with ACE self-interact"],
        ["View Distance", "ACE self-interact, staging areas only"],
        ["Night Vision", "colour filter under CBA settings"],
        ["TP Menu", "ACE self-interact, staging areas only"],
        ["Vehicle Customisation", "ACE self-interact, staging areas only"],
        ["NVG Brightness", "ALT + Page Up / Page Down"],
        ["Laser Code", "CTRL + ALT + Q up, CTRL + ALT + E down"],
    ], foot="Always remember to pillage BEFORE you burn"),

    "good2know": R("Good to Knows", [
        ["Hypoxia", "above 4000 ft you need a HALO mask"],
        ["Boo Boo Bag", "an IFAK - open it with ACE self-interact"],
        ["VS-17", "portable helipad - AI may or may not land on it"],
        ["View Distance", "the \ key, or CTRL + [ and CTRL + ] to step it"],
        ["NVG Brightness", "ALT + Page Up / Page Down"],
        ["Laser Code", "CTRL + ALT + Q up, CTRL + ALT + E down"],
        ["Vector Marker", "CTRL + SHIFT + M - marks your target for everyone"],
        ["Vector Waypoint", "CTRL + SHIFT + N - a waypoint only you can see"],
        ["Timers", "ACE self-interact - Set Timer - 1, 2, 3 or 5 minutes"],
    ], sub="Timers ring for everyone carrying a scanner - silence yours with the alarm key",
       foot="Always remember to pillage BEFORE you burn"),

    "jmfsbroles": R("Pick Role", [
        ["Communications", ""],
        ["Breacher", ""],
        ["Combat Life Saver", ""],
        ["Just a Grunt", "everyone else"],
    ], sub="Advanced skills are assigned by the mod or a server admin",
       foot="Pick before the briefing - the roster closes at step-off"),

    "jmfsbbtime": R("Operation Timeline", [
        ["OP - 30", "leaders on, map loaded, mission ready"],
        ["OP + 01", "you are late - load your kit, help others, sit down"],
        ["OP + 05", "sections balanced, everyone seated for the briefing"],
        ["OP + 06", "briefing and questions"],
        ["OP + 15", "step off - if you are late, you are walking"],
    ], foot="We don't want to be hard asses about it - just don't waste everyone else's time"),

    "go": R("Operation Timeline", [
        ["OP - 30", "leaders on, map loaded, mission ready"],
        ["OP + 01", "you are late - load your kit, help others, sit down"],
        ["OP + 05", "sections balanced, everyone seated for the briefing"],
        ["OP + 06", "briefing and questions"],
        ["OP + 15", "step off - if you are late, you are walking"],
    ], foot="We don't want to be hard asses about it - just don't waste everyone else's time"),

    "jmfsbcallsign": R("Callsigns", [
        ["G", "JMSB - always the first letter"],
        ["S", "1-4 squad, 5 Pl XO, 6 Pl Leader, 7 Pl JFIRE, 8 Pl Medic"],
        ["S", "91 Engineers, 92 Scout Team"],
        ["T", "A-D fireteam, 5 Sqd XO, 6 Sqd Leader, 7 JFIRE, 8 Medic"],
        ["G-91", "engineer team member"],
        ["G-6", "platoon leader"],
        ["G-3-A", "3rd squad, alpha team"],
    ], sub="G - S - T   -   JMSB, squad, team"),

    "access": R("To Access the Arsenal", [
        ["1", "ACE self-interact"],
        ["2", "open the Group Menu and select a role"],
        ["3", "ACE self-interact - Arsenal is now listed"],
    ], sub="The Arsenal only appears once you hold a role"),

    "ctab": R("cTab", [
        ["Line 1", "grid your cursor is pointing at"],
        ["Line 2", "ASL altitude your cursor is pointing at"],
        ["Line 3", "distance to where your cursor is pointing"],
        ["Line 4", "direction to where your cursor is pointing"],
        ["F1 / F4", "map options / messaging"],
    ], sub="S7 Android for everyone  -  rugged tablet for leaders",
       foot="Open the tablet or android with H"),

    "tacpad": S("Custom Info & Tacpad", [
        ("On Your Screen", "", [
            ["[ ]", "left / right custom info - cycle what each side shows"],
            ["Shift + [ ]", "show the new UI readouts, left / right"],
            ["Alt + [ ]", "cycle the tiles - squad, EW, drones, jamming, radio, timer"],
        ]),
        ("On The Map", "open the map - the whole UI is drawn on it", [
            ["Live Tiles", "the top band - press one and its app opens full size"],
            ["TAC//MSG", "the reader - nets, threads and line-report templates"],
            ["TAC//SUPPORT", "task ALiVE transport, CAS and artillery - JFO holds it"],
        ]),
    ], fig="hud_panels.png",
       foot="Every key is rebindable - CBA controls, under 1st Joint Multi-Functional Strike Battalion"),

    "viewd": R("View Distance", [
        ["Backslash", "default keybind for the view distance menu"],
        ["ACE", "also available under ACE self-interact"],
        ["Foot / Car / Air", "each has its own view and object distance"],
    ], sub="Set it in staging - not mid-contact"),

    # the two Controls screenshots ARE the content here - keep them
    # both boards carry the same binds: keybinds.paa had been blank since its
    # source screenshot went; jmfsbkeys was the hand-made brown board
    "keybinds": K("Keybinds", [
        ("1st JMSB", [
            ("Send TIC  (whole side)", "Ctrl+Shift+T"),
            ("Vector: Place Target Marker", "Ctrl+Shift+M"),
            ("Signal Scanner", "Ctrl+U"),
            ("Scanner Stopwatch", "Ctrl+Alt+U"),
            ("Scanner Alarm", "Ctrl+Shift+U"),
            ("Clear Scanner Alarms", "!UNBOUND - SET IT"),
            ("Point Direction (vehicle)", "ACE finger key"),
        ]),
        ("View Distance", [
            ("View Distance Menu", "\\"),
            ("Preset 1 / 2 / 3", "Shift/Ctrl/Alt+\\"),
            ("Raise View Distance", "Ctrl+]"),
            ("Lower View Distance", "Ctrl+["),
        ]),
    ], foot="Set in: Options > Controls > Configure Addons (CBA)"),
    "jmfsbkeys": K("Keybinds", [
        ("1st JMSB", [
            ("Send TIC  (whole side)", "Ctrl+Shift+T"),
            ("Vector: Place Target Marker", "Ctrl+Shift+M"),
            ("Signal Scanner", "Ctrl+U"),
            ("Scanner Stopwatch", "Ctrl+Alt+U"),
            ("Scanner Alarm", "Ctrl+Shift+U"),
            ("Clear Scanner Alarms", "!UNBOUND - SET IT"),
            ("Point Direction (vehicle)", "ACE finger key"),
        ]),
        ("View Distance", [
            ("View Distance Menu", "\\"),
            ("Preset 1 / 2 / 3", "Shift/Ctrl/Alt+\\"),
            ("Raise View Distance", "Ctrl+]"),
            ("Lower View Distance", "Ctrl+["),
        ]),
    ], foot="Set in: Options > Controls > Configure Addons (CBA)"),

    "markers": R("Marker Tree", [
        ["Enemy SALUTE", "infantry, motorised, armour, air, mine, IED"],
        ["Medical", "casualty collection, MEDEVAC pickup, regroup"],
        ["General", "observation post, sniper, target reference point"],
        ["Command & Control", "HQ, LZ, dot or circle with label"],
        ["Manoeuvre", "control point, rally point, breach, start point"],
        ["Sustainment", "ammo, fuel, water, vehicle recovery"],
    ], sub="Placed from the tablet map - each branch opens a submenu"),

    "marker_range": R("Markers from Range Finders", [
        ["1", "point and use the rangefinder"],
        ["2", "choose the marker from the menu"],
        ["Vector", "ACE3 vector - Tab + R"],
        ["Rangefinder", "vehicle or Arma 3 rangefinder - T"],
    ], sub="On a cTab the menu opens automatically on the coordinates",
       foot="In game, open the tablet or android with H"),
}


def render(name, spec):
    im = board()
    d = ImageDraw.Draw(im)
    badge(im)
    if spec["kind"] == "title":
        centred_title(im, d, spec["lines"])
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "sections":
        header(im, d, spec["title"], spec.get("sub"))
        sections(im, d, spec["blocks"])
        if spec.get("fig"):
            side_figure(im, d, os.path.join(IMG, spec["fig"]))
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "uniform":
        header(im, d, "Uniform of the Day")
        uniform(im, d, spec["name"], (
            os.path.join({True: IMG, "art": ART}.get(spec.get("local"), ORIG), spec["src"]), spec["box"]
        ))
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "keys":
        header(im, d, spec["title"])
        keycols(im, d, spec["columns"])
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "rows":
        header(im, d, spec["title"], spec.get("sub"))
        rows(im, d, spec["items"])
        footer(im, d, spec.get("foot"))
        if spec.get("dots"):
            tracer_dots(d)
    elif spec["kind"] == "ammo2":
        header(im, d, spec["title"], spec.get("sub"))
        ammo_cols(im, d, spec["columns"])
        footer(im, d, spec.get("foot"))
    else:
        header(im, d, spec["title"], spec.get("sub"))
        figure(im, spec["box"], os.path.join(ORIG, spec["src"]))
        footer(im, d, spec.get("foot"))
    return im


# THE FA AMMO BOARDS (fa_main/data/fa_sign_*.paa), placed at the ranges by the
# missions. They were hand-made in the old brown Ghosts of Battle style; same
# words now, on the unit board, the arsenal tag as it is today ([JMSB]).
# PNG masters go to tools/art/signs/fa (never shipped), PAAs into fa_main.
FA_OUT = os.path.join(ROOT, "tools", "art", "signs", "fa")
FA_PAA = os.path.join(ROOT, "addons", "fa_main", "data")
FA_SIGNS = {
    "fa_sign_40mm": dict(R("40mm UGL - Smart Payloads", [
        ["Mk364 PAB", "programmable airburst · counter-drone · HE on impact"],
        ["Mk389 TBK", "tungsten buckshot (+ subsonic load)"],
        ["Mk380 NR-P", "network relay · extends the squad data-link"],
        ["Mk383 EMP-M", "soft-kill EW burst · drones, optics, comms"],
        ["Mk384 M-SMK", "multispectral smoke · blocks visual + thermal"],
        ["Mk385 DCOY", "IR / RF decoy · baits loitering munitions"],
        ["Mk386 UGS", "unattended ground sensor · contact picket"],
        ["Mk388 JAM", "area comms / GNSS jammer bubble"],
    ], sub="any 40mm UGL · 3GL / EGLM / GL · range: ACE zeroing or PgUp / PgDn",
        foot="Carriers pop a chute at apex and deploy on landing · Mk364 range: CBA keybind or ACE self-interact")),
    "fa_sign_65_mx": dict(R("6.5x39 Caseless - MX Rifles", [
        ["Mk330 EPR", "standard tungsten-core ball (2035)"],
        ["Mk331 AP", "tungsten armor-piercing (2040)"],
        ["Mk328 HV / Mk329 LR", "match and long-range DMR loads"],
        ["XM892 / XM893 CTEP", "cased-telescoped 2-stage penetrator (2039)"],
        ["Mk367 PAB", "proximity airburst · counter-drone"],
    ], sub="MX  ·  MXC  ·  MX 3GL  ·  MX SW  ·  MXM",
        foot="All loads plain + 7 tracer colours · look for the [JMSB] tag in the arsenal"), dots=True),
    "fa_sign_jca_556": dict(R("JCA 5.56x45 - M4A4 / HK433", [
        ["Mk327 HV", "hybrid-case hypervelocity ball (2033)"],
        ["XM891 CTEP", "cased-telescoped tungsten EPR (2039)"],
        ["Mk332 AP", "tungsten armor-piercing (2040)"],
        ["Mk361 PAB", "proximity airburst · counter-drone"],
        ["Mk368K AD", "8-pellet drone shot · eff. 100 m"],
        ["Mk368L AD", "5-pellet drone shot · eff. 200 m"],
    ], sub="EMAG & PMAG bodies · black · sand · green PMAG",
        foot="Every JCA 5.56 magazine body carries all loads · [JMSB] tag in the arsenal"), dots=True),
    "fa_sign_jca_762": dict(R("JCA 7.62x51 - SR-10", [
        ["M80A2 HV", "hybrid-case 135gr tungsten EPR (2032)"],
        ["XM751 CTEP", "cased-telescoped · long-range / anti-armor (2039)"],
        ["Mk362 PAB", "proximity airburst · counter-drone"],
        ["Mk369K AD", "12-pellet drone shot · eff. 150 m"],
        ["Mk369L AD", "10-pellet drone shot · eff. 250 m"],
    ], sub="20Rnd PMAG · black and sand bodies",
        foot="All tracer colours on both bodies · [JMSB] tag in the arsenal"), dots=True),
    "fa_sign_nato_rockets": {
        "kind": "ammo2", "title": "NATO Rockets - MAAWS / Titan",
        "sub": "MAAWS Mk4 (84mm recoilless)  ·  Titan MPRL (shoulder missiles)",
        "foot": "Seekers need a lock tone · Copperhead loiters if fired unlocked · HE 448: Mk364 keybind",
        "columns": [
            ("MAAWS Mk4 - 84mm", [
                ["HEAT 758 TT", "FnF top-attack tandem · 1.2 km"],
                ["HEAT 665 CS", "heavy tandem · enclosure-safe"],
                ["HE 448 AB", "prefrag HE · airburst · 1.5 km"],
                ["GM 841", "laser-homing · lase and fire · 2 km"],
                ["ADM 484 PROX", "C-UAS proximity frag · 600 m"],
                ["ADM 486 CAN", "flechette canister · swarms · 150 m"],
                ["ADM 487 SEEK", "IR FnF vs locked drone · 1 km"],
                ["AAM 517 SR", "VSHORAD · lock tone · 1.75 km"],
            ]),
            ("Titan MPRL - shoulder", [
                ["BGM-185 Broadsword", "FnF top-attack ATGM · 10 km"],
                ["XM1200 Copperhead", "loitering munition · 40 km"],
                ["MIM-165 Sentry", "dual-seeker SAM · jets to drones · 12 km"],
                ["MIM-166 Roadrunner", "C-UAS hard-kill · 4 km"],
            ]),
        ],
    },
}


# folder -> (eyebrow, drop the words "training area" from titles too)
VARIANTS = [
    ("signs_v2",       "1ST JOINT MULTI-FUNCTIONAL STRIKE BATTALION - TRAINING AREA", False),
    ("signs_v2_plain", "1ST JOINT MULTI-FUNCTIONAL STRIKE BATTALION",                 True),
]


def strip_area(spec):
    """Same board with every mention of the training area taken out."""
    if spec["kind"] != "title":
        return spec
    lines = [l for l in spec["lines"] if l.strip().lower() != "training area"]
    if not lines:                       # e.g. a board that was only that phrase
        lines = spec["lines"]
    out = dict(spec)
    out["lines"] = lines
    return out


def main():
    global EYEBROW, OUT
    for folder, eyebrow, plain in VARIANTS:
        EYEBROW = eyebrow
        OUT = os.path.join(IMG, folder)
        os.makedirs(OUT, exist_ok=True)
        made = []
        for name, spec in sorted(SIGNS.items()):
            if plain:
                spec = strip_area(spec)
            p = os.path.join(OUT, name + ".png")
            render(name, spec).save(p)
            made.append(p)
        print("%d PNG masters -> %s" % (len(made), OUT))
        if "--paa" in sys.argv:
            for p in made:
                paa = p[:-4] + ".paa"
                if os.path.exists(paa):
                    os.remove(paa)
                subprocess.run(["hemtt", "utils", "paa", "convert", p, paa],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("  converted to PAA")

    EYEBROW = "1ST JOINT MULTI-FUNCTIONAL STRIKE BATTALION"
    os.makedirs(FA_OUT, exist_ok=True)
    for name, spec in sorted(FA_SIGNS.items()):
        p = os.path.join(FA_OUT, name + ".png")
        render(name, spec).save(p)
        if "--paa" in sys.argv:
            paa = os.path.join(FA_PAA, name + ".paa")
            if os.path.exists(paa):
                os.remove(paa)
            subprocess.run(["hemtt", "utils", "paa", "convert", p, paa],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("%d FA ammo boards -> %s" % (len(FA_SIGNS), FA_PAA if "--paa" in sys.argv else FA_OUT))


if __name__ == "__main__":
    main()
