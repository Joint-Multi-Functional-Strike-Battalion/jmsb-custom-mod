# Stitch prompts — TAC//SUPPORT

Paste the style block first, then one screen prompt at a time.
Stitch does better with one screen per prompt than a whole flow.

Source: `DESIGN_SUPPORT_V2.md`. Mockups: canvas "TAC//APP UI mockups"
(Support2, AltCAS, AltArty, AltTrans).

---

## 1. Style block

```
Design system for a military tactical tablet app, used inside a video game (Arma 3).
Landscape tablet screen, 1364 x 1000 px. Dark theme only.

Colours:
- ground #20261C (background), raised panel #2A3125, map area #2D3328
- ink #E9E4D3 (main text), quiet text #B8B3A4, dim #8A8777
- divider lines #3A4234
- accent #C2A878 (tan): selection, primary buttons, armed state, alerts
- status green #7FA66A (ready / reachable), status red #C0523B (danger close, hot, no route)
- friendly units light blue #7FB3D9

Type: IBM Plex Sans Condensed for words, IBM Plex Mono for every number, grid
reference, time and callsign. Sizes: 13 px labels, 14 px body, 16–20 px key values.
Uppercase small labels with slight letter spacing; never letter-space names or numbers.

Shape: square corners, flat fills, 1 px row dividers, 2 px region dividers. No shadows,
no gradients, no rounded cards, no icons other than simple line glyphs.
Buttons: outline = available, tan fill = primary/selected, dim = unavailable.
Every list row 36–44 px tall. Dense but readable, like a real military fires app (ATAK, KILSWITCH).
```

---

## 2. Support board (map-first entry)

```
Screen "TAC//SUPPORT". The player calls in air strikes, artillery and helicopter transport.
The idea: the player clicks WHERE on the map first, and the app answers WHO can reach it.

Layout:
- Top bar 40 px: title "TAC//SUPPORT", filter chips "ALL 6", "CAS 3", "ARTY 2", "TRANS 1"
  (ALL selected), hint text "Click the map where you need it", CLOSE button right.
- Left rail 270 px wide, three stacked sections:
  IN FLIGHT: mission cards. One shows "RAVEN · EN ROUTE 1:10 · PICKUP > LZ 2" with a thin
  progress bar and small buttons SITREP / ABORT / RTB. One shows "THUNDER · SPLASH 0:12"
  in red with a red left edge. One finished line "HAWK · ATTACK RUN · DONE" with a BDA button.
  QUEUED TARGETS: one row "2 · 0477 7860 · BMP".
  READY: asset rows with a green dot, name, type line and ammo, e.g. "HOG · CAS · F/A-181 · 4 GBU".
- Centre: large top-down topographic map, dark muted. On it: a tan diamond target, a red
  danger-close ring around it, a dashed blue "FLOT" line of friendly units, a red impact ring
  elsewhere labelled "THUNDER · SPLASH 0:12", a numbered outline diamond "2 · QUEUED",
  a tan approach line "HOG · IN 045° · 2:40".
- A popup card on the map next to the target, 330 px wide, tan border:
  header "TARGET 0451 7829" with MOVE · CLR, a line "BMP · 2 INF · STATIC",
  "BEST FIT FIRST", then asset rows ranked: each row has name, ETA in mono on the right,
  one line of weapon info, and task buttons as chips
  (e.g. FOX 1-1 · ARTY · 0:48 · "155 HE · kill radius 50 m" · [ADJUST] [FFE 6 HE] [SMOKE] [ILLUM]).
  The top row is tagged "BEST FIT" and highlighted. Last line dim: "THUNDER · out of range (14 km, max 12)".
- Small legend bottom-left of the map: CLICK: TARGET · SHIFT-CLICK: QUEUE · ALT-CLICK: INGRESS/EGRESS · RIGHT-CLICK: LZ.
- Bottom order bar 72 px: the order as a sentence in large text
  "FOX 1-1 will ADJUST FIRE on 0451 7829", under it in red "DANGER CLOSE · Alpha 4-4 at 600 m · confirm twice",
  steppers "HE − 1 +", "SHEAF POINT", "ETA 0:48", and one big tan button "SEND · DANGER CLOSE".
```

---

## 3. CAS request

