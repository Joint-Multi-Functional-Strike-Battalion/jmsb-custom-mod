#!/usr/bin/env python3
"""The radio family: model, textures and icon for jmfsb_radios, from the 3DMA assets.

SOURCES ARE NOT IN THE REPO. Radio_*_v01/ at the repo root are purchased
assets (3D Military Assets) and are gitignored; this script reads them and
writes the shippable derivatives into addons/radios/data. Without a source it
says so and skips that radio - check_art.py reports that as CANNOT CHECK, not
a failure. One table, RADIOS, says which parts of which OBJ make which radio.

WHAT IT MAKES, per radio <id>
  <id>.p3d          MLOD, three LODs: the visual model, a box geometry with
                    mass, and four land-contact points. hemtt build binarizes
                    it, which is also the validator.
  <id>_co.paa       base colour, 2048
  <id>_nohq.paa     tangent-space normals, 2048 (not referenced by the rvmat
                    until it has been seen in game - see the note below)
  <id>_smdi.paa     Arma's specular map: R unused, G specular, B gloss - from
                    the asset's metalness and roughness
  <id>_icon_ca.paa  inventory icon, a flat-shaded top view rendered here

AXES. The assets are Blender Z-up: a radio lies with its thickness along Z and
its length along Y. Arma is Y-up, left-handed. (x, y, z) -> (x, z, y) lays it
flat with its thickness up and its length forward, and that swap is a
reflection, which is exactly the handedness change - so the OBJ's
counter-clockwise faces come out clockwise, which is what Arma draws as
front-facing. FLIP_WINDING is the switch if that turns out wrong in game.
Normals in MLOD are stored inverted (the format's own convention); NEGATE_NORMALS
is the switch for that one. A model sits with its underside on y = 0 and
autocenter off, so a dropped radio lies on the ground rather than half in it.

Run:  python tools/gen_radios.py [id ...]       (all radios when none named)
      RADIOS_PREVIEW_DIR=<dir> keeps the icon previews for a look.
"""

import os
import shutil
import struct
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
OUT = os.path.join(ROOT, "addons", "radios", "data")
PREFIX = "z\\jmfsb\\addons\\radios\\data"

# id -> source folder, OBJ, texture stem, the object names that make the
# radio (the rest of the file is other kit), mass in kg.
RADIOS = {
    "mpu5": {
        "src": "Radio_MPU5_v01",
        "obj": os.path.join("Mesh", "MPU5.obj"),
        "tex": "MPU5",
        # The radio and its PTT. The pouch, the patch and the two tablet
        # meshes in the same file are other items and are left for later.
        "parts": ("MPU5_Mesh", "MPU5_PTT_Mesh"),
        "mass": 1.2,
        # The open-radio dialog's background: the vendor's product shot, with
        # the user's green annotation painted out (that box, in source pixels),
        # on a 1024 square with the white cut to transparent.
        "dialog": {"image": "tfar screen.jpg", "paint_out": (536, 140, 868, 372)},
    },
    "tw950": {
        "src": "Radio_TrellisWare_v01",
        "obj": os.path.join("Mesh", "TrellisWare_TW-950.obj"),
        "tex": "TrellisWare_TW-950",
        # The body and the long antenna. antenna_02 and antenna_03 are the
        # same antenna at other lengths - alternates, not extras.
        "parts": ("TrellisWare_redio_Cylinder", "antenna_01_low_Cylinder"),
        "mass": 0.8,
    },
}

TEX_SIZE = 2048
ICON_W, ICON_H = 256, 256

FLIP_WINDING = False
NEGATE_NORMALS = True

# LOD resolutions, as Object Builder names them.
LOD_VISUAL = 1.0
LOD_GEOMETRY = 1.0e13
LOD_LANDCONTACT = 2.0e15


# --------------------------------------------------------------------- OBJ --

