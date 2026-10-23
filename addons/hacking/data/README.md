# Vendored art and models

## MRHMilsimTools

Everything in this folder except `icons/` comes from **MRHMilsimTools** by Mr H., which is licensed
**ADPL-SA** (Arma Public Licence – Share Alike). That permits redistribution and
modification within Arma 3 with attribution, on the same terms. JMSB is APL-SA,
which is compatible.

Contrast the GPL mods (ALiVE, AXE): jmfsb may reference their behaviour but never
copy their source — see `docs/DESIGN_INTEL_SYSTEM.md` §0.

| File | Source in MRHMilsimTools | Used for |
|---|---|---|
| `tablet.paa` | `MRHSoldierTab/paa/tablet.paa` | Bezel behind the hacking tablet dialog — **rebranded**, see below |
| `phone.paa` | `MRHFunctions/img/hackphone/hackphone.paa` | Handset behind the signal scanner screen |
| `hackphone_icon.paa` | `MRHFunctions/models/hackphone/hackphoneIcon.paa` | Inventory icon for the Signal Scanner |

The two MRH item models (`soldiertab.p3d`, `hackphone.p3d`) were dropped earlier - the
items use base-game models - and their textures and the tablet's inventory icon
(`soldiertabtext.paa`, `p/hackphonetexture.paa`, `tablet_icon.paa`) went with them on
2026-10-07, when tools/slim_assets.py removed every asset nothing named.

Everything drawn *inside* the tablet and scanner screens is jmfsb-original.

`tablet.paa` is **not** the file as vendored: `tools/gen_tablet_bezel.py` paints
out the "MRHTECH" wordmark on the chin and stamps the jmfsb logo there instead.
The untouched vendored copy lives at `art/tablet_src.paa` — kept outside
`addons/` so a 1.1 MB source image is not packed into the pbo — and the script
always regenerates from it, so it can be rerun and retuned freely.

Note the two bezels are **square images of non-square devices** (`tablet.paa` is a
landscape tablet in a 2048² canvas, `phone.paa` a handset in a 512²). Their
controls must be sized accordingly or the device shears — `fnc_tabletLayout` keeps
its control square, and `fnc_scannerLayout` stretches to `SCN_ASPECT`, which is
the same stretch MRH's own dialog applies to the handset.

## icons/

Line-art glyphs sliced from a stock signals-intelligence icon sheet supplied by
the mod author (`AdobeStock_1965363267`), by `tools/gen_hack_icons.py`. **Confirm
the Adobe Stock licence covers redistribution in a released mod before shipping
these** — everything else in this folder is share-alike, this is not.

They are white on transparent so Arma's `colorText` tints them, which is what
lets a scanner row's glyph take the same state colour as its text for free.

| File | Sheet caption | Used for |
|---|---|---|
| `signal.paa` | Signal Waves | UAV row; Signal Scanner self-action |
| `jam.paa` | Signal Jamming | JAM row |
| `broken.paa` | Broken Signal | JAM row when the field is total |
| `mesh.paa` | Data Flow Tap | MESH row |
| `antenna.paa` | Antenna | NET row |
| `intercept.paa` | Interception Device | Hacking Tablet self-action |
| `listen.paa` | Listening System | *spare* — SIGINT product |
| `comms.paa` | Communication Interception | *spare* — remote unit hack |
| `uplink.paa` | Satellite Dish | *spare* — tower / uplink |
| `wireless.paa` | Wireless Hacking | *spare* — hack in progress |