```
Screen "TAC//SUPPORT · CAS". A close-air-support request form next to a map.

- Top bar: title, small "template cas · thread T0042", and a step tracker on the right:
  DRAFT › ISSUED › WILCO › ON TASK › CLOSED (WILCO highlighted tan).
- Aircraft strip 54 px: "CHECK-IN  HOG  1x F/A-181 · 0388 7650 · 3000 M · 4 GBU-12 · 20 MIN · ABORT BLUE".
- Left column 600 px: the request as a table, columns LINE / FIELD / VALUE / FROM.
  Rows: Line 1 Grid reference 0451 7829 (FROM: MAP) · Line 2 Map reference TGT AB102 (MARKER)
  · Line 3 Ingress 0398 7712 (MAP) · Line 4 Egress 0420 7905 (MAP) · Line 5 Target description
  "BMP + 2 INF, STATIC" (TYPED) · Line 6 Range from friendlies "250 M · DANGER CLOSE" in red with a
  red left edge (BFT) · Line 7 Marked by: chips SMOKE / LASER 1688 (selected) / IR / TRACER / NONE
  · Preferred munitions GBU-12 (STORES) · Remarks empty.
  Under it a THREAD log: "12:03 BANSHEE 1-1 · CAS REQUEST · ISSUED", "12:03 HOG · ROGER",
  "12:04 HOG · WILCO · ETA 2:40" (tan).
  Footer buttons: big tan CLEARED HOT, outline ABORT, outline CLOSE.
- Right: map with ingress line to the target, egress line, red danger-close ring,
  friendly unit marker labelled "Alpha 4-4 · 250 M", drone marker "LASER 1688".
  Small legend: "Click fills the armed line · under 300 m ticks DANGER CLOSE".
```

---

## 4. Artillery: call for fire + adjust pad

```
Screen "TAC//SUPPORT · ARTY". Call for fire and round-by-round adjustment.

- Top bar: title, "FOX 1-1 · 155 SP · 24 RDS · TOF 32 S", steps CALL FOR FIRE › MTO › ADJUST (tan) › FFE › EOM.
- Left column 400 px, compact rows label/value in mono:
  Observer BANSHEE 1-1 · Warno 1 "A · ADJUST FIRE" · Warno 2 BATTERY · Warno 3 "GRID 0451 7829"
  with a small GRID/POLAR/SHIFT switch · Description "BMP + 2 INF IN THE OPEN" · Engage "A · HE · 6 RDS"
  · Danger close "DC · 600 M" in red · Control "B · AT MY COMMAND".
  A raised box "BATTERY REPLY: FOX · WILCO · 1 RD ADJ · 6 FFE · TOF 32".
  ROUNDS log: "1 · SPLASH · 80 OVER · 40 LEFT", "2 · DROP 100 RIGHT 50 · 20 SHORT",
  "3 · ADD 50 · IN FLIGHT · SPLASH 0:09" (tan).
- Right: map with observer at bottom-left, dashed observer-to-target line labelled "OT LINE 6100",
  target diamond, numbered grey splash dots 1 and 2, tan ring for round 3 with "0:09", dashed blue friendly line.
- Floating adjust pad on the map (300 px): a D-pad of big buttons ADD (top), LEFT, RIGHT, DROP (bottom),
  centre shows "50 M"; a step row 25 / 50 (selected) / 100 / 200 / 400; hint "or click the map where the
  next round should land"; outline button SEND CORRECTION; big tan button FIRE FOR EFFECT · 6;
  small row REPEAT / CHECK FIRE / EOM.
```

---

## 5. Transport (helicopter insert)

```
Screen "TAC//SUPPORT · TRANSPORT". Plan a helicopter lift from pickup zone to landing zone.

- Top bar: title, "RAVEN · UH-80 · 8 SEATS · FUEL 74%", CHANGE AIRCRAFT button.
- Route strip 120 px across the full width, read left to right:
  box "PZ · PICKUP · PB HAWKINS · 0413 1168 · COLD · GREEN SMOKE" (tan border)
  → line "4.2 KM · 1:40" → box "VIA · RP 1 · AVOID AA · 40 M AGL"
  → line "3.1 KM · 1:15" → box "LZ · INSERT · LZ FALCON · HOT" (red border)
  → dashed box "THEN · RTB · HOLD · LOITER".
- Left column 440 px:
  MANIFEST "7 / 8 SEATS" with a row of 8 seat blocks (4 green, 3 tan, 1 empty);
  squad rows "BANSHEE 1-1 · 4 · AT PZ", "ALPHA 4-5 · 3 · 300 M OUT" each with REMOVE;
  chips + MY SQUAD / + SQUAD AT PZ / + CARGO.
  HLZ BRIEF with a small switch HLZ / CASEVAC / AIRDROP, rows: Line 1 Location · Line 2 Name LZ FALCON
  · Line 3 Extract contents 7 PAX · Line 4 Security GREEN / YELLOW / RED (RED selected, red)
  · Line 5 Marking SMOKE RED · Line 6/7 Ingress/egress.
- Right: map with the route drawn as tan legs, a dashed red AA threat circle the route bends around,
  PZ and LZ circles.
- Bottom bar 64 px: sentence "RAVEN lifts 7 from HAWKINS to FALCON · wheels down 3:20",
  red "HOT LZ · confirm twice", big tan LAUNCH button.
```

---

## Notes

- If Stitch rounds corners or adds shadows, repeat the "square corners, no shadows" line in that prompt.
- Real screen is 1364 x 1000; if Stitch only offers web or mobile sizes, choose desktop.
- All numbers are sample data from the mockups; change freely.