def read_obj(path, parts):
    verts, uvs, norms = [], [], []
    faces = []          # [(vi, ti, ni), ...] triangles
    part = ""
    with open(path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            t = line.split()
            if not t:
                continue
            if t[0] == "o":
                part = t[1].split(".")[0]
            elif t[0] == "v":
                verts.append(tuple(float(v) for v in t[1:4]))
            elif t[0] == "vt":
                uvs.append((float(t[1]), float(t[2])))
            elif t[0] == "vn":
                norms.append(tuple(float(v) for v in t[1:4]))
            elif t[0] == "f" and part in parts:
                poly = []
                for w in t[1:]:
                    vi, ti, ni = (w.split("/") + ["", ""])[:3]
                    poly.append((int(vi) - 1, int(ti) - 1 if ti else -1, int(ni) - 1 if ni else -1))
                # fan any polygon into triangles; MLOD takes tris and quads but
                # a fan is one rule for everything
                for i in range(1, len(poly) - 1):
                    faces.append((poly[0], poly[i], poly[i + 1]))
    if not faces:
        raise SystemExit("%s: none of %s found in the OBJ" % (path, parts))
    return np.array(verts), np.array(uvs), np.array(norms), faces


def to_arma(p):
    """Blender Z-up to Arma Y-up: (x, y, z) -> (x, z, y)."""
    return np.stack([p[:, 0], p[:, 2], p[:, 1]], axis=1)


# -------------------------------------------------------------------- MLOD --

def asciiz(s):
    return s.encode("latin-1") + b"\0"


def tagg(name, data):
    return b"\x01" + asciiz(name) + struct.pack("<I", len(data)) + data


def property_tagg(key, value):
    return tagg("#Property#", key.encode().ljust(64, b"\0") + value.encode().ljust(64, b"\0"))


def selection_tagg(name, n_points, n_faces):
    return tagg(name, bytes([1] * n_points) + bytes([1] * n_faces))


def lod_bytes(points, normals, faces, taggs, resolution):
    """One P3DM LOD. faces: list of ([(point, normal, u, v), ...], texture, material)."""
    out = [b"P3DM", struct.pack("<IIIIII", 0x1C, 0x100, len(points), len(normals), len(faces), 0)]
    for x, y, z in points:
        out.append(struct.pack("<fffI", x, y, z, 0))
    for x, y, z in normals:
        out.append(struct.pack("<fff", x, y, z))
    uvset = [struct.pack("<I", 0)]
    for verts, texture, material in faces:
        out.append(struct.pack("<I", len(verts)))
        for i in range(4):
            if i < len(verts):
                p, n, u, v = verts[i]
                out.append(struct.pack("<IIff", p, n, u, v))
                uvset.append(struct.pack("<ff", u, v))
            else:
                out.append(struct.pack("<IIff", 0, 0, 0.0, 0.0))
                uvset.append(struct.pack("<ff", 0.0, 0.0))
        out.append(struct.pack("<I", 0))
        out.append(asciiz(texture))
        out.append(asciiz(material))
    out.append(b"TAGG")
    out.extend(taggs)
    out.append(tagg("#UVSet#", b"".join(uvset)))
    out.append(tagg("#EndOfFile#", b""))
    out.append(struct.pack("<f", resolution))
    return b"".join(out)


def build_p3d(rid, verts, uvs, norms, faces, mass_kg):
    used_v = sorted({v for tri in faces for v, _, _ in tri})
    used_n = sorted({n for tri in faces for _, _, n in tri if n >= 0})
    vmap = {v: i for i, v in enumerate(used_v)}
    nmap = {n: i for i, n in enumerate(used_n)}

    pts = to_arma(verts[used_v])
    # Underside on y = 0, centred in x and z.
    lo, hi = pts.min(axis=0), pts.max(axis=0)
    pts = pts - np.array([(lo[0] + hi[0]) / 2, lo[1], (lo[2] + hi[2]) / 2])
    lo, hi = pts.min(axis=0), pts.max(axis=0)

    nrm = to_arma(norms[used_n]) if used_n else np.zeros((1, 3))
    nrm = nrm / np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-9)
    if NEGATE_NORMALS:
        nrm = -nrm

    texture = "%s\\%s_co.paa" % (PREFIX, rid)
    material = "%s\\%s.rvmat" % (PREFIX, rid)
    vis_faces = []
    for tri in faces:
        if FLIP_WINDING:
            tri = tri[::-1]
        verts_out = []
        for v, t, n in tri:
            u, vv = (uvs[t] if t >= 0 else (0.0, 0.0))
            verts_out.append((vmap[v], nmap[n] if n >= 0 else 0, float(u), float(1.0 - vv)))
        vis_faces.append((verts_out, texture, material))

    visual = lod_bytes(pts, nrm, vis_faces, [property_tagg("autocenter", "0")], LOD_VISUAL)

    # Geometry: one convex box round the whole thing, with the mass on it.
    bx = [(x, y, z) for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])]
    # corner index: x*4 + y*2 + z
    quads = [
        [0, 1, 3, 2],   # -x
        [4, 6, 7, 5],   # +x
        [0, 4, 5, 1],   # -y
        [2, 3, 7, 6],   # +y
        [0, 2, 6, 4],   # -z
        [1, 5, 7, 3],   # +z
    ]
    box_normals = [(-1, 0, 0), (1, 0, 0), (0, -1, 0), (0, 1, 0), (0, 0, -1), (0, 0, 1)]
    if NEGATE_NORMALS:
        box_normals = [(-a, -b, -c) for a, b, c in box_normals]
    geo_faces = []
    for qi, q in enumerate(quads):
        if FLIP_WINDING:
            q = q[::-1]
        geo_faces.append(([(i, qi, 0.0, 0.0) for i in q], "", ""))
    mass = struct.pack("<%df" % len(bx), *([mass_kg / len(bx)] * len(bx)))
    geometry = lod_bytes(bx, box_normals, geo_faces, [
        selection_tagg("Component01", len(bx), len(geo_faces)),
        tagg("#Mass#", mass),
        property_tagg("autocenter", "0"),
        property_tagg("class", "none"),
    ], LOD_GEOMETRY)

    # Land contact: the four underside corners, points only.
    lc = [(x, 0.0, z) for x in (lo[0], hi[0]) for z in (lo[2], hi[2])]
    landcontact = lod_bytes(lc, [], [], [], LOD_LANDCONTACT)

    lods = [visual, geometry, landcontact]
    return b"MLOD" + struct.pack("<II", 257, len(lods)) + b"".join(lods), pts, vis_faces, (lo, hi)


