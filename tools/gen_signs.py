"""Rebuild the tsigns / jmfsb sign sets to the sign_style_guide.json board style.

Reads nothing from the old signs except, for the handful whose content IS a
screenshot, a cropped figure lifted out of the original PNG. Everything else is
drawn from the SIGNS spec below.

    python tools/gen_signs.py

Writes PNG masters to art/signs_v2/ (and art/signs_v2_plain/) and, with --paa,
converts each to PAA in addons/media/images/signs_v2[_plain]/.
"""
import io, os, glob, math, random, subprocess, sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "addons", "media", "images")
OUT = os.path.join(ROOT, "art", "signs_v2")   # PNG masters; main() sets it per variant
LOGO = os.path.join(ROOT, "art", "JMSB-crossed-arrows-G", "512", "jmsb-crossed-arrows-G-clean-512.png")
ART = os.path.join(ROOT, "art", "signs")   # swatches lifted from the last good boards
ORIG = os.environ.get("JMFSB_SIGN_ORIG", "")   # folder of old signs converted to PNG
# --only name1,name2: render just those boards (and no FA boards)
ONLY = set(sys.argv[sys.argv.index("--only") + 1].split(",")) if "--only" in sys.argv else set()

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
MARKER       = (0xB3, 0x26, 0x1E)   # the device diagrams' numbered callouts

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


def steps(im, d, items):
    """Numbered steps side by side, each a caption over a screenshot. items =
    [(caption, file in art/signs)]; the shots keep their shape, all at one
    height, spread across the body."""
    fn_, fc = font(F_BLACK, 60), font(F_BOLD, 30)
    top, bottom = ROWS_Y + 62, BODY_BOTTOM - 4
    shots = [Image.open(os.path.join(ART, f)).convert("RGB") for _, f in items]
    h = bottom - top
    shots = [sh.resize((int(sh.width * h / sh.height), h), Image.LANCZOS) for sh in shots]
    gap = (W - 2 * MARGIN - sum(sh.width for sh in shots)) / max(len(shots) - 1, 1)
    x = MARGIN
    for i, ((caption, _), sh) in enumerate(zip(items, shots)):
        d.text((x, ROWS_Y - 6), str(i + 1), font=fn_, fill=AMBER)
        cap, room = caption.upper(), sh.width - 52
        if tw(d, cap, fc) <= room:
            d.text((x + 52, ROWS_Y + 12), cap, font=fc, fill=BONE)
        else:   # too wide for its shot: two lines, a size down
            words, f2 = cap.split(), font(F_BOLD, 26)
            cut = max(range(1, len(words)), key=lambda k: -abs(len(" ".join(words[:k])) - len(" ".join(words[k:]))))
            d.text((x + 52, ROWS_Y - 2), " ".join(words[:cut]), font=f2, fill=BONE)
            d.text((x + 52, ROWS_Y + 28), " ".join(words[cut:]), font=f2, fill=BONE)
        im.paste(sh, (int(x), top))
        d.rectangle([x - 3, top - 3, x + sh.width + 2, top + h + 2], outline=FRAME_PALE, width=3)
        x += sh.width + gap


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