# ---------------------------------------------------------------- textures --

def to_paa(png, paa):
    hemtt = shutil.which("hemtt")
    if not hemtt:
        raise SystemExit("hemtt not on PATH - cannot write %s" % paa)
    # hemtt REFUSES TO OVERWRITE, and says so with exit code 0 - so a rerun
    # after a texture change silently kept the old file. The target goes first.
    if os.path.exists(paa):
        os.remove(paa)
    subprocess.run([hemtt, "utils", "paa", "convert", png, paa], check=True, capture_output=True)
    if not os.path.exists(paa):
        raise SystemExit("hemtt did not write %s" % paa)


def textures(rid, src, stem, tmp):
    tex = os.path.join(src, "Textures")

    def load(kind, mode):
        return Image.open(os.path.join(tex, "%s_%s.png" % (stem, kind))).convert(mode).resize((TEX_SIZE, TEX_SIZE), Image.LANCZOS)
    base = load("BaseColor", "RGB")
    normal = load("Normal", "RGB")
    metal = np.asarray(load("Metalness", "L")).astype(np.float32) / 255
    rough = np.asarray(load("Roughness", "L")).astype(np.float32) / 255

    # SMDI: R unused (full), G specular - dielectric 0.2, metal up to 0.9 -
    # B gloss, the inverse of roughness.
    spec = (0.2 + 0.7 * metal) * 255
    gloss = (1.0 - rough) * 255
    smdi = np.dstack([np.full_like(spec, 255), spec, gloss]).astype(np.uint8)

    for suffix, im in (("co", base), ("nohq", normal), ("smdi", Image.fromarray(smdi, "RGB"))):
        name = "%s_%s" % (rid, suffix)
        png = os.path.join(tmp, name + ".png")
        im.save(png)
        to_paa(png, os.path.join(OUT, name + ".paa"))
        print("  wrote", name + ".paa")
    return base


# -------------------------------------------------------------------- icon --

def icon(rid, pts, faces, bounds, base, tmp):
    """Flat-shaded top view, upright - antenna up - on transparent ground."""
    lo, hi = bounds
    # image x <- model x (width), image y <- model z (length, +z at the top)
    span_z = hi[2] - lo[2]
    span_x = hi[0] - lo[0]
    scale = min((ICON_W - 16) / span_x, (ICON_H - 16) / span_z)
    ox = (ICON_W - span_x * scale) / 2
    oy = (ICON_H - span_z * scale) / 2
    rgba = np.zeros((ICON_H, ICON_W, 4), np.uint8)
    depth = np.full((ICON_H, ICON_W), -1e9, np.float32)
    tex = np.asarray(base)
    light = np.array([0.3, 0.9, -0.3])
    light /= np.linalg.norm(light)
    for verts, _, _ in faces:
        p = np.array([pts[v[0]] for v in verts[:3]])
        n = np.cross(p[1] - p[0], p[2] - p[0])
        if np.linalg.norm(n) < 1e-12:
            continue
        n /= np.linalg.norm(n)
        if n[1] < 0:
            n = -n
        shade = 0.55 + 0.45 * max(0.0, float(n @ light))
        u = np.mean([v[2] for v in verts[:3]])
        vv = np.mean([v[3] for v in verts[:3]])
        tx = int(min(max(u, 0), 0.9999) * tex.shape[1])
        ty = int(min(max(vv, 0), 0.9999) * tex.shape[0])
        # The radios are black; an icon of one needs lifting or it is a
        # silhouette. Gamma up, then a floor, then the light.
        albedo = (tex[ty, tx].astype(np.float32) / 255) ** 0.6
        col = np.clip((0.25 + 0.75 * albedo) * shade * 255, 0, 255)
        sx = ox + (p[:, 0] - lo[0]) * scale
        sy = oy + (hi[2] - p[:, 2]) * scale
        z = p[:, 1]
        x0, x1 = int(max(sx.min(), 0)), int(min(sx.max(), ICON_W - 1)) + 1
        y0, y1 = int(max(sy.min(), 0)), int(min(sy.max(), ICON_H - 1)) + 1
        if x1 <= x0 or y1 <= y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
        d = (sx[1] - sx[0]) * (sy[2] - sy[0]) - (sx[2] - sx[0]) * (sy[1] - sy[0])
        if abs(d) < 1e-9:
            continue
        w0 = ((sx[1] - gx) * (sy[2] - gy) - (sx[2] - gx) * (sy[1] - gy)) / d
        w1 = ((sx[2] - gx) * (sy[0] - gy) - (sx[0] - gx) * (sy[2] - gy)) / d
        w2 = 1 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        zz = w0 * z[0] + w1 * z[1] + w2 * z[2]
        sub = depth[y0:y1, x0:x1]
        win = inside & (zz > sub)
        sub[win] = zz[win]
        rgba[y0:y1, x0:x1][win] = np.array([col[0], col[1], col[2], 255], np.uint8)
    png = os.path.join(tmp, "%s_icon_ca.png" % rid)
    Image.fromarray(rgba, "RGBA").save(png)
    to_paa(png, os.path.join(OUT, "%s_icon_ca.paa" % rid))
    print("  wrote %s_icon_ca.paa" % rid)
    keep = os.environ.get("RADIOS_PREVIEW_DIR")
    if keep:
        os.makedirs(keep, exist_ok=True)
        shutil.copy(png, os.path.join(keep, "%s_icon_preview.png" % rid))


# ------------------------------------------------------------------ dialog --

DIALOG_SIZE = 1024