def numpad(im, d, keys, legend):
    """The numpad standard drawn as the keypad itself (user, 2026-10-24: "make a
    sign with a numpad saying 1-4 are F1 F2 F3 F4, 0 and . are the arrows, 5-9
    are functions ... set a standard"). keys: label -> (caption, group); the
    pad is the real layout - + and Enter two rows tall, 0 two columns wide.
    legend: [(heading, [(label, key), ...]), ...] down the right."""
    fills = {
        "f":     (FRAME_PALE, BROWN_FACE),   # device F1-F4
        "net":   (FRAME_PALE, BROWN_FACE),   # pick a net
        "arrow": (SLATE, BROWN_FACE),        # device arrows
        "fn":    (WARN, BONE),               # the 5-9 functions
        "voice": (WOOD_RULE, BONE),          # talk keys, volume, open channel
        "lock":  (BROWN_MARGIN, SLATE),      # Num Lock
    }
    # col, row, col span, row span
    layout = {
        "NUM": (0, 0, 1, 1), "/": (1, 0, 1, 1), "*": (2, 0, 1, 1), "-": (3, 0, 1, 1),
        "7": (0, 1, 1, 1), "8": (1, 1, 1, 1), "9": (2, 1, 1, 1), "+": (3, 1, 1, 2),
        "4": (0, 2, 1, 1), "5": (1, 2, 1, 1), "6": (2, 2, 1, 1),
        "1": (0, 3, 1, 1), "2": (1, 3, 1, 1), "3": (2, 3, 1, 1), "ENTER": (3, 3, 1, 2),
        "0": (0, 4, 2, 1), ".": (2, 4, 1, 1),
    }
    x0, y0 = MARGIN + 8, ROWS_Y - 10
    cw, gap = 214, 12
    rh = (BODY_BOTTOM - y0 - 4 * gap) // 5
    fnum, fcap = font(F_BLACK, 52), font(F_BOLD, 24)
    for label, (c, r, cs, rs) in layout.items():
        caption, group = keys.get(label, ("", "lock"))
        bg, ink = fills[group]
        bx = x0 + c * (cw + gap)
        by = y0 + r * (rh + gap)
        bw = cs * cw + (cs - 1) * gap
        bh = rs * rh + (rs - 1) * gap
        d.rounded_rectangle([bx, by, bx + bw, by + bh], radius=12, fill=bg)
        # The key's own legend large on the left, what it does beside it,
        # both centred down the key - so a one-row key never stacks them.
        num = "" if label == "NUM" else ("ENT" if label == "ENTER" else label)
        tx = bx + 16
        if num:
            nf = fnum if len(num) < 3 else font(F_BLACK, 34)
            nb = d.textbbox((0, 0), num, font=nf)
            d.text((tx, by + (bh - (nb[3] - nb[1])) // 2 - nb[1]), num, font=nf, fill=ink)
            tx += (nb[2] - nb[0]) + 18
        lines = caption.split("\n")
        ly = by + (bh - 28 * len(lines)) // 2
        for line in lines:
            d.text((tx, ly), line, font=fcap, fill=ink)
            ly += 28
    # the legend
    lx0 = x0 + 4 * cw + 3 * gap + 72
    lx1 = W - MARGIN - 8
    fh, fl, fk = font(F_BOLD, 40), font(F_REG, 34), font(F_MONO, 34)
    y = ROWS_Y - 6
    for heading, items in legend:
        d.text((lx0, y), heading.upper(), font=fh, fill=EMBER)
        y += 56
        for label, key in items:
            d.text((lx0, y), label, font=fl, fill=BONE)
            d.text((lx1 - tw(d, key, fk), y + 2), key, font=fk, fill=AMBER)
            y += 46
        y += 18


def fkeys(im, d, keys, mods, legend):
    """The F-row layout drawn as the keyboard's F row (user, 2026-11-08: "make a
    new sign also", "keep the old sign" - the numpad board stays). keys: the
    plain row, [(label, caption, group), ...] F1 first, grouped as the keyboard
    is (4 | 2 | 2 | 3). mods: [(row label, [caption per key, F1 first]), ...]
    under it - Shift selects, Ctrl mutes. legend: one line under the rows."""
    fills = {
        "f":     (WARN, BONE),               # device F1-F4
        "arrow": (SLATE, BROWN_FACE),        # page < >
        "fn":    (FRAME_PALE, BROWN_FACE),   # yes / no / action / TIC
        "voice": (WOOD_RULE, BONE),          # voice activate
        "net":   (FRAME_PALE, BROWN_FACE),   # Shift: select net
        "mute":  (BROWN_MARGIN, BONE),       # Ctrl: mute net
    }
    groups = [4, 2, 2, 3]
    label_w, kgap, ggap = 200, 10, 40
    kw = (W - 2 * MARGIN - label_w - kgap * (len(keys) - len(groups)) - ggap * (len(groups) - 1)) // len(keys)
    xs, x, i = [], MARGIN + label_w, 0
    for g in groups:
        for _ in range(g):
            xs.append(x)
            x += kw + kgap
            i += 1
        x += ggap - kgap
    flab, fnum, fcap = font(F_BOLD, 34), font(F_BLACK, 48), font(F_BOLD, 22)

    def key(bx, by, bh, num, caption, group):
        bg, ink = fills[group]
        d.rounded_rectangle([bx, by, bx + kw, by + bh], radius=12, fill=bg)
        ty = by + 12
        if num:
            d.text((bx + (kw - tw(d, num, fnum)) // 2, ty), num, font=fnum, fill=ink)
            ty += 62
        lines = caption.split("\n")
        ly = ty if num else by + (bh - 26 * len(lines)) // 2
        for line in lines:
            d.text((bx + (kw - tw(d, line, fcap)) // 2, ly), line, font=fcap, fill=ink)
            ly += 26

    y, top_h, mod_h, gap = ROWS_Y + 4, 196, 92, 16
    d.text((MARGIN, y + (top_h - 34) // 2), "PRESS", font=flab, fill=EMBER)
    for (label, caption, group), bx in zip(keys, xs):
        key(bx, y, top_h, label, caption, group)
    y += top_h + gap
    for (row, captions), group in zip(mods, ("net", "mute")):
        d.text((MARGIN, y + (mod_h - 34) // 2), row.upper(), font=flab, fill=EMBER)
        for caption, bx in zip(captions, xs):
            key(bx, y, mod_h, "", caption, group)
        y += mod_h + gap
    d.text((MARGIN, y + 4), legend, font=font(F_BOLD, 32), fill=BONE)


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


def devices(im, d, figs, key, plain=False):
    """A device board: the diagrams (art/signs/diag_*.png, from
    tools/gen_device_diagrams.py) along the left at the body's height, and
    the numbered key down the right, its numbers in the diagrams' own red
    callout discs - or, plain, a tan dash each, for pictures with no callouts
    (the radios). Key lines wrap to the room they have, and a short key (the
    simple signs, user 2026-10-23) is set large enough to read from the road."""
    top, bottom = ROWS_Y + 8, BODY_BOTTOM - 8
    h = bottom - top
    x = MARGIN
    for f in figs:
        s = Image.open(os.path.join(ART, f)).convert("RGBA")
        s = s.resize((int(s.width * h / s.height), h), Image.LANCZOS)
        im.paste(s, (int(x), top), s)
        x += s.width + 48
    kx, kw = x + 12, W - MARGIN - x - 12
    n = len(key)
    step = (h - 4) / n
    size = 46 if step >= 100 else (31 if step >= 44 else 27)
    fk, fn = font(F_REG, size), font(F_BLACK, size - 6)
    r = 26 if step >= 100 else (18 if step >= 44 else 15)
    for i, text in enumerate(key):
        y = top + i * step
        # wrap to the key's width; a second line only when it fits the step
        words, lines, cur = text.split(), [], ""
        for w_ in words:
            t = (cur + " " + w_).strip()
            if tw(d, t, fk) <= kw - 2 * r - 16:
                cur = t
            else:
                lines.append(cur)
                cur = w_
        lines.append(cur)
        lines = lines[:2] if step >= size * 2.2 else lines[:1]
        lh = size * 1.12
        ty = y + (step - lh * len(lines)) / 2
        cy = ty + lh / 2
        if plain:
            d.rectangle([kx + r * 0.5, cy - 3, kx + r * 1.5, cy + 3], fill=AMBER)
        else:
            d.ellipse([kx, cy - r, kx + 2 * r, cy + r], fill=MARKER, outline=BONE, width=2)
            s = str(i + 1)
            d.text((kx + r - tw(d, s, fn) / 2, cy - (size - 6) * 0.62), s, font=fn, fill=BONE)
        for j, l in enumerate(lines):
            d.text((kx + 2 * r + 16, ty + j * lh), l, font=fk, fill=BONE)


def centred_title(im, d, lines, eyebrow=None, under=None):
    """Wayfinding sign: eyebrow at the top, the name large and centred; under,
    a smaller line beneath it."""
    d.text((MARGIN, EYEBROW_Y), (eyebrow or EYEBROW).upper(), font=font(F_BOLD, 40), fill=EMBER)
    d.line([(MARGIN, DIVIDER_Y), (W - MARGIN, DIVIDER_Y)], fill=FRAME_PALE, width=4)
    size = 190
    avail = W - MARGIN * 2
    top_limit = DIVIDER_Y + 30
    under_h = 90 if under else 0
    avail_h = BODY_BOTTOM - top_limit - under_h
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
    if under:
        fu = font(F_BOLD, 56)
        d.text(((W - tw(d, under, fu)) // 2, top + block + under_h - 66), under, font=fu, fill=SLATE)


def map_board(im, d, src, legend, layout):
    """A site map: the drawing (art/signs, lifted off the old board with its
    background made transparent) and its numbered legend. layout "side" puts
    the drawing down the right with the legend left of it; "top" puts a wide
    drawing across the top with the legend in two columns under it."""
    fig = Image.open(os.path.join(ART, src)).convert("RGBA")
    top, bottom = ROWS_Y, BODY_BOTTOM - 8
    if layout == "top":
        fh = int((bottom - top) * 0.45)
        scale = min(fh / fig.height, (W - 2 * MARGIN) / fig.width)
        fig = fig.resize((int(fig.width * scale), int(fig.height * scale)), Image.LANCZOS)
        im.paste(fig, ((W - fig.width) // 2, top), fig)
        cols = [legend[:(len(legend) + 1) // 2], legend[(len(legend) + 1) // 2:]]
        y0 = top + fig.height + 24
        step = (bottom - y0) / max(len(cols[0]), 1)
        x0s = [MARGIN, W // 2 + 24]
    else:
        scale = min((bottom - top) / fig.height, 820 / fig.width)
        fig = fig.resize((int(fig.width * scale), int(fig.height * scale)), Image.LANCZOS)
        im.paste(fig, (W - MARGIN - fig.width, top + ((bottom - top) - fig.height) // 2), fig)
        # a long legend goes in two columns in the room left of the drawing
        if len(legend) > 8:
            half = (len(legend) + 1) // 2
            cols = [legend[:half], legend[half:]]
            x0s = [MARGIN, MARGIN + (W - 2 * MARGIN - fig.width - 48) // 2]
        else:
            cols = [legend]
            x0s = [MARGIN]
        y0 = top
        step = (bottom - y0) / max(len(cols[0]), 1)
    size = int(min(46, step * 0.78))
    fd, fr = font(F_BLACK, size), font(F_REG, size - 2)
    for col, x0 in zip(cols, x0s):
        y = y0
        for des, desc in col:
            d.text((x0, y), des, font=fd, fill=AMBER)
            d.text((x0 + tw(d, "00", fd) + 28, y + 2), desc, font=fr, fill=BONE)
            y += step


def table(im, d, cols, rows):
    """A table across the body: cols = [(heading, share of the width)], rows =
    lists of cells. One type size for the whole table, the largest every cell
    fits at; the first column in the designation face, and any column given a
    third element True (cols entry (heading, share, True)). A cell may be
    (text, colour) - a colour chip before the text (the triage card colours)."""
    x0, x1 = MARGIN, W - MARGIN
    total = sum(c[1] for c in cols)
    xs, x = [], x0
    keys = {i for i, c in enumerate(cols) if i == 0 or (len(c) > 2 and c[2])}
    for c in cols:
        share = c[1]
        xs.append(x)
        x += (x1 - x0) * share / total
    xs.append(x1)
    pad, chip = 18, 34
    fh = font(F_BOLD, 32)
    y = ROWS_Y - 8
    for i, c in enumerate(cols):
        d.text((xs[i], y), c[0].upper(), font=fh, fill=EMBER)
    y += 50
    d.line([(x0, y), (x1, y)], fill=FRAME_PALE, width=2)
    step = min(78, (BODY_BOTTOM - 6 - y) / max(len(rows), 1))

    def cell_text(c):
        return c[0] if isinstance(c, tuple) else c

    def fits(size):
        for r in rows:
            for i, c in enumerate(r):
                f = font(F_BLACK if i in keys else F_REG, size)
                room = xs[i + 1] - xs[i] - pad - (chip + 14 if isinstance(c, tuple) else 0)
                if tw(d, cell_text(c), f) > room:
                    return False
        return True

    size = int(min(38, step * 0.66))
    while size > 22 and not fits(size):
        size -= 1
    for n, r in enumerate(rows):
        cy = y + step / 2
        for i, c in enumerate(r):
            f = font(F_BLACK if i in keys else F_REG, size)
            tx = xs[i]
            if isinstance(c, tuple):
                d.rectangle([tx, cy - chip / 2, tx + chip, cy + chip / 2], fill=c[1], outline=BONE, width=2)
                tx += chip + 14
            # one middle line for both faces, so the black and regular cells sit level
            d.text((tx, cy), cell_text(c), font=f, fill=AMBER if i in keys else BONE, anchor="lm")
        y += step
        if n < len(rows) - 1:
            d.line([(x0, y), (x1, y)], fill=WOOD_RULE, width=2)


def diagram(im, d, src, notes):
    """A drawn schematic (art/signs, transparent - tools/gen_inf_figs.py) down
    the right of the body, its short notes left of it: [designation, text]
    rows, the text wrapping under itself. One type size for all the notes,
    the largest that fits. No notes: the drawing centred across the body."""
    fig = Image.open(os.path.join(ART, src)).convert("RGBA")
    top, bottom = ROWS_Y - 14, BODY_BOTTOM - 6
    if not notes:
        scale = min((bottom - top) / fig.height, (W - 2 * MARGIN) / fig.width)
        fig = fig.resize((int(fig.width * scale), int(fig.height * scale)), Image.LANCZOS)
        im.paste(fig, ((W - fig.width) // 2, top + (bottom - top - fig.height) // 2), fig)
        return
    scale = min((bottom - top) / fig.height, 1060 / fig.width)
    fig = fig.resize((int(fig.width * scale), int(fig.height * scale)), Image.LANCZOS)
    im.paste(fig, (W - MARGIN - fig.width, top + (bottom - top - fig.height) // 2), fig)
    x0, x1 = MARGIN, W - MARGIN - fig.width - 56

    def lay(size):
        fd, fr = font(F_BLACK, size), font(F_REG, size - 4)
        out = []
        for des, text in notes:
            first = x1 - x0 - tw(d, des, fd) - tw(d, " - ", fr)
            lines, cur, room = [], "- ", first
            for w_ in text.split():
                t = (cur + w_) if cur == "- " else (cur + " " + w_)
                if tw(d, t, fr) <= room:
                    cur = t
                else:
                    lines.append(cur)
                    cur, room = w_, x1 - x0 - 24
            lines.append(cur)
            out.append((des, lines))
        return fd, fr, out

    for size in range(42, 25, -1):
        fd, fr, out = lay(size)
        lh, gap = size * 1.2, size * 0.55
        total = sum(len(l) for _, l in out) * lh + gap * (len(out) - 1)
        if total <= bottom - top:
            break
    y = top + (bottom - top - total) / 2
    for des, lines in out:
        d.text((x0, y), des, font=fd, fill=AMBER)
        dx = tw(d, des, fd) + tw(d, " ", fr)
        for i, line in enumerate(lines):
            d.text((x0 + dx if i == 0 else x0 + 24, y + (size - (size - 4)) * 0.7 + i * lh),
                   line, font=fr, fill=BONE)
        y += len(lines) * lh + gap


def image_board(name, src):
    """A finished picture used as the board as it is - the objective GRG maps,
    their badge already the unit's (art/signs/grg)."""
    return Image.open(os.path.join(ART, src)).convert("RGB").resize((W, H), Image.LANCZOS)


# ---------------------------------------------------------------------------
# content
# ---------------------------------------------------------------------------
def T(lines, sub=None, foot=None, under=None):
    """under: a smaller line set under the name (the sub is not drawn on a
    title board - "toc" keeps its look)."""
    return {"kind": "title", "lines": lines, "sub": sub, "foot": foot, "under": under}

def R(title, items, sub=None, foot=None):
    return {"kind": "rows", "title": title, "items": items, "sub": sub, "foot": foot}

def S(title, blocks, sub=None, foot=None, fig=None):
    return {"kind": "sections", "title": title, "blocks": blocks, "sub": sub, "foot": foot, "fig": fig}

def U(name, src, box, foot=None, local=False):
    """local=True reads src from addons/media/images (repo material), local="art"
    from art/signs (swatches lifted from the last good boards, the old
    converted signs being gone), else the JMFSB_SIGN_ORIG folder."""
    return {"kind": "uniform", "name": name, "src": src, "box": box, "foot": foot, "local": local}

def K(title, columns, foot=None):
    return {"kind": "keys", "title": title, "columns": columns, "foot": foot}

def FIG(title, src, box, sub=None, foot=None):
    return {"kind": "figure", "title": title, "src": src, "box": box, "sub": sub, "foot": foot}

def D(title, figs, key, sub=None, foot=None, plain=False):
    return {"kind": "devices", "title": title, "figs": figs, "key": key, "sub": sub, "foot": foot, "plain": plain}

def M(title, src, legend, layout="side", sub=None, foot=None):
    return {"kind": "map", "title": title, "src": src, "legend": legend, "layout": layout,
            "sub": sub, "foot": foot}

def IMG_(src):
    return {"kind": "image", "src": src}

def TB(title, cols, rows, sub=None, foot=None):
    return {"kind": "table", "title": title, "cols": cols, "rows": rows, "sub": sub, "foot": foot}

def DG(title, src, notes, sub=None, foot=None):
    """A schematic from art/signs (tools/gen_inf_figs.py) with its notes."""
    return {"kind": "diagram", "title": title, "src": src, "notes": notes, "sub": sub, "foot": foot}

RANGE_FOOT = "Fire only on a hot range - check your lane before you go loud"
# Dagger Island (the training map, 2026-11-07). The old 61st boards' "Range
# Control: Freq 60 MHz / Medevac: Freq 35 MHz" is gone - the voice is the
# mod's nets now, not radio frequencies.
DAGGER = "Dagger Island Multipurpose Training Area"
ACM = "Advanced Combat Medicine 1.4.8"
INF = "Infantry Course"

SIGNS = {
    # the mission's own "Group & Arsenal System" board (data\fa_sign_group_arsenal.paa
    # in Task_Force_Roomba), brought into the set: the three game screenshots are
    # cut from it into art/signs, the board around them is the unit's
    "group_arsenal": {"kind": "steps", "title": "Group & Arsenal System",
        "sub": "self interact → group menu  ·  pick your role  ·  self interact → arsenal",
        "items": [("ACE self interact", "group_arsenal_1.png"),
                  ("Open Group Menu, select a role", "group_arsenal_2.png"),
                  ("Arsenal now available", "group_arsenal_3.png")],
        "foot": "No role, no arsenal  ·  re-open self interact after you pick  ·  swap roles any time at the staging zone"},
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

    # ---- squads and sections (2026-11-07): one board per old 61st squad
    # sign. Call signs from the unit's ORBAT - OVERLORD 6 is the HQ ("toc").
    "squad_ghost":     T(["GHOST 1"], under="Team 1"),
    "squad_nomad":     T(["NOMAD 2"], under="Team 2 - Mechanised"),
    "squad_raider":    T(["RAIDER 3"], under="Team 3"),
    "squad_support":   T(["SUPPORT 4"], under="Support Team"),
    "medical_section": T(["Medical Section"]),

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
            ["Group Menu", "ACE self-interact"],
            ["Kit is saved", "loadout and roster gear stored when you close any inventory"],
            ["Also here", "heal, TP menu and vehicle customisation"],
        ]),
        ("Patrol Base", "anyone can build one - no rank needed", [
            ["Kits", "carry a Patrol Base Kit (sand or olive), drop 4 within 5 m"],
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
        ["View Distance", "the \\ key, anywhere"],
        ["Night Vision", "colour filter under CBA settings"],
        ["TP Menu", "ACE self-interact, staging areas only"],
        ["Vehicle Customisation", "ACE self-interact, staging areas only"],
        ["NVG Brightness", "ALT + Page Up / Page Down"],
        ["Laser Code", "CTRL + ALT + Q up, CTRL + ALT + E down"],
    ], foot="Always remember to pillage BEFORE you burn"),

    "good2know": R("Good to Knows", [
        ["HALO Mask", "HALO and HAHO jumpers wear one, or the aircraft answers CANTCO"],
        ["Boo Boo Bag", "an IFAK - open it with ACE self-interact"],
        ["VS-17", "portable helipad - AI may or may not land on it"],
        ["View Distance", "the \\ key, or CTRL + [ and CTRL + ] to step it"],
        ["NVG Brightness", "ALT + Page Up / Page Down"],
        ["Laser Code", "CTRL + ALT + Q up, CTRL + ALT + E down"],
        ["Vector Marker", "CTRL + SHIFT + M - marks your target for everyone"],
        ["Vector Waypoint", "CTRL + SHIFT + T - a waypoint only you can see"],
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
            ["Shift + [ ]", "HUD slot on / off, left / right"],
            ["Alt + [ ]", "cycle the slot - drones, jamming, radio, scanner, squad, timer"],
        ]),
        ("On The Tablet", "your Open Tablet key, or ACE self-interact > Tablet", [
            ["Live Tiles", "the top band - press one and its app opens full size"],
            ["TAC//MSG", "the reader - nets, threads and report cards"],
            ["Support", "message the asset in TAC//MSG - @ its call sign"],
        ]),
    ], fig="hud_panels.png",
       foot="Every key is rebindable - CBA controls, under 1st Joint Multi-Functional Strike Battalion"),

    "viewd": R("View Distance", [
        ["Backslash", "default keybind for the view distance menu"],
        ["Ctrl + [ ]", "step it down / up; Shift, Ctrl, Alt + \\ for presets"],
        ["Foot / Car / Air", "each has its own view and object distance"],
    ], sub="Set it in staging - not mid-contact"),

    # the two Controls screenshots ARE the content here - keep them
    # both boards carry the same binds: keybinds.paa had been blank since its
    # source screenshot went; jmfsbkeys was the hand-made brown board
    "keybinds": K("Keybinds", [
        ("1st JMSB", [
            ("Troops In Contact", "Num -"),
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
            ("Troops In Contact", "Num -"),
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

    # The devices' keys (2026-11-07; the old board was cTab's - the mod has
    # none). The defaults registered in addons/devices/XEH_postInit.sqf.
    "device_keys": K("Device Keys", [
        ("Devices", [
            ("Open Tablet", "!UNBOUND - SET IT"),
            ("Hide / show the phone", "Ctrl+End"),
            ("Device F1 - F4", "F1-F4"),
            ("Action - what you look at", "F9"),
            ("Net page left / right", "F5 / F6"),
            ("Device RADIO app", "!UNBOUND - SET IT"),
            ("RADIO tab prev / next", "!UNBOUND - SET IT"),
        ]),
        ("Nets and calls", [
            ("Select net 1 - 8", "Shift+F1-F8"),
            ("Mute net 1 - 8", "Ctrl+F1-F8"),
            ("Answer / hang up", "F7"),
            ("Decline call", "F8"),
            ("Troops in contact", "F10"),
            ("Voice activation on / off", "F11"),
            ("Call camera face / view", "!UNBOUND - SET IT"),
        ]),
    ], foot="Numpad keys: Addon Options > Devices > Key layout  ·  every key: Configure Addons > 1st JMSB"),

    # ACE3 Equipment keys (2026-11-07): the defaults ACE 3.21.2 registers
    # (ace_common, ace_microdagr, ace_laser, ace_irlight, ace_nightvision,
    # ace_parachute, ace_tagging, ace_vector, ace_yardage450).
    "ace_keys": K("ACE Equipment Keys", [
        ("Devices and laser", [
            ("Toggle handheld device", "Home"),
            ("Close handheld device", "Ctrl+Home"),
            ("Cycle handheld devices", "Shift+Home"),
            ("MicroDAGR prev / next", "!UNBOUND - SET IT"),
            ("Laser code up X#XX", "Ctrl+Alt+Q"),
            ("Laser code up XX#X", "Ctrl+Alt+W"),
            ("Laser code up XXX#", "Ctrl+Alt+E"),
        ]),
        ("Optics and more", [
            ("Vector azimuth", "Tab"),
            ("Vector distance", "R"),
            ("Yardage 450 power", "R"),
            ("NVG brightness up / down", "Alt+PgUp/PgDn"),
            ("Altimeter", "O"),
            ("Illuminator / laser switch", "!UNBOUND - SET IT"),
            ("Spray paint quick tag", "!UNBOUND - SET IT"),
        ]),
    ], foot="Set in: Options > Controls > Configure Addons > ACE3 Equipment"),

    # GAME VOICE (user, 2026-10-22: "signs for the game voip system"). Three
    # boards, the words from addons/voice, addons/adapter_von and the devices'
    # keybinds (XEH_postInit.sqf): the nets a man is on, the keys, and how it
    # works. TFAR and ACRE were removed 2026-10-31 (DEC1).
    "radio_nets": R("Radio Voice - Your Nets", [
        ["TEAM", "your squad, e.g. GHOST 1 - everyday talk; where you start on every role pick"],
        ["C2", "team leaders, ATLs and all of HHC - leaders talking between squads"],
        ["A2G", "pilots and copilots by seat, plus the JFO skill - air to ground"],
        ["VEH", "crew intercom of the vehicle you are in - not the passengers"],
        ["LOCAL", "talking out loud to everyone near you - hold Shift + Caps Lock - always works, no radio needed"],
        ["CALLS", "private calls, any number, up to 8 people each - CALL beside a name in the Squad app"],
        ["GLOBAL", "the whole server - the tablet's GLOBAL button; C2 members and admins only"],
    ], sub="The comm plan in PAC puts you on them - by squad, role and skill",
       foot="Chip outline: green good  ·  amber weak or jammed  ·  red no route  ·  dim muted"),

    # THE NUMPAD STANDARD (2026-11-07, docs/DESIGN_WATCH_HUD.json: 1-4 nets,
    # 5-8 F1-F4, 9 the action key; "- is TIC, 0 and . are the arrows, / = no
    # do not answer, * = yes or answer" stand; Ctrl + a net's key mutes it) -
    # the same table as the comment over BUTTON_KEYS in
    # addons/devices/script_component.hpp.
    "numpad": {
        "kind": "numpad", "title": "Numpad - Device Keys",
        "sub": "Num Lock ON  ·  1-4 nets  ·  5-8 the device's F1-F4  ·  9 action",
        "keys": {
            "NUM": ("NUM LOCK\nON", "lock"),
            "/": ("DECLINE\nNO", "fn"),
            "*": ("ANSWER\nYES", "fn"),
            "-": ("TROOPS IN\nCONTACT", "fn"),
            "+": ("VOICE\nACTIVATE", "voice"),
            "7": ("F3", "fn"),
            "8": ("F4", "fn"),
            "9": ("ACTION", "fn"),
            "4": ("NET 4", "net"),
            "5": ("F1", "fn"),
            "6": ("F2", "fn"),
            "1": ("NET 1", "net"),
            "2": ("NET 2", "net"),
            "3": ("NET 3", "net"),
            "0": ("NET PAGE <", "arrow"),
            ".": ("NET\nPAGE >", "arrow"),
        },
        # Only what is NOT printed on the pad.
        "legend": [
            ("Hold Ctrl and press", [
                ("Mute / unmute net 1-4", "Ctrl + 1-4"),
            ]),
            ("The device's F1-F4 (5 6 7 8)", [
                ("F1 ear, F2 mute, F3 / F4 zoom", "the walking view"),
                ("Watch on: report, cycle, all off, squad", "the watch HUD"),
                ("The apps set in SETTINGS", "the tablet"),
            ]),
            ("Talking", [
                ("On your net", "Caps Lock"),
                ("LOCAL - everyone near you", "Shift + Caps Lock"),
            ]),
        ],
        "foot": "Set on your own PC: ESC > Options > Controls > Configure Addons > 1st JMSB",
    },

    # THE F-ROW LAYOUT (user, 2026-11-08, "1st JMSB device keys: F-row layout";
    # "make f11 Voice activate"; "only 8 radio chips"): the default since
    # 2026-11-08 - KEY_LAYOUT_TABLE in addons/devices/script_component.hpp.
    # The numpad boards above and below stay, for the numpad layout.
    "fkeys": {
        "kind": "fkeys", "title": "F Keys - Device Keys",
        "sub": "The default keys  ·  no numpad needed  ·  8 nets",
        "keys": [
            ("F1", "DEVICE\nF1", "f"), ("F2", "DEVICE\nF2", "f"),
            ("F3", "DEVICE\nF3", "f"), ("F4", "DEVICE\nF4", "f"),
            ("F5", "PAGE <", "arrow"), ("F6", "PAGE >", "arrow"),
            ("F7", "ANSWER\nYES", "fn"), ("F8", "DECLINE\nNO", "fn"),
            ("F9", "ACTION", "fn"), ("F10", "TROOPS IN\nCONTACT", "fn"),
            ("F11", "VOICE\nACTIVATE", "voice"),
        ],
        "mods": [
            ("Shift +", ["NET %d" % n for n in range(1, 9)]),
            ("Ctrl +", ["MUTE %d" % n for n in range(1, 9)]),
        ],
        "legend": "Caps Lock talk on your net  ·  Shift + Caps Lock LOCAL  ·  numpad keys: Addon Options > Devices > Key layout",
        "foot": "Set on your own PC: ESC > Options > Controls > Configure Addons > 1st JMSB",
    },

    # THE SAME KEYS WITH THE TABLET OPEN (user, 2026-10-25: "make a numpad sign
    # for the tablet"): the numpad works under the tablet as on the phone
    # (jmfsb_devices_fnc_keyDown), and the frame's F1-F4 are numpad 5-8 or a
    # click, opening the apps set in SETTINGS > DEVICE KEYS. Numpad Enter is
    # never the mod's (user, 2026-11-01): the tablet key is the player's own.
    "numpad_tablet": {
        "kind": "numpad", "title": "Numpad - Tablet",
        "sub": "Num Lock ON  ·  same keys, tablet open  ·  bind Open Tablet yourself",
        "keys": {
            "NUM": ("NUM LOCK\nON", "lock"),
            "/": ("DECLINE\nNO", "fn"),
            "*": ("ANSWER\nYES", "fn"),
            "-": ("TROOPS IN\nCONTACT", "fn"),
            "+": ("VOICE\nACTIVATE", "voice"),
            "7": ("F3", "fn"),
            "8": ("F4", "fn"),
            "9": ("ACTION", "fn"),
            "4": ("NET 4", "net"),
            "5": ("F1", "fn"),
            "6": ("F2", "fn"),
            "1": ("NET 1", "net"),
            "2": ("NET 2", "net"),
            "3": ("NET 3", "net"),
            "0": ("TILE PAGE BACK\nSCROLL UP", "arrow"),
            ".": ("PAGE ON\nSCROLL DN", "arrow"),
        },
        "legend": [
            ("Hold Ctrl and press", [
                ("Mute / unmute net 1-4", "Ctrl + 1-4"),
            ]),
            ("Arrows 0 and .", [
                ("A call window up", "move it"),
                ("Else", "tile page, or scroll"),
            ]),
            ("The frame keys (click, or 5 6 7 8)", [
                ("TAC//MSG  ·  Squad", "5  6"),
                ("Radio  ·  Settings", "7  8"),
                ("Change their apps", "SETTINGS > DEVICE KEYS"),
            ]),
        ],
        "foot": "Set on your own PC: ESC > Options > Controls > Configure Addons > 1st JMSB",
    },

    "radio_keys": K("Radio Voice - Keys", [
        ("Talk and nets", [
            ("Talk on your active net", "Caps Lock"),
            ("Talk local (hold)", "Shift+Caps Lock"),
            ("Pick net 1 - 4", "Num 1-4"),
            ("Mute / unmute net 1 - 4", "Ctrl+Num 1-4"),
            ("Net page left / right", "Num 0 / Num ."),
            ("Radio volume", "!UNBOUND - SET IT"),
        ]),
        ("Calls and devices", [
            ("Answer / hang up", "Num *"),
            ("Voice activation on/off", "Num +"),
            ("Open the tablet", "!UNBOUND - SET IT"),
            ("Troops In Contact", "Num -"),
            ("Hide / show the phone", "Ctrl+End"),
            ("Device F1-F4", "Num 5-8"),
        ]),
    ], foot="Every key: Options > Controls > Configure Addons > 1st JMSB"),

    "radio_howto": R("Radio Voice - How It Works", [
        ["1", "hold Caps Lock to talk on your active net - Shift + Caps Lock talks local"],
        ["2", "carry the MPU5, your role's default radio - with no radio you only have VEH and LOCAL"],
        ["3", "pick a role and you land on your squad net - the filled chip on your phone"],
        ["4", "Num 1-4 picks a net by its chip number; hold Caps Lock and the chip goes red with TX"],
        ["5", "no fixed range - your signal routes radio to radio, through vehicles and the base stations"],
        ["6", "weak route = quiet with static; red outline = nobody can hear you - move, or get near a base"],
        ["7", "unconscious or on radio silence your radio nets close; LOCAL always works"],
    ], sub="Voice is built into the mod - nothing else to download",
       foot="NET % (game VON only) is the free radio channels - at 0% a new call cannot connect"),

    # The devices drawn (user, 2026-10-22: "include drawings" - in the signs):
    # the diagrams from tools/gen_device_diagrams.py, the key beside each.
    "radio_phone": D("Radio Voice - The Phone", ["diag_phone.png"], [
        "Status row: NET, MESH, JAM, GPS, DRONES, MSG, BATT",
        "Map, centred on you, with your squad's markers",
        "Net chips: number = its key (Num 1-4); filled = your active net",
        "TX: the chip goes red while you transmit on it",
        "Ear tag L / B / R: which ear that net's beeps play in",
        "Outline = signal: green good, amber weak, red no route, dim muted",
        "Squad list with a status dot per member",
        "Talking chip: who is talking right now, and on which net",
        "F1-F4 are Num 5-8: ear, mute, zoom in, zoom out",
        "The arrows are Num 0 and Num . : turn the net page (4 chips a page)",
    ], sub="The walking view - always on, in the GPS slot",
       foot="Hide or show it with Ctrl+End  ·  SETTINGS > DEVICES and DEVICE KEYS"),

    "radio_side": D("Radio Voice - The Side Device", ["diag_side.png"], [
        "Status in two rows: NET, MESH, JAM, GPS, DRONES, MSG, BATT",
        "Map, centred on you, with your squad's markers",
        "Net chips: number = its key (Num 1-4); filled = your active net",
        "TX: the chip goes red while you transmit on it",
        "Ear tag L / B / R: which ear that net's beeps play in",
        "Outline = signal: green good, amber weak, red no route, dim muted",
        "Squad list in two columns, a status dot per member",
        "Talking chip: who is talking right now, and on which net",
        "F1-F4 are Num 5-8: ear, mute, zoom in, zoom out",
        "The arrows are Num 0 and Num . : turn the net page (4 chips a page)",
    ], sub="The same walking view, stacked - left or right edge of your screen",
       foot="Pick the edge and the size under the tablet's SETTINGS > DEVICES"),

    "radio_tablet": D("Radio Voice - The Tablet", ["diag_tablet.png"], [
        "Bar: time, your grid, your name and squad, CH radio channels used and free",
        "Notification line: the latest alert and how many are waiting",
        "RADIO tile: your active net - press it for the RADIO app (or Num 8)",
        "Squad rail: CALL beside a name dials that person",
        "Map, with the map tools in the panel on the right",
        "Talking chip: who is talking, on which net",
        "TAC//MSG reader: CALL on a message replies with a phone call",
        "SETTINGS: device keys, phone size, tablet frame, grid digits, beeps",
        "Net chips: number = key, filled = active, outline = signal",
        "TX chip while you transmit",
        "GLOBAL: server-wide talk for C2 members and admins - red while on",
        "F1-F4 are Num 5-8: TAC//MSG, Squad, Radio, Settings",
        "The arrows are Num 0 and Num . : tile page, or scroll",
    ], sub="Open Tablet key opens it; UAV tablet: same screen, frame with grips",
       foot="ESC closes it  ·  everything on it is also on the phone, smaller"),

    # The radios themselves, and the tablet's apps (user, 2026-10-23: "add
    # guides to the radios, the devices and the tablets").
    "radio_sets": D("Radio Voice - The Radios", ["mpu5_icon.png", "tw950_icon.png"], [
        "MPU5, left: the unit's handheld and every role's default, in your radio slot",
        "It is what puts you on your nets - no radio, and you have only VEH and LOCAL",
        "TW-950, right: the second handheld - an older set, VHF only, no relay",
        "The handhelds carry every net - nothing on your back is a radio",
        "Arsenal > Tools holds both; the one you take goes in the radio slot",
    ], sub="The MPU5 is a MANET set: it relays for everyone near you",
       foot="Lose your radio and your chips go grey - get one from a mate or the arsenal", plain=True),

    "tablet_apps": R("The Tablet - Apps", [
        ["RADIO", "your nets and calls; MANAGE for leaders - the RTO makes nets there"],
        ["TAC//MSG", "reports and messages by net; CALL on a message replies with a call"],
        ["@CALLSIGN", "support: in TAC//MSG, TO the SUPPORT group or @ the asset, send its card"],
        ["DRONES", "the drones: fly yours, see the enemy's; the nearest hostile's bearing"],
        ["HACK", "nodes in range, the intel they hold"],
        ["MEDIC", "the squad's vitals live - heart rate, SpO2, rhythm - and casualties"],
        ["WEATHER / TIMER", "wind and visibility; a timer that rings on every scanner"],
        ["INTEL", "what has been recovered"],
        ["PAC", "your record, the roster, the operation"],
        ["SETTINGS", "device keys, phone size, tablet frame, grid digits, colour scheme"],
    ], sub="Your Open Tablet key opens it - a tile is a readout and the button to its app",
       foot="ESC closes  ·  the apps also run on the vanilla map in native mode"),

    # THE SIMPLE SIGNS (user, 2026-10-23: "make sure i have simple signs with
    # pictures for in game"): the drawing with four callouts and four big lines.
    "simple_phone": D("The Phone", ["diag_phone_simple.png"], [
        "NET, MESH, JAM, GPS, DRONES, MSG, BATT",
        "Net chips - Num 1-4 picks one",
        "Red with TX while you talk",
        "F1-F4 = Num 5-8",
    ], sub="Hold Caps Lock to speak on the filled chip",
       foot="Hide it with Ctrl+End  ·  size in SETTINGS > DEVICES"),

    "simple_side": D("The Side Device", ["diag_side_simple.png"], [
        "NET, MESH, JAM, GPS, DRONES, MSG, BATT",
        "Net chips - Num 1-4 picks one",
        "Red with TX while you talk",
        "F1-F4 = Num 5-8",
    ], sub="The phone's layout, stacked, on the edge of your screen",
       foot="Left or right edge and size in SETTINGS > DEVICES"),

    "simple_tablet": D("The Tablet", ["diag_tablet_simple.png"], [
        "RADIO tile - press for the RADIO app",
        "Net chips - Num 1-4 picks one",
        "Red with TX while you talk",
        "GLOBAL - leaders and admins, server-wide",
    ], sub="Your Open Tablet key opens it, ESC closes it",
       foot="Everything on it is also on the phone, smaller"),

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

    # ---- Dagger Island training map (2026-11-07) --------------------------
    # The 61st boards the dagger training mission used, remade on the unit's
    # board. Same words, minus the radio frequencies (see DAGGER).
    "dagger_camp":          T(["Camp Dagger"], foot=DAGGER),
    "dagger_dz_c":          T(["Drop Zone C"], foot=DAGGER),
    "dagger_fb_kilo":       T(["Firebase Kilo"], foot=DAGGER),
    "dagger_helo_airfield": T(["Helo Airfield"], foot=DAGGER),
    "dagger_hot_ranges":    T(["Hot Ranges"], foot=DAGGER),
    "dagger_live_fire":     T(["Live Fire Area"], foot=DAGGER),
    "dagger_motor_pool":    T(["Motor Pool"], foot=DAGGER),
    "dagger_obj_delta":     T(["Objective Delta"], foot=DAGGER),
    "dagger_obj_golf":      T(["Objective Golf"], foot=DAGGER),
    "dagger_range_a1":      T(["Range Alpha 1", "Basic Rifle Qual"], foot=DAGGER),
    "dagger_range_a2":      T(["Range Alpha 2", "Machine Gun Qual"], foot=DAGGER),
    "dagger_range_a3":      T(["Range Alpha 3", "Sniper Qual"], foot=DAGGER),
    "dagger_range_a4":      T(["Range Alpha 4", "Small Arms Manoeuvre"], foot=DAGGER),
    "dagger_range_b2":      T(["Range Bravo 2", "Anti Armour"], foot=DAGGER),
    "dagger_range_c1":      T(["Range Charlie 1", "CQB - MOUT"], foot=DAGGER),
    "dagger_trench":        T(["Trench Complex"], foot=DAGGER),
    "dagger_vab":           T(["Victory Air Base"], foot=DAGGER),
    "dagger_zeus_r1":       T(["Zeus Range 1"], foot=DAGGER),
    "dagger_zeus_r2":       T(["Zeus Range 2"], foot=DAGGER),
    # The terrain's own signs (2026-11-07, jmfsb_terrainsigns): every place name
    # the Dagger Island billboards carry that had no board yet.
    "dagger_zeus_r3":       T(["Zeus Range 3"], foot=DAGGER),
    "dagger_zeus_r4":       T(["Zeus Range 4"], foot=DAGGER),
    "dagger_zeus_r5":       T(["Zeus Range 5"], foot=DAGGER),
    "dagger_obj_alpha":     T(["Objective Alpha"], foot=DAGGER),
    "dagger_obj_bravo":     T(["Objective Bravo"], foot=DAGGER),
    "dagger_obj_charlie":   T(["Objective Charlie"], foot=DAGGER),
    "dagger_obj_echo":      T(["Objective Echo"], foot=DAGGER),
    "dagger_obj_foxtrot":   T(["Objective Foxtrot"], foot=DAGGER),
    "dagger_obj_hotel":     T(["Objective Hotel"], foot=DAGGER),
    "dagger_dz_a":          T(["Drop Zone A"], foot=DAGGER),
    "dagger_dz_b":          T(["Drop Zone B"], foot=DAGGER),
    "dagger_range_b1":      T(["Range Bravo 1"], foot=DAGGER),
    "dagger_range_control": T(["Range Control"], foot=DAGGER),
    "dagger_range_facility": T(["Range Facility"], foot=DAGGER),
    "dagger_mobile_range_1": T(["Mobile Range 1"], foot=DAGGER),
    "dagger_mobile_range_2": T(["Mobile Range 2"], foot=DAGGER),
    "dagger_sniper_range":  T(["Sniper Range"], foot=DAGGER),
    "dagger_ftx_range":     T(["FTX Range"], foot=DAGGER),
    "dagger_test_fire":     T(["Test Fire Area"], foot=DAGGER),
    "dagger_impact_area":   T(["Impact Area", "Do Not Enter"], foot=DAGGER),
    "dagger_no_entry":      T(["Do Not Enter"], foot=DAGGER),
    "dagger_shoot_house":   T(["Shoot House"], foot=DAGGER),
    "dagger_mout":          T(["MOUT Facility"], foot=DAGGER),
    "dagger_staging":       T(["Staging Area"], foot=DAGGER),
    "dagger_prep_east":     T(["Mission Prep", "East"], foot=DAGGER),
    "dagger_prep_west":     T(["Mission Prep", "West"], foot=DAGGER),
    "dagger_team_room":     T(["Team Room"], foot=DAGGER),
    "dagger_armory":        T(["Armory"], foot=DAGGER),
    "dagger_comms_tower":   T(["Comms Tower"], foot=DAGGER),
    "dagger_camp_opfor":    T(["Camp OPFOR"], foot=DAGGER),
    "dagger_fob_jackal":    T(["FOB Jackal"], foot=DAGGER),
    "dagger_viper_airbase": T(["Viper Airbase"], foot=DAGGER),
    "dagger_amphib_range":  T(["Amphibious Range"], foot=DAGGER),
    "dagger_boat_ramps":    T(["Boat Ramps"], foot=DAGGER),
    "dagger_dive_dock":     T(["Dive Ops Dock"], foot=DAGGER),
    "dagger_dive_town":     T(["Dive Town"], foot=DAGGER),
    "dagger_deep_dive":     T(["Deep Dive Area"], foot=DAGGER),
    "dagger_op_north":      T(["OP North"], foot=DAGGER),
    "dagger_op_south":      T(["OP South"], foot=DAGGER),
    "dagger_op_lynch":      T(["OP Lynch"], foot=DAGGER),
    "dagger_op_romad":      T(["OP Romad"], foot=DAGGER),
    "dagger_op_cliffhanger": T(["OP Cliffhanger"], foot=DAGGER),
    "dagger_drr_1":         T(["DRR 1"], foot=DAGGER),
    "dagger_drr_2":         T(["DRR 2"], foot=DAGGER),
    "dagger_drr_3":         T(["DRR 3"], foot=DAGGER),
    "dagger_drr_4":         T(["DRR 4"], foot=DAGGER),
    "dagger_drr_5":         T(["DRR 5"], foot=DAGGER),
    "dagger_drr_6":         T(["DRR 6"], foot=DAGGER),
    "dagger_drr_7":         T(["DRR 7"], foot=DAGGER),
    "dagger_welcome":       T(["Welcome to", "Dagger Island"], foot=DAGGER),
    "dagger_brief_1":       T(["Briefing Area 1"], foot=DAGGER),
    "dagger_brief_2":       T(["Briefing Area 2"], foot=DAGGER),
    "dagger_brief_3":       T(["Briefing Area 3"], foot=DAGGER),
    "dagger_brief_4":       T(["Briefing Area 4"], foot=DAGGER),
    "dagger_brief_5":       T(["Briefing Area 5"], foot=DAGGER),
    "dagger_brief_6":       T(["Briefing Area 6"], foot=DAGGER),
    "dagger_pistol_range":  T(["Pistol Range"], foot=DAGGER),
    "dagger_jtac_school":   T(["JTAC Schoolhouse"], foot=DAGGER),
    # In place of the other units' branding boards ("correction replace all").
    "dagger_jmsb":          T(["JMSB"], under="Sagittae in Tenebris", foot=DAGGER),
    # The terrain's comms plan board shows "numpad" (user, 2026-11-07: "make it
    # the phone keybinds"), not a board of its own.

    "dagger_map_camp": M("Camp Dagger", "dagger_map_camp.png", [
        ["1", "Briefing Area"], ["2", "Motor Pool"], ["3", "Helo Port"],
        ["4", "Weapons Familiarity (BCT)"], ["5", "Staging Area"],
        ["6", "Small Arms Practice"], ["7", "Pistol Range"], ["8", "Hand Grenade"],
        ["9", "CQB Training 1"], ["10", "CQB Training 2"], ["11", "Basic Marksmanship"],
    ], sub=DAGGER),
    "dagger_map_vab": M("Victory Air Base (VAB)", "dagger_map_vab.png", [
        ["1", "Small Arms Firing Range"], ["2", "C-17 Staging Area"],
        ["3", "Mission Briefing Area"], ["4", "Office Area"], ["5", "Hardened Hangars"],
        ["6", "MEDEVAC Landing Pad"], ["7", "Soft Shell Hangars"], ["8", "C-130 Staging Area"],
        ["9", "Helo Landing Pads"], ["10", "Airfield Control Tower"],
    ], layout="top", sub=DAGGER),
    "dagger_map_ranges": M("Range Complex", "dagger_map_ranges.png", [
        ["A1", "Basic Rifle Qual Range"], ["A2", "Machine Gun Range"],
        ["A3", "Sniper Qual Range"], ["A4", "Lanes"], ["B1", "Open"],
        ["B2", "Anti Armour"], ["C1", "CQB / MOUT Range"],
    ], sub=DAGGER),

    # objective GRG maps (the ACE slideshow boards): the old pictures, the
    # unit's badge over the old one - art/signs/grg
    "dagger_grg_alpha":   IMG_("grg/obj_alpha.png"),
    "dagger_grg_bravo":   IMG_("grg/obj_bravo.png"),
    "dagger_grg_charlie": IMG_("grg/obj_charlie.png"),
    "dagger_grg_delta":   IMG_("grg/obj_delta.png"),
    "dagger_grg_echo":    IMG_("grg/obj_echo.png"),
    "dagger_grg_foxtrot": IMG_("grg/obj_foxtrot.png"),
    "dagger_grg_golf":    IMG_("grg/obj_golf.png"),
    "dagger_grg_hotel":   IMG_("grg/obj_hotel.png"),

    # briefing areas - numbers only: who briefs where is the ORBAT's, not a sign's
    # ---- ACM medical boards (2026-11-07) ---------------------------------
    # Advanced Combat Medicine 1.4.8, the unit's medical mod. Every fact is
    # ACM's own data (its configs, stringtables and functions) - item names,
    # vial strengths, doses for its 83 kg ideal weight, max doses, thresholds.
    # The old 61st sheets only set the topics.
    "acm_march": R("MARCH", [
        ["M", "massive bleeding - tourniquet the limb, pressure bandage or ETD"],
        ["A", "airway - head turn or suction to clear, head tilt or i-gel"],
        ["R", "respiration - inspect chest, chest seal, NCD, BVM with O2"],
        ["C", "circulation - pulse, IV or IO, blood and fluids, CPR, AED"],
        ["H", "head - check response, splint, treat pain; ACM has no cold"],
    ], sub="Treat in this order, top to bottom", foot=ACM),

    "acm_self_aid": R("Self Aid", [
        ["Fight first", "win the firefight and get to cover, then treat"],
        ["Tourniquet", "limb bleeding - you can put it on yourself"],
        ["Bandage", "pressure bandage on each open wound"],
        ["Chest seal", "hole in the chest - seal it yourself"],
        ["Pain", "paracetamol while awake, Penthrox for short pain"],
        ["Communicate", "tell your team you are hit, how bad, and where"],
    ], sub="An ETD needs a buddy - you cannot put one on yourself", foot=ACM),

    "acm_buddy_aid": R("Buddy Aid", [
        ["1", "win the fight, get the casualty into cover"],
        ["2", "call the medic - who, how bad, where"],
        ["3", "stop bleeding - tourniquet limbs, pressure bandage or ETD on wounds"],
        ["4", "unconscious: check airway - head turn for vomit or blood, head tilt for collapse"],
        ["5", "check breathing - chest seal on a chest wound"],
        ["6", "feel the pulse at the neck - none: start CPR and keep it going"],
        ["7", "leaving them: recovery position - lost if dragged, carried or loaded"],
    ], sub="Until the medic takes over", foot=ACM),

    "acm_bandages": R("Bandages & Splints", [
        ["Pressure Bandage", "standard issue, any wound - you can use it on yourself"],
        ["Trauma Dressing", "ETD - large surface, 5x a pressure bandage - not on yourself"],
        ["Elastic Wrap", "wraps bandaged or clotted wounds and bruises - won't stop bleeding"],
        ["Surgical Kit", "stitches bandaged, wrapped or clotted wounds closed"],
        ["Tourniquet", "stops limb bleeding - the limb goes cyanotic, severe after 2 min"],
        ["SAM Splint", "re-usable - wrap it with an elastic wrap or it falls off"],
        ["Universal Splint", "single-use splint kit"],
        ["Fracture", "inspect, realign, splint - lidocaine IM into the limb numbs it"],
    ], sub="Bandaged wounds can reopen - wrap or stitch them", foot=ACM),

    "acm_meds_1": TB("Medications 1 - Heart & Blood", [
        ("Drug", 2.2), ("Vial", 1.6), ("Use", 3.4), ("Route", 1.1), ("Dose", 2.6), ("Limit", 3.1),
    ], [
        ["Epinephrine", "1mg/1ml", "cardiac arrest", "IV, IM", "IV 1 mg, IM 0.3 mg", "unstable over 4 mg IV, 6 IM"],
        ["Adenosine", "12mg/4ml", "slows heart; VT with a pulse", "IV", "6 mg", "heart pauses, restarts"],
        ["Amiodarone", "150mg/3ml", "VF, pVT", "IV", "150 mg; 300 if shocks fail", "max 2200 mg"],
        ["Lidocaine", "100mg/5ml", "IV: VF, pVT - IM: numbs a limb", "IV, IM", "IV 83 mg, IM 100 mg", "max IV 270 mg, IM 200"],
        ["Atropine", "1mg/1ml", "raises heart rate; nerve agent", "IV, IM", "IV 1 mg, IM 2 mg", "max 20 mg"],
        ["Esmolol", "100mg/10ml", "lowers heart rate, short", "IV", "20-40 mg", "unstable over 45 mg"],
        ["TXA", "1g/10ml", "bleeding, internal, chest blood", "IV", "1 g", "works for 15 min"],
        ["Calcium Chl.", "1g/10ml", "low calcium after blood", "IV", "1 g", "under 0.9 g does nothing"],
        ["Ertapenem", "1g/3.2ml", "wound infection; before evac", "IV, IM", "1 g", "-"],
        ["Ondansetron", "4mg/2ml", "nausea, vomiting", "IV, IM", "4 mg", "max 8 mg"],
    ], sub="Doses for 83 kg - over the max is an overdose", foot=ACM),

    "acm_meds_2": TB("Medications 2 - Pain & Other", [
        ("Drug", 2.4), ("Vial", 1.6), ("Use", 3.0), ("Route", 1.2), ("Dose", 2.8), ("Limit", 3.2),
    ], [
        ["Morphine", "10mg/2ml", "moderate to severe pain", "IV, IM", "IV 4-8 mg, IM 6-8 mg", "max IV 12 mg, IM 14"],
        ["Fentanyl", "100mcg/2ml", "acute severe pain", "IV, IM", "IV 40-80, IM 60-80 mcg", "max IV 150 mcg, IM 180"],
        ["Ketamine", "500mg/10ml", "pain, no opioid", "IV, IM", "IV 8-17 mg, IM 40-60", "max IV 250 mg, IM 500"],
        ["Fentanyl Lozenge", "OTFC", "acute severe pain", "cheek", "1 lozenge", "awake, lying or sitting; 3 min"],
        ["Paracetamol", "pack", "mild to moderate pain", "mouth", "1 dose", "awake only; peaks in 4 min"],
        ["Penthrox", "inhaler", "acute pain, short", "inhaled", "1 use", "max 5; lasts 4 min"],
        ["Naloxone", "4mg/0.1ml", "reverses opioids, overdose", "nose", "1 spray", "lasts 5 min"],
        ["Ammonia", "inhalant", "wakes a fainted patient", "inhaled", "1 use", "only with stable vitals"],
        ["Dimercaprol", "300mg/3ml", "lewisite exposure", "IM", "250 mg", "max 600 mg"],
    ], sub="Opioid and ketamine doses scale with body weight", foot=ACM),

    "acm_airway": TB("Airway", [
        ("Check airway shows", 3.0), ("Cause", 2.6), ("Fix", 4.6),
    ], [
        ["Light obstruction", "vomit or blood", "head turning"],
        ["Obstruction", "more vomit or blood", "suction bag or ACCUVAC"],
        ["Collapse", "unconscious, gets worse", "head tilt-chin lift, recovery position or i-gel"],
        ["Unconscious", "airway reflex lost", "OPA or NPA keeps it open"],
        ["Vomit, head bleed", "lying on the back", "recovery position or i-gel stops it building"],
        ["Inflammation", "chemical exposure", "significant blocks the i-gel - cric kit"],
        ["Nothing works", "-", "cric kit: scalpel, hook, cric-key, cuff, strap"],
    ], sub="Airway items go in only when unconscious and clear", foot=ACM),

    "acm_breathing": TB("Breathing & Thorax", [
        ("Finding", 2.8), ("Means", 3.6), ("Fix", 4.0),
    ], [
        ["No chest movement", "not breathing: airway, arrest, tension", "clear the airway; NCD; BVM"],
        ["Uneven chest rise", "pneumothorax", "chest seal - stops it getting worse"],
        ["Tracheal deviation", "tension pneumothorax, 3 min+", "NCD kit, then chest seal"],
        ["Extensive bruising", "hemothorax - blood in the chest", "thoracostomy, drain, chest tube; TXA"],
        ["Shallow", "pneumothorax or airway collapse", "chest seal; manage the airway"],
        ["Slow / rapid", "under 16 / over 22 a minute", "find the cause"],
        ["SpO2 under 91", "cyanosis; 80 out, 67 arrest", "BVM; add O2 - 425 L tank or vehicle"],
    ], sub="NCD with no tension causes a pneumothorax", foot=ACM),

    # Circulation / DCR: shock classes on the left (ACE's hemorrhage classes,
    # which ACM's menu reads off blood + plasma + saline), what each fluid
    # does on the right (ACM's getBloodVolumeChange; GET_EFF_BLOOD_VOLUME is
    # blood + 30% of plasma - overload). Arrest is acm_cardiac, the type
    # table acm_blood, the menu and flow acm_fluids.
    "acm_circulation": TB("Circulation", [
        ("Class", 1.1), ("Menu shows - volume left", 4.5), ("Fluid", 1.6, True), ("Does", 4.4),
    ], [
        ["I", "Lost some blood - under 6.0 L", "Blood", "volume and oxygen - type must match"],
        ["II", "Lost a lot of blood - under 5.1 L", "Plasma", "volume, clotting, 30% of the oxygen"],
        ["III", "Lost a large amount - under 4.2 L", "Saline", "volume only - carries no oxygen"],
        ["IV", "Lost a fatal amount - under 3.6 L", "FWB", "fresh whole blood - full speed 15 min"],
        ["3.1 L", "asystole - no ROSC", "TXA", "1 g IV - slows all bleeding"],
        ["Refill", "arm 2 s at 5.8 L, over 4 s at 5.2 L", "Calcium", "1 g IV after blood - clotting back"],
        ["IV fails", "vein not found, or limb too damaged", "Over 6 L", "overload - BP up, oxygen down"],
    ], sub="Class counts blood, plasma and saline - only blood carries full oxygen",
       foot=ACM),

    "acm_vitals": TB("Vital Signs", [
        ("Vital", 2.4), ("Normal", 2.2), ("Out of range", 7.0),
    ], [
        ["Heart rate", "75-82 bpm", "under 40 or over 220 and it stays: cardiac arrest"],
        ["Pulse check", "normal 60-100", "weak under 60, strong over 100 - the non-medic reading"],
        ["Blood pressure", "120/80", "drops with bleeding, chest injury, blood under 4.8 L"],
        ["MAP", "93", "under 55 or over 200: cardiac arrest"],
        ["Pulse sites", "wrist, groin, neck", "felt only above systolic 80, 70, 60"],
        ["SpO2", "98.5-99%", "91 cyanosis - 85 vision - 80 out - 67 arrest - 55 dead"],
        ["Breathing", "16-20 a minute", "under 16 slow, over 22 rapid, under 6 unconscious"],
        ["Blood volume", "6.0 L", "5.1 class II - 4.2 class III - 3.6 class IV - 3.1 asystole"],
        ["Cap refill", "about 2 s", "3 s, then over 4 s as blood drops; over 4 s, no pulse"],
    ], sub="Wakes only with BP 60/50+, HR 40+, SpO2 80+, breathing 6+", foot=ACM),

    "acm_triage": TB("Triage", [
        ("Card", 1.6), ("Category", 2.4), ("Who", 7.0),
    ], [
        [("T1", (0xFF, 0x00, 0x00)), "Immediate", "no pulse, not breathing, blocked airway, tension chest, heavy bleeding"],
        [("T2", (0xFF, 0xD6, 0x00)), "Delayed", "serious but stable - pulse, breathing, bleeding controlled"],
        [("T3", (0x00, 0x80, 0x00)), "Minimal", "minor wounds, awake, can treat themselves"],
        [("T4", (0x00, 0x00, 0x00)), "Expectant", "asystole with blood under 3.1 L - no ROSC under 4.2 L"],
        ["None", "Not triaged", "set the card from the medical menu"],
        ["Card log", "-", "every drug, dose and airway item given is written on it"],
    ], sub="T1-T4 also show in the vehicle patient list", foot=ACM),

    # Who may do what: each action's allowSelfTreatment and medicRequired,
    # the allow* settings at their ACM defaults (0 anyone, 1 medic, 2 doctor).
    "acm_skills": TB("Skills - Who Can Do What", [
        ("Area", 1.6), ("Self - and on others", 3.4), ("Anyone, on others", 3.9), ("Medic", 3.6),
    ], [
        ["Wounds", "bandage, tourniquet, SAM splint", "trauma dressing (ETD)", "elastic wrap, stitches, fractures"],
        ["Airway", "-", "head turn, chin lift, recovery position", "i-gel, cric kit"],
        ["Airway kit", "-", "OPA, NPA, suction bag", "ACCUVAC"],
        ["Breathing", "chest seal", "check, inspect chest, BVM, pulse ox", "NCD, thoracostomy, chest tube"],
        ["Circulation", "-", "pulse, BP cuff, cap refill, CPR, AED", "IV, IO - not on yourself"],
        ["Medication", "paracetamol, Penthrox, naloxone", "-", "every syringe, fentanyl lozenge"],
        ["Disability", "-", "shake or slap awake", "ammonia inhalant"],
        ["Evacuation", "-", "-", "doctor: convert casualty"],
    ], sub="ACM default settings - a doctor counts as a medic", foot=ACM),

    # The medical menu (ACE's, as ACM draws it): body colours from ACE's
    # bleeding and damage scales, bones and kit from ACM's body image; the
    # menu buttons are ACE's categories with ACM's actions in them.
    "acm_menu": TB("Medical Menu", [
        ("On the body", 2.3), ("Means", 3.6), ("Button", 1.9, True), ("Holds", 4.6),
    ], [
        [("Yellow", (0xFF, 0xDE, 0x75)), "bleeding, slow", "Triage", "the triage card - T1 to T4"],
        [("Red", (0xFF, 0x00, 0x00)), "bleeding, fast", "Examine", "pulse, BP, cap refill, pulse ox, AED leads"],
        [("Pale blue", (0x9E, 0xDB, 0xFF)), "hurt, not bleeding", "Bandage", "bandages, tourniquet, splints, wraps"],
        [("Dark blue", (0x00, 0x00, 0xFF)), "badly hurt, not bleeding", "Medication", "pills, syringes, inhalers, wake up"],
        [("Red bone", (0xFF, 0x00, 0x00)), "fractured", "Airway", "airway and chest, to thoracostomy"],
        [("Blue bone", (0x00, 0x00, 0xFF)), "splinted", "Advanced", "IV, IO, fluids, CPR, AED shock"],
        ["Tourniquet", "drawn on the limb", "Drag / Carry", "move the casualty"],
        ["Kit", "IV, IO, seal, OPA, NPA, i-gel, pads", "Switch", "between the patient and you"],
        ["Lists", "-", "Overview", "injuries, bleeding, blood lost, pain"],
        ["", "", "Logs", "activity log and quick view"],
    ], sub="H opens it on the man you look at, else on you  ·  Ctrl+H peeks at your own",
       foot=ACM),

    # Sheet 2 of self aid: checking yourself. acm_self_aid is what to do.
    "acm_self_aid_2": R("Self Aid 2 - Check Yourself", [
        ["Look", "Ctrl+H peeks at your wounds; H opens your own menu"],
        ["Bleeding", "bandage until the menu says no external bleeding"],
        ["Tourniquet", "hurts after 2 min, slows a leg, sways an arm"],
        ["Fracture", "SAM splint it yourself - unwrapped it falls off in 1-2 min"],
        ["Pain", "paracetamol only while awake; Penthrox lasts 4 min"],
        ["Dog tags", "check your own - your blood type is on them"],
        ["Not on you", "trauma dressing, airway items, IV, IO - get a buddy"],
    ], sub="Sheet 2 - what the menu tells you about yourself", foot=ACM),

    # Thorax: ACM's breathing functions in the order they are used. The
    # findings for each sign are on acm_breathing.
    "acm_thorax": R("Thorax Management", [
        ["1 Inspect", "unconscious only - uneven rise, deviation, bruising"],
        ["2 Chest seal", "on a chest wound - stops a pneumothorax getting worse"],
        ["3 NCD kit", "tracheal deviation: clears the tension; with no tension it makes one"],
        ["4 Thoracostomy", "medic, surgical or thoracostomy kit - releases tension, finger sweep"],
        ["  Lidocaine", "IM into the chest first, or the thoracostomy hurts"],
        ["5 Chest tube", "after the thoracostomy - holds while lying down or out"],
        ["6 Drain", "through the tube - ACCUVAC gives the ml, suction bag a guess"],
        ["7 Close", "close the incision with a surgical kit - one-way valve"],
        ["Hemothorax", "TXA IV clears it faster; over 1.2 L stops the heart"],
    ], sub="Pneumothorax worsens while he breathes - seal it early", foot=ACM),

    # Cardiac arrest: ACM's rhythms, AED shock, CPR, amiodarone and
    # reversible (PEA) arrest functions.
    "acm_cardiac": TB("Cardiac Arrest", [
        ("Rhythm / step", 2.5), ("What to do - what happens", 8.0),
    ], [
        ["VF, pVT", "shockable - AED shock, then CPR; a shock lifts CPR's chance for 2 min"],
        ["No CPR", "pVT decays to VF, then to asystole"],
        ["Shocks", "60 s or more apart - sooner, or on asystole or PEA, gives asystole"],
        ["Drugs in VF, pVT", "epinephrine 1 mg, amiodarone 150 mg, lidocaine IV - all help CPR"],
        ["Shocks fail", "some hearts resist - amiodarone 300 mg IV, then shock"],
        ["Asystole", "no shock - CPR with epinephrine IV can bring back VF or pVT"],
        ["PEA", "fix in 6 min: tension, chest blood over 1.2 L, blood 4.2 L or less, SpO2 under 67"],
        ["CPR", "builds over 1-2 min unbroken - medics and doctors do it better"],
        ["CPR fails", "blood under 3.6 L; morphine and fentanyl lower its chance"],
        ["ROSC", "needs blood over 4.2 L, no tension, SpO2 67 or more"],
    ], sub="Blood under 3.1 L is asystole - no ROSC", foot=ACM),

    # The blood type table: ACM's BLOODTYPE_COMPATIBLE_LIST, green = the
    # patient (row) can take that bag (column); last column ACM's default
    # blood type ratios out of 100.
    "acm_blood": TB("Blood Types", [
        ("Patient", 1.6), ("O-", 1.0), ("O+", 1.0), ("A-", 1.0), ("A+", 1.0),
        ("B-", 1.0), ("B+", 1.0), ("AB-", 1.0), ("AB+", 1.0), ("In 100", 1.3),
    ], [
        [t] + [("", (0x4C, 0xAF, 0x50)) if d in ok else "-" for d in
               ["O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+"]] + [n]
        for t, ok, n in [
            ("O-",  ["O-"], "5"),
            ("O+",  ["O-", "O+"], "39"),
            ("A-",  ["O-", "A-"], "3"),
            ("A+",  ["O-", "O+", "A-", "A+"], "28"),
            ("B-",  ["O-", "B-"], "2"),
            ("B+",  ["O-", "O+", "B-", "B+"], "18"),
            ("AB-", ["O-", "A-", "B-", "AB-"], "1"),
            ("AB+", ["O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+"], "4"),
        ]
    ], sub="Row: the patient  ·  column: the bag  ·  type is on the dog tags",
       foot=ACM + "  ·  wrong type acts as saline, then a reaction"),

    # Fluids: ACM's transfusion menu (TransfusionMenu_*), its bags and
    # getBloodVolumeChange / getIVFlowRate.
    "acm_fluids": TB("Fluids & Transfusion", [
        ("Item / key", 2.4), ("What it does", 8.0),
    ], [
        ["Transfuse Fluids", "opens the menu - from an arm or the chest with an IV or IO in"],
        ["Left list", "bags on the selected line - Move, Remove, Stop transfusion"],
        ["Right list", "bags you carry - Add Bag; E switches to the patient's kit"],
        ["Keys", "1-3 IV site, Q IV or IO, W S A D Z X picks the body part"],
        ["Bags", "saline, plasma, blood - 1000, 500, 250 ml"],
        ["Access", "16g 1x, 14g 1.5x, FAST1 IO 0.65x, EZ-IO 0.55x"],
        ["Fluid", "saline 1.2x, plasma 1x, blood 0.8x - bags on one line share it"],
        ["Blocked", "tourniquet stops a limb IV; arrest without CPR all but stops IV"],
        ["IO", "hurts as it runs - lidocaine IV first; arm IO runs under a tourniquet"],
        ["FBTK", "on a donor's IV, fills; remove at 250 ml+ for a fresh whole blood bag"],
    ], sub="Inspect IV: clear, normal flow, no flow or swelling", foot=ACM),

    # Second vitals sheet: how each vital is read in ACM. acm_vitals has the
    # numbers. ACM has no body temperature.
    "acm_vitals_2": TB("Vital Signs 2 - Reading Them", [
        ("Check", 2.4), ("With", 3.8), ("Reads", 6.0),
    ], [
        ["Feel Pulse", "hands - neck, wrist or groin", "the beat itself; gone at low pressure"],
        ["Cap refill", "arm or chest", "~2, under 3, ~3 or over 4 s"],
        ["Blood pressure", "pressure cuff, or stethoscope", "bulb LMB +50, RMB +30; valve LMB -10, RMB -2"],
        ["Breathing", "Check Breathing", "normal, slow, rapid or none"],
        ["Chest", "stethoscope", "breath and heart sounds - move the bell"],
        ["SpO2", "pulse oximeter, either arm", "oxygen saturation"],
        ["AED monitor", "pads, pulse ox, cuff, capnograph", "HR, PR, SpO2, CO2, NIBP, RR"],
        ["EtCO2", "AED capnograph", "35-45 awake, 30-35 out, 10-20 good CPR, 0 arrest"],
        ["After ROSC", "AED capnograph", "about 50, falling to 30 over 30 s"],
        ["Temperature", "-", "not modelled by ACM"],
    ], sub="The numbers are on Vital Signs - this is how to get them", foot=ACM),

    # Pain by the level the menu shows (ACE's mild / pain / severe, set off
    # the unconscious threshold); drugs, doses and limits from ACM.
    "acm_pain": TB("Pain Management", [
        ("Menu shows", 2.4), ("Give", 2.6), ("Dose", 3.1), ("Who - notes", 4.6),
    ], [
        ["In mild pain", "Paracetamol", "1 dose, mouth", "anyone, awake; peaks in 4 min"],
        ["In mild pain", "Penthrox", "1 use, inhaled", "anyone, awake; lasts 4 min, max 5"],
        ["In pain", "Morphine", "IV 4-8 mg, IM 6-8 mg", "medic; max IV 12 mg, IM 14"],
        ["In pain", "Ketamine", "IV 8-17 mg, IM 40-60", "medic; not an opioid"],
        ["In severe pain", "Fentanyl", "IV 40-80, IM 60-80 mcg", "medic; the strongest"],
        ["In severe pain", "Fentanyl lozenge", "1, in the cheek", "medic; awake, lying or sitting"],
        ["Nausea", "Ondansetron", "4 mg IV or IM", "opioids, ketamine, lidocaine cause it"],
        ["Overdose", "Naloxone", "1 spray, nose", "anyone; reverses opioids"],
        ["In arrest", "-", "-", "morphine and fentanyl lower CPR's chance"],
    ], sub="Severe pain can knock a man out  ·  doses for 83 kg", foot=ACM),

    # Casualty flow, generic: ACE/ACM steps; 6 and 7 are ACM's evacuation
    # addon (convertCasualty, Evacuate Patient), only where a mission sets
    # its reinforce and evacuation points.
    "acm_medevac": R("Casualty Flow", [
        ["1 Point of injury", "win the fight - self and buddy aid, stop the bleeding"],
        ["2 Triage", "the medic sets T1-T4 on the triage card"],
        ["3 Move", "drag, carry or load - the recovery position is lost"],
        ["4 Casualty point", "T1 first - airway, breathing, circulation"],
        ["5 Evacuate", "medical vehicle - T1-T4 show in its patient list"],
        ["6 Convert", "doctor: unconscious player, not bleeding, ertapenem given"],
        ["7 Evac point", "carry him there - Evacuate Patient returns the ticket"],
    ], sub="6-7: ACM evacuation only - a converted man takes a reinforcement", foot=ACM),

    # ---- infantry course (2026-11-07) -------------------------------------
    # The 61st 11B course slides, remade on the unit board: one board per
    # slide, the drawings our own (tools/gen_inf_figs.py -> art/signs/inf).
    # The slides set the topics only. inf_travelling, inf_stack_normal and
    # inf_stack_breacher are the three slides the mission does not place.
    "inf_roles": DG("Unit Role Icons", "inf/roles.png", [],
        sub="The small triangle points the way the man faces", foot=INF),
    "inf_open_area": DG("Danger Area - Large Open Area", "inf/open_area.png", [
        ["Approach", "travelling overwatch - open up the distance between teams and men"],
        ["Road", "a danger area inside the danger area - cross it in the formation, do not clear it on its own"],
        ["Bound", "start bounding overwatch inside small arms range of the far side, about 250 m"],
        ["Far side", "teams bound into the wood line and clear room for the whole squad"],
    ], sub="NRP - near-side rally point  ·  FRP - far-side rally point", foot=INF),
    "inf_small_open": DG("Danger Area - Small Open Area", "inf/small_open.png", [
        ["Contour", "go round the open area, inside the tree line"],
        ["Detour", "turn 90 degrees, move past the open area, turn back"],
        ["Line", "come back onto the original direction of travel"],
        ["Rally", "near-side rally point before, far-side rally point after"],
    ], sub="Small enough to go round - do not cross it", foot=INF),
    # Terrain from the shooter's eye, as the course slide teaches it - not a
    # way of firing (user, 2026-11-07).
    "inf_defilade": DG("Enfilade & Defilade", "inf/defilade.png", [
        ["Enfilade", "in direct sight - ground the shooter can see, so he can hit it"],
        ["Defilade", "dead space - ground hidden behind a crest or fold, he can neither see nor hit it"],
        ["Moving", "go from defilade to defilade - cross ground in direct sight fast"],
        ["Dead space", "you cannot cover it from where you are - use grenades, indirect fire or another position"],
    ], foot=INF),
    "inf_single_env": DG("Single Envelopment", "inf/single_env.png", [
        ["Support", "fixes the enemy with fire from the front"],
        ["Manoeuvre", "moves round one flank under that fire"],
        ["Assault", "hits the enemy from the side"],
        ["Shift fire", "support lifts or shifts fire as the assault closes"],
    ], sub="Flank attack", foot=INF),
    "inf_deep_env": DG("Deep Envelopment", "inf/deep_env.png", [
        ["Support", "fixes the enemy with fire from the front"],
        ["Manoeuvre", "goes wide and deep round the flank"],
        ["Assault", "hits the enemy from the rear - cuts off the way out"],
        ["Needs", "a covered route and the time to use it"],
    ], foot=INF),
    "inf_double_env": DG("Double Envelopment", "inf/double_env.png", [
        ["Support", "fixes the enemy with fire from the front"],
        ["Manoeuvre", "two elements, one round each flank"],
        ["Assault", "both close at once from two sides"],
        ["Control", "the two elements converge - know where the other one is"],
    ], sub="Pincer", foot=INF),
    "inf_travelling": DG("Travelling & Travelling Overwatch", "inf/travelling.png", [
        ["Travelling", "both elements move together - contact not likely"],
        ["Travelling overwatch", "the lead moves, the trail follows far enough back to support - contact possible"],
        ["Bounding overwatch", "contact expected - see the bounding board"],
    ], foot=INF),
    "inf_bounding": DG("Bounding Overwatch", "inf/bounding.png", [
        ["Bound", "one team moves while the other overwatches, then they swap"],
        ["Successive", "the bounding team stops level with the overwatch team"],
        ["Alternating", "the bounding team moves past the overwatch team - faster"],
        ["Use", "contact expected"],
    ], sub="The numbers are the order of the bounds", foot=INF),
    "inf_support_fire": DG("Support by Fire", "inf/support_fire.png", [
        ["Supporting element", "takes ground with fields of fire on the enemy - left and right limits"],
        ["Moving element", "manoeuvres onto the enemy under that fire"],
        ["Support by fire", "the fire lets the other element close and assault"],
        ["Attack by fire", "the fire alone destroys the enemy - no assault"],
    ], foot=INF),
    "inf_linear_ambush": DG("Linear Ambush", "inf/linear_ambush.png", [
        ["Line", "the ambush line runs parallel to the kill zone"],
        ["Sectors", "each man fires into his own part of the kill zone"],
        ["Security", "a man or team on each flank watches the approaches"],
        ["Initiate", "the leader opens fire - that is the signal"],
    ], foot=INF),
    "inf_l_ambush": DG("L-Shaped Ambush", "inf/l_ambush.png", [
        ["Long leg", "parallel to the kill zone - fires across it"],
        ["Short leg", "at the end of the kill zone - fires along it"],
        ["Fires", "the legs' fires never point at each other"],
        ["Ground", "a bend in a road or trail"],
    ], foot=INF),
    "inf_offence_defence": S("Offence & Defence", [
        ("Offence", "the four Fs", [
            ["Find", "locate the enemy"],
            ["Fix", "pin him in place with fire"],
            ["Flank", "manoeuvre onto his side"],
            ["Finish", "assault and clear"],
        ]),
        ("Defence", "PMS", [
            ["Preparation", "positions, fields of fire, routes in and out"],
            ["Mutual support", "every position covers another"],
            ["Security", "early warning, all round"],
        ]),
    ], foot=INF),
    "inf_react_contact": S("React to Contact", [
        ("Act", "in this order", [
            ["Return fire", "suppress the enemy - the first priority"],
            ["Take cover", "get into cover and keep engaging"],
        ]),
        ("Report", "the 3 Ds", [
            ["Direction", "\"contact, 12 o'clock\" - or a bearing"],
            ["Distance", "\"100 metres\""],
            ["Description", "\"3 infantry, rifles\""],
        ]),
    ], foot=INF),
    "inf_wedge": DG("Team Wedge", "inf/wedge.png", [
        ["Shape", "an upside-down V, the team leader at the point"],
        ["Use", "open ground - spreads the team, covers more ground"],
        ["Spacing", "10 m minimum - more the more open the ground"],
        ["Contact", "every man can see the team leader"],
        ["Rear", "the last man watches the rear, the man ahead keeps him in sight"],
    ], foot=INF),
    "inf_file": DG("Team File", "inf/file.png", [
        ["Shape", "single file"],
        ["Use", "dense woods, built-up areas, building to building - contact not likely, or speed comes first"],
        ["Spacing", "3-5 m, by the situation"],
        ["Speed", "the team leader sets a pace that keeps the last man closed up"],
        ["Rear", "the last man watches the rear"],
    ], sub="Also called the column", foot=INF),
    "inf_staggered": DG("Staggered Column", "inf/staggered.png", [
        ["Shape", "zig-zag, men on alternate sides"],
        ["Use", "roads and built-up areas"],
        ["Why", "covers a wider area - one enemy cannot ambush the whole team"],
        ["Spacing", "3-5 m, by the situation"],
        ["Rear", "the last man watches the rear"],
    ], foot=INF),
    "inf_line": DG("Team Line", "inf/line.png", [
        ["Shape", "abreast, weapons to the 12 o'clock"],
        ["Use", "the most fire to the front, the least risk of hitting your own"],
        ["When", "called on contact, or when contact is expected"],
        ["Spacing", "5-10 m, by the situation"],
        ["Rear", "keep some rear security"],
    ], foot=INF),
    "inf_dismount": DG("Dismount", "inf/dismount.png", [
        ["Command team", "the driver's side"],
        ["Dismount team", "the other side and the rear"],
        ["Cover", "never directly in front of or behind the vehicle"],
        ["Security", "360 - every man faces out"],
    ], foot=INF),
    "inf_dismount_front": DG("Dismount Front", "inf/dismount_front.png", [
        ["Contact", "expected to the front"],
        ["Dismount team", "a line ahead of the vehicle, both sides of its nose"],
        ["Gun", "leave the vehicle's line of fire clear"],
        ["Command team", "the vehicle's sides and rear corners"],
    ], foot=INF),
    "inf_dismount_left": DG("Dismount Left", "inf/dismount_left.png", [
        ["Contact", "expected to the left"],
        ["Dismount team", "a line out on the left, facing the threat"],
        ["Command team", "covers the rear"],
    ], foot=INF),
    "inf_dismount_right": DG("Dismount Right", "inf/dismount_right.png", [
        ["Contact", "expected to the right"],
        ["Dismount team", "a line out on the right, facing the threat"],
        ["Command team", "covers the rear"],
    ], foot=INF),
    "inf_stack_normal": DG("Stacking - Normal", "inf/stack_normal.png", [
        ["Order", "1 at the door, team leader 3rd, the last man covers the rear"],
        ["Set", "1: \"Set\" - 2: \"Set\" - 3: \"Set\" - last: \"All set\""],
        ["Go", "1: \"Breaching, 3, 2, 1\""],
    ], foot=INF),
    "inf_stack_breacher": DG("Stacking - With Breacher", "inf/stack_breacher.png", [
        ["Breacher", "the engineer sets the charge and gets clear"],
        ["Set", "1: \"Set\" - 2: \"Set\" - 3: \"Set\" - last: \"All set\""],
        ["Go", "breacher: \"Breaching, 3, 2, 1\""],
    ], foot=INF),
    "inf_stack_expedient": DG("Stacking - Expedient", "inf/stack_expedient.png", [
        ["Two men", "no time for a full stack"],
        ["1st", "\"Breaching, 3, 2, 1\""],
        ["2nd", "\"Behind you\" or \"On your six\""],
    ], foot=INF),
    "inf_strong_points": DG("Strong Points", "inf/strong_points.png", [
        ["Corners", "all four - a threat can hide in any of them"],
        ["Centre", "the open middle of the room"],
        ["Clear", "every strong point is covered before \"Room clear\""],
    ], foot=INF),
    "inf_room_types": DG("Room Types", "inf/room_types.png", [
        ["Name", "a room is named for where its door is"],
        ["Corner fed", "door at one end of the wall - the room opens one way"],
        ["Centre fed", "door in the middle - the room opens both ways"],
    ], foot=INF),
    "inf_cqb_callouts": TB("CQB Call-Outs", [
        ("Call", 2.2), ("Means", 3.5), ("Call", 2.5, True), ("Means", 3.6),
    ], [
        ["BREACHER", "engineer, place the charge", "HELP L / R / FRONT", "more men needed there"],
        ["BREACHING", "breaching the door now", "OUTSIDE", "fire to or from outside"],
        ["SET", "ready to follow the breacher", "DRY HOLE", "room or building empty"],
        ["STATUS", "all report: clear and ready?", "MAN DOWN", "assaulter hit, out of the fight"],
        ["CLEAR", "my sector is clear", "CEASE FIRE", "all stop: unsafe act or injury"],
        ["ROOM CLEAR", "team leader: room secure", "GRENADE OUT / IN", "out: throwing - in: enemy grenade"],
        ["SHORT", "small room, do not enter", "GUN DOWN", "clearing a stoppage"],
        ["LONG", "take security deeper in", "GUN UP", "stoppage cleared, ready"],
        ["DOOR / ROOM", "+ direction: one to clear", "LOADING", "reloading - \"Gun up\" after"],
    ], foot=INF),
    "inf_feed_right": DG("Right Feed Room", "inf/feed_right.png", [
        ["Room", "door at the left end - the room opens to the right"],
        ["1st man", "goes deep, along the wall to the far corner"],
        ["2nd man", "takes the near corner"],
        ["Both", "face into the room"],
    ], foot=INF),
    "inf_feed_centre": DG("Centre Feed Room", "inf/feed_centre.png", [
        ["Room", "door in the middle - the room opens both ways"],
        ["1st man", "turns either way, along the wall to the corner"],
        ["2nd man", "goes the opposite way"],
        ["Sectors", "the two cross-cover the room"],
    ], sub="Go the opposite way to the man in front of you", foot=INF),
    "inf_feed_left": DG("Left Feed Room", "inf/feed_left.png", [
        ["Room", "door at the right end - the room opens to the left"],
        ["1st man", "goes deep, along the wall to the far corner"],
        ["2nd man", "takes the near corner"],
        ["Both", "face into the room"],
    ], foot=INF),
    "inf_hallway": DG("Hallways", "inf/hallway.png", [
        ["Pair", "two men back to back"],
        ["Front", "covers down the hall"],
        ["Rear", "covers the way you came"],
        ["Doors", "call each one as you reach it - \"Door left\""],
    ], foot=INF),
    "inf_corner": DG("Corners", "inf/corner.png", [
        ["1 Pie", "slice the corner from wide, a little at a time - the other man covers behind"],
        ["2 High, low", "one man crouches, one stands - two guns round the corner"],
        ["3 Round", "move round together, the rear man covers behind"],
    ], foot=INF),
    "inf_intersection": DG("Intersections", "inf/intersection.png", [
        ["1", "two men at the mouth, one covers behind"],
        ["2", "step out together - one covers left, one right"],
        ["3", "cross into the far hall, one up, one back"],
    ], sub="Move at the same time", foot=INF),
    "inf_herringbone": DG("Herringbone", "inf/herringbone.png", [
        ["Halt", "on the road, on the move"],
        ["Vehicles", "pull off to alternate sides, angled out"],
        ["Road", "the middle stays open"],
        ["Guns", "each vehicle covers its own side"],
    ], foot=INF),
    "inf_coil": DG("Coil", "inf/coil.png", [
        ["Halt", "a longer stop - all-round security"],
        ["Vehicles", "a ring, every one facing out"],
        ["Here", "1 holds the front, 2 and 3 the flanks, 4 the rear"],
    ], foot=INF),
    "inf_soft_dismount": DG("Soft Dismount", "inf/soft_dismount.png", [
        ["Stay", "gunners and drivers stay in the vehicles"],
        ["Out", "everyone else dismounts"],
        ["Security", "360 round the vehicles"],
    ], foot=INF),
    "inf_hard_dismount": DG("Hard Dismount", "inf/hard_dismount.png", [
        ["Out", "everyone dismounts"],
        ["Security", "360 round the vehicles"],
    ], foot=INF),

    # ---- ACE3 devices (2026-11-07): facts from ACE 3.21.2 (its keybinds,
    # functions and stringtables) ------------------------------------------
    "dagr": TB("MicroDAGR GPS", [
        ("Key / screen", 2.4), ("What it does or shows", 8.0),
    ], [
        ["Home", "open it - press again for the interactive mode"],
        ["Ctrl+Home", "close it"],
        ["Shift+Home", "cycle handheld devices, when you carry more than one"],
        ["Info", "MGRS grid, elevation MSL, heading, speed in kph, date and time"],
        ["Compass", "heading and speed - bearing and range to the set waypoint"],
        ["Map", "minimap - double-tap it to mark a waypoint there"],
        ["Mark", "type a grid, then a name - saves a waypoint"],
        ["Waypoints", "set or delete - a set waypoint shows its bearing, range and elevation"],
        ["Connect To", "the next Vector reading becomes the target"],
        ["Settings", "degrees or mils, waypoints on the map, magnetic north"],
    ], sub="Bottom buttons: Info, Compass, Map  ·  top bar: the menu",
       foot="ACE3 MicroDAGR  ·  keys under ACE3 Equipment"),

    "vector": TB("Vector 21 Rangefinder", [
        ("Do this", 3.6), ("Get this", 6.8),
    ], [
        ["Hold Tab", "azimuth - left readout, degrees"],
        ["Hold R, release", "distance - right readout, metres, 10 to 6000 m"],
        ["Tab + R together", "azimuth and distance - also sent to a connected MicroDAGR"],
        ["Tab twice, hold", "azimuth and inclination"],
        ["R twice, hold", "height and horizontal distance"],
        ["Hold R, tap Tab, aim, release", "distance between two points"],
        ["Hold Tab, tap R, aim, release", "azimuth and distance between two points"],
        ["Tab 5 times", "settings - metres or feet, degrees or mils"],
        ["R 5 times", "reticle and night brightness"],
    ], sub="Look through it first - the keys work only at the eyepiece",
       foot="ACE3 Vector  ·  keys under ACE3 Equipment  ·  Vector 21 Nite adds night vision"),

    "bct": T(["Basic Training"], under="Listen to the instructor. Ask questions."),

    "brief_1": T(["Briefing Area 1"]),
    "brief_2": T(["Briefing Area 2"]),
    "brief_3": T(["Briefing Area 3"]),
    "brief_4": T(["Briefing Area 4"]),
    "brief_5": T(["Briefing Area 5"]),
    "brief_6": T(["Briefing Area 6"]),
    "brief":   T(["Briefing"]),
    "aviation": T(["Combat Aviation"]),
}


def render(name, spec):
    if spec["kind"] == "image":
        return image_board(name, spec["src"])
    im = board()
    d = ImageDraw.Draw(im)
    badge(im)
    if spec["kind"] == "title":
        centred_title(im, d, spec["lines"], under=spec.get("under"))
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
    elif spec["kind"] == "numpad":
        header(im, d, spec["title"], spec.get("sub"))
        numpad(im, d, spec["keys"], spec["legend"])
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "fkeys":
        header(im, d, spec["title"], spec.get("sub"))
        fkeys(im, d, spec["keys"], spec["mods"], spec["legend"])
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "devices":
        header(im, d, spec["title"], spec.get("sub"))
        devices(im, d, spec["figs"], spec["key"], spec.get("plain", False))
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "steps":
        header(im, d, spec["title"], spec.get("sub"))
        steps(im, d, spec["items"])
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "rows":
        header(im, d, spec["title"], spec.get("sub"))
        rows(im, d, spec["items"])
        footer(im, d, spec.get("foot"))
        if spec.get("dots"):
            tracer_dots(d)
    elif spec["kind"] == "map":
        header(im, d, spec["title"], spec.get("sub"))
        map_board(im, d, spec["src"], spec["legend"], spec.get("layout", "side"))
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "table":
        header(im, d, spec["title"], spec.get("sub"))
        table(im, d, spec["cols"], spec["rows"])
        footer(im, d, spec.get("foot"))
    elif spec["kind"] == "diagram":
        header(im, d, spec["title"], spec.get("sub"))
        diagram(im, d, spec["src"], spec["notes"])
        footer(im, d, spec.get("foot"))
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
# PNG masters go to art/signs/fa (never shipped), PAAs into fa_main.
FA_OUT = os.path.join(ROOT, "art", "signs", "fa")
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
        # PNG masters in art/ (user, 2026-11-07: "pngs can go to art"), the
        # PAAs the game reads in the addon - as the FA boards do
        OUT = os.path.join(ROOT, "art", folder)
        paa_dir = os.path.join(IMG, folder)
        os.makedirs(OUT, exist_ok=True)
        os.makedirs(paa_dir, exist_ok=True)
        made = []
        for name, spec in sorted(SIGNS.items()):
            # --only a,b renders just those boards - the screenshot boards need
            # JMFSB_SIGN_ORIG and are drawn without their figure otherwise.
            if ONLY and name not in ONLY:
                continue
            if plain:
                spec = strip_area(spec)
            p = os.path.join(OUT, name + ".png")
            render(name, spec).save(p)
            made.append(p)
        print("%d PNG masters -> %s" % (len(made), OUT))
        if "--paa" in sys.argv:
            for p in made:
                paa = os.path.join(paa_dir, os.path.basename(p)[:-4] + ".paa")
                if os.path.exists(paa):
                    os.remove(paa)
                subprocess.run(["hemtt", "utils", "paa", "convert", p, paa],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("  converted to PAA -> %s" % paa_dir)

    if ONLY:
        return
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