def dialog_background(rid, src, spec, tmp):
    """The radio's open-dialog picture: the product shot scaled to a 1024
    square, centred, annotation painted out, white cut to transparent by flood
    fill from the corners. The canvas placement is printed so the dialog's
    knob rectangles can be taken off it (see addons/radios/dialog.hpp)."""
    from PIL import ImageDraw
    im = Image.open(os.path.join(src, spec["image"])).convert("RGB")
    x0, y0, x1, y1 = spec["paint_out"]
    ImageDraw.Draw(im).rectangle((x0, y0, x1, y1), fill=(255, 255, 255))
    w, h = im.size
    k = DIALOG_SIZE / max(w, h)
    nw, nh = int(round(w * k)), int(round(h * k))
    im = im.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGB", (DIALOG_SIZE, DIALOG_SIZE), (255, 255, 255))
    ox, oy = (DIALOG_SIZE - nw) // 2, (DIALOG_SIZE - nh) // 2
    canvas.paste(im, (ox, oy))
    work = canvas.copy()
    for seed in ((0, 0), (DIALOG_SIZE - 1, 0), (0, DIALOG_SIZE - 1), (DIALOG_SIZE - 1, DIALOG_SIZE - 1)):
        ImageDraw.floodfill(work, seed, (255, 0, 255), thresh=28)
    arr = np.asarray(work)
    cut = np.all(arr == np.array((255, 0, 255), np.uint8), axis=2)
    alpha = np.where(cut, 0, 255).astype(np.uint8)
    # NO WHITE EDGE. The antialiased rim between the frame and the white it
    # was shot on is neither white enough to flood nor dark enough to keep,
    # and drawn opaque it is a pale halo round the whole radio. Two pixels in
    # from the cut get alpha from how far below white they are, and every cut
    # pixel is painted black so the texture filter blends the rim toward dark
    # instead of toward the white that used to be there.
    rgb = np.asarray(canvas).copy()
    lum = rgb.astype(np.float32).mean(axis=2)
    ring = np.zeros_like(cut)
    for _ in range(2):
        grow = ring | cut
        nxt = np.zeros_like(cut)
        nxt[1:, :] |= grow[:-1, :]
        nxt[:-1, :] |= grow[1:, :]
        nxt[:, 1:] |= grow[:, :-1]
        nxt[:, :-1] |= grow[:, 1:]
        ring |= nxt & ~cut
    feather = np.clip((255 - lum) * (255.0 / (255 - 150)), 0, 255).astype(np.uint8)
    alpha = np.where(ring, np.minimum(alpha, feather), alpha)
    rgb[cut] = 0
    out = Image.fromarray(np.dstack([rgb, alpha]), "RGBA")
    png = os.path.join(tmp, "%s_dialog_ca.png" % rid)
    out.save(png)
    to_paa(png, os.path.join(OUT, "%s_dialog_ca.paa" % rid))
    print("  wrote %s_dialog_ca.paa  (source %dx%d scaled %.4f, placed at %d,%d)" % (rid, w, h, k, ox, oy))
    keep = os.environ.get("RADIOS_PREVIEW_DIR")
    if keep:
        os.makedirs(keep, exist_ok=True)
        shutil.copy(png, os.path.join(keep, "%s_dialog_preview.png" % rid))


# -------------------------------------------------------------------- main --

def one(rid, spec):
    src = os.path.join(ROOT, spec["src"])
    obj = os.path.join(src, spec["obj"])
    if not os.path.exists(obj):
        print("%s: %s not in this checkout - skipped" % (rid, obj))
        return False
    os.makedirs(OUT, exist_ok=True)
    verts, uvs, norms, faces = read_obj(obj, spec["parts"])
    p3d, pts, vis_faces, bounds = build_p3d(rid, verts, uvs, norms, faces, spec["mass"])
    with open(os.path.join(OUT, rid + ".p3d"), "wb") as f:
        f.write(p3d)
    lo, hi = bounds
    print("%s.p3d: %d points, %d faces, size %.3f x %.3f x %.3f m (w x h x l)" % (
        rid, len(pts), len(vis_faces), hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]))
    tmp = tempfile.mkdtemp()
    try:
        base = textures(rid, src, spec["tex"], tmp)
        icon(rid, pts, vis_faces, bounds, base, tmp)
        if "dialog" in spec:
            dialog_background(rid, src, spec["dialog"], tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return True


def main():
    wanted = sys.argv[1:] or list(RADIOS)
    unknown = [w for w in wanted if w not in RADIOS]
    if unknown:
        raise SystemExit("unknown radio(s) %s - known: %s" % (unknown, list(RADIOS)))
    made = sum(1 for w in wanted if one(w, RADIOS[w]))
    if made == 0:
        raise SystemExit("no radio source present")
    return 0


if __name__ == "__main__":
    sys.exit(main())
