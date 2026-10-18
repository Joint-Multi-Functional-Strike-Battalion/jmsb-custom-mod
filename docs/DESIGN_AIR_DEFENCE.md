# Air defence - design

Status: BUILT 2026-10-07 as `addons/adsite` (all of F1-F12), NOT YET VERIFIED IN GAME - run Phase 0
(`#jmfsb adsite.probe`) and `docs/TESTS.md` section 12 first. The engagement brain is its own addon, `adsite`:
`airdefence` already used `sites` for its placement records, so the two stay apart - `airdefence` places,
`iads` runs the radars, `adsite` engages for both. Asked for by the user ("do we still have integrated aa" -> "all 3"), with two requirements of
their own on top of the feature list: **warnings are jmfsb notices**, and **the Site's status and
controls live in jmfsb's UI** (the tacpad), not in a terminal dialog of their own.

## What is asked for

| # | Feature | Where it lives |
|---|---|---|
| F1 | Shoots down munitions as well as aircraft: missiles, rockets, bombs, artillery, mortar and MLRS rounds, tracked and intercepted, with a real proximity fuse on the interceptor | `jmfsb_adsite` - the engagement core |
| F2 | Uses each vehicle as it is: roles, sensors, reach and envelopes read from its own config and loadout; fires its own weapons, so ballistics, guidance and damage are the game's | `adsite` - `fnc_profileVehicle` |
| F3 | Coordinated, layered defence: a Site pools what its sensors see and gives each threat to the best-fit weapon; short range takes the bulk of a salvo, long range is held for what only it can reach, guns are the inner layer | `adsite` - `fnc_assign` |
| F4 | Only engages what threatens it: hostile aircraft by side relations; munitions only while their predicted impact is inside the Site's protected area | `adsite` - `fnc_threatens` |
| F5 | Radar emission control: automatic, silent until cued, or burst search handed radar to radar; shut down for an anti-radiation missile | `jmfsb_iads` (exists: blink + duty floor) grown into this |
| F6 | Human-feeling crews: skill and temperament set reaction time and reliability, no fixed timer | `adsite` - `fnc_crewDelay` |
| F7 | CIWS that corrects its own aim from where its rounds go, and only fires where a burst has a real chance | `adsite` - `fnc_ciws` |
| F8 | Linked Sites: one picture, one coordinator, no two missiles on one target | `airdefence` - the coordinator |
| F9 | Alarms: going-live and incoming, per Site | **jmfsb notices** (`jmfsb_notify_fnc_broadcast`) - user, 2026-10-07: "warning should be a notice" |
| F10 | Site terminal: live status, the Site's settings, a manual interception page with a map (chosen weapon onto chosen track, automation off, radar control), surface strikes on a ground point | **the tacpad** panel (`adsite` - `fnc_panel`) - user, 2026-10-07: "integrate into the ui". Built as a map panel like `aps`', not an app + live tile |
| F11 | Zeus: every Site setting and vehicle override editable live (Zeus Enhanced) | `airdefence` - ZEN attributes |
| F12 | Runs on the server: all detection and engagement server-side | everywhere |

## The rules it is built under (AGENTS.md, binding)

- **ALiVE wins / adapter seam.** `airdefence` already places batteries from each commander's TAOR through
  `jmfsb_common`; nothing here names an ALiVE symbol. A Site is either one `airdefence` placed (profiled) or one
  a mission maker builds in Eden by syncing vehicles to a **JMSB - Air Defence Site** module.
- **Sides typed once (D59).** A Site's side is its vehicles' side; what it engages is asked of the engine
  (`getFriend` / `side` relations of the target's side), exactly as `iads` derives "every side the players are not on".
  No side attribute anywhere.
- **Settings are operation values only.** Ranges, reserves, delays, chances. *Where* a Site is and *what is in it*
  come from the module's sync or from `airdefence`'s ALiVE placement - never from a setting.
- **No dead knobs.** Every module attribute and CBA setting below is read by named code; `check_plumbing.py` gates it.
- **Server-side.** Detection, assignment and engagement run on the server. Clients only draw (tacpad, notices) and
  send orders back through a CBA server event.

## Architecture

```
            sensors (radars, IRST, the vehicles' own)           jmfsb_iads
                     |  getSensorTargets / listRemoteTargets         | emission control (F5)
                     v                                               v
  incoming munitions --> fnc_track --> Site picture <------- one per Site, or per LINK (F8)
  (Fired EH, server)        |              |
                            v              v
                       fnc_threatens   fnc_assign  -- layered weapon-target assignment (F3)
                            (F4)           |
                                           v
                        fnc_engage  -- the vehicle's own weapon (F2), after fnc_crewDelay (F6)
                           |    \
                     missile     gun / CIWS (F7: aim corrected from observed miss)
                           |
                     fnc_fuze  -- proximity kill (F1), aps's intercept pattern
```

### The Site

A hashmap on the server, `GVAR(sites)`: id, side, member vehicles with each one's **profile** (F2), the protected
area (centre + radius, or the module's area), the link group (F8), automation on/off, and the picture: tracks keyed
by object, each with class (aircraft / missile / rocket / bomb / shell / mortar / MLRS), first seen, predicted impact
or closest approach, threat state, and the weapons already committed to it.

### Vehicle profile (F2)

Read once per class and cached: every turret's weapons and their magazines' ammo (`maxRange`, `airLock`,
`irLock`/`laserLock`/`radar` guidance, `maneuvrability`, `initSpeed`, `hit`, `indirectHitRange`), and the vehicle's
`Components >> SensorsManagerComponent` (radar range, angle, `minRange`, ground-clutter). A launcher with no radar
of its own is a **shooter that needs a cue** - the case `iads`' P0-3 is still unverified for. Roles fall out of
the numbers, not a list: long-range SAM, short-range SAM, gun, CIWS, sensor-only.

### Tracking munitions (F1)

The server adds `Fired` to every vehicle and man of every side hostile to some Site (CBA class event handlers on
`AllVehicles` / `CAManBase`, not a scan). A fired round is tracked if it is a missile, rocket, bomb, or artillery /
mortar / MLRS shell (by `simulation` and the ammo's own figures) and its **predicted impact point** - ballistic for
a shell, current heading and remaining motor for a rocket, `missileTarget` for a guided missile - lies inside some
Site's protected area plus a margin (F4: a shell landing clear costs nothing). Each tracked round costs one per-frame
position check while it flies; the README will publish what a sweep costs, as `iads` does.

### Assignment (F3)

Per Site, each beat: threats sorted by time-to-impact. For each, the cheapest weapon that can still reach it
**before impact and outside its own minimum range** gets it:

1. CIWS / guns for anything inside their envelope - the inner layer, and the only answer to most shells.
2. Short-range missiles for the bulk of a salvo.
3. Long-range missiles are held in reserve (`reserveLong` = a fraction of their rounds) for what only they can
   reach - aircraft at range, ballistic threats outside the short layer - unless nothing else can take it.

A threat has at most `shotsPerThreat` committed weapons; a linked Site's coordinator sees every member's commitments,
so two batteries never fire at one round (F8).

### Engaging with the vehicle's own weapon (F2, F6)

After the crew's delay - `fnc_crewDelay`: base reaction from `skill` (`aimingSpeed`, `spotTime`, `commanding`),
a temperament draw per crew that stays with them for the mission, and a reliability chance of a fumble that costs a
second - the gunner is given the target (`doWatch`, `doTarget`) and fires its own weapon (`fireAtTarget`, or
`forceWeaponFire` for a CIWS mode). Guided missiles fired at a munition are steered with `setMissileTarget`.
Nothing about the shot is simulated: what flies is the game's own round.

**The proximity fuse** (`fnc_fuze`): an interceptor in flight is checked against its target each frame; inside the
ammo's `indirectHitRange` (or a fuse distance from the module) it detonates (`triggerAmmo`) and the target is
destroyed with its own explosion where the game would do that. This is `aps`' `fnc_intercept` pattern, which
already destroys rockets and missiles short of a hull.

### CIWS (F7)

A gun in the CIWS role fires bursts only when the predicted miss distance is under its burst's spread at that range
(the "real chance" test). After each burst it watches where its rounds passed the target and corrects its lead
(an offset carried per target, decayed per burst) - the aim correction the feature list describes, done by
adjusting the `doWatch` point ahead of the threat.

### Emission control (F5) - `jmfsb_iads`

`iads` already does the blinking with a duty-cycle floor and a shared datalink picture. It grows three modes per
Site: **automatic** (today's blink), **silent until cued** (radars dark until a passive sensor, a linked Site or a
tracked launch cues them), and **burst search** (one radar lit for a burst, then the next - handed round the Site).
**ARM response**: a missile whose ammo is anti-radiation (`ARM` guidance flags) tracked against a lit radar
turns that radar off until the missile is gone, and the Site relies on the rest. `iads`' Phase 0 questions
(P0-1..4) are still open and are run first (below).

### Alarms -> jmfsb notices (F9)

No sounds of the Site's own. Through `jmfsb_notify_fnc_broadcast`, the widget every jmfsb system already uses:

- **Going live** - when a Site's radars first light in a mission or after a silence: "AIR DEFENCE - <Site> radiating"
  to players on the Site's side within its area (or linked group).
- **Incoming** - when a tracked threat is assigned against a Site: "INCOMING - <class> on <Site>, <seconds>s" to
  the same players, at most once per threat, coalesced for a salvo ("INCOMING - 6 rockets ...").

Rate-limited per Site so a barrage is one notice, not forty. The notice history (`jmfsb_notify` keeps it) is the
log. A mission maker who wants a sound plays it off the CBA event the notice is raised from.

### The UI -> the tacpad (F10)

The Site terminal is a **tacpad app**, `AIR DEFENCE`, registered with `jmfsb_tacpad_fnc_registerApp` exactly as
`aps` and `pac` register theirs, plus a **live tile** on `tacpad_apps`' band (Sites up / threats tracked /
rounds left).

- **STATUS** - each Site of the player's side: members, role, rounds, radar state, automation, threats.
- **SETTINGS** - the Site's operation values, for whoever the access rule allows.
- **INTERCEPT** - the tacpad already sits on the map: tracks are drawn on it, the player picks one, then a weapon
  from the members that can reach it, and the order is sent to the server. Automation off, radar on / off / burst.
- **STRIKE** - a ground point clicked on the map and a member with a surface-capable weapon (`fnc_profileVehicle`
  knows) to put on it.

Who may open which page is a module attribute: everyone on the side sees STATUS; SETTINGS / INTERCEPT / STRIKE
need to be a crewman of a Site member, near one of its vehicles, or the side's commander slot - set per Site,
never a global setting (WHO is not an operation value).

### Zeus (F11)

With Zeus Enhanced loaded, the Site module and every member vehicle get ZEN attributes for the same values the
module carries; an edit goes to the server through the same event the tacpad uses. Without ZEN the Site is Eden-only.

## Phase 0 - the engine questions, before code depends on them

Code built on an unverified engine guess runs, logs success, and does the opposite (the lesson `iads`' README
records). So these are a `#jmfsb airdefence.probe`, as `iads.probe` is:

| | Question | If the answer is no |
|---|---|---|
| A0-1 | Does `setMissileTarget` steer a SAM onto a **shell / rocket** object, not just a vehicle? | Guided intercepts of munitions are flown by the fuse alone: the SAM is fired at the threat's predicted point and the proximity check does the rest |
| A0-2 | Does `fireAtTarget` fire an AI gunner's SAM at an object that is not a vehicle? | `forceWeaponFire` with the gunner already watching the point |
| A0-3 | Do vehicle sensors report munitions (`getSensorTargets` showing missiles/shells)? | Munitions come only from the `Fired` tracker (planned that way anyway); sensors cue aircraft |
| A0-4 | Is `Fired` on every hostile shooter affordable on a full ALiVE server? | The tracker registers only shooters inside `trackRange` of a Site, refreshed on a slow beat |
| A0-5 | `iads` P0-1..4 (radar on/off values, datalink shape, cued firing, passive sensors) | as `iads`' README says |

## Build order

1. **Phase 0 probe** (A0-1..5) - one session in the editor with the probe; the answers decide 2-4's code paths.
2. **Site + profile + assignment against aircraft** - F2, F3, F4 (aircraft half), F8, F12 on `airdefence`'s
   batteries and the Eden module. Notices (F9).
3. **Munition tracking and the fuse** - F1, F4 (munition half), CIWS (F7).
4. **Emission control modes** in `iads` - F5, ARM response.
5. **Crew model** - F6.
6. **Tacpad app + tile** - F10.
7. **Zeus attributes** - F11.

Each phase lands with its README, its `docs/TESTS.md` section and a green `check_all.py`.

## 2026-10-13 - automatic air defence (user: "our integrated air should work like" Air Defenses PLUS, "for all invade or defend sides")

Built into `adsite`, not beside it - the same Sites, picture, assignment, fuse, notices, tacpad and ZEN:

- **Automatic Sites.** A server class init on `LandVehicle` / `Ship` queues every new vehicle; `fnc_autoScan` (a PFH
  that exists only while the queue is non-empty) asks `fnc_isAD` (cached per class, from `fnc_profile`: a CIWS or a
  radar-carrying AA gun with a round of hit 40 or more, a missile with airLock 2, a weaponless air radar, or an
  Extra Classes match) and, once crewed, `fnc_autoJoin` puts it into an `AUTO` Site of its crew's side within the
  link distance. A module or battery that claims it later wins (`fnc_addMember`). Automatic Sites do not engage
  manned aircraft unless a setting says so - the crews' own AI does, as ever.
- **Threat settings** (families, drones, intercept chance per attempt, range cap, ignore sides) apply to every Site;
  no module attribute is overridden, since none covers them.
- **Targeting mode per vehicle** (off / random / closest / highest = soonest impact) - assignment became
  member-centric: free members, inner layer first, each pick one reachable threat under its Site's shots per
  threat, unengaged threats first, then by the member's mode.
- **Alarms (supersedes F9's "no sounds")**: a per-side CBA setting picks a base-game alarm, played with
  `playSound3D` on un-muted members and nearby loudspeakers once per salvo. Notices stay the written warning.


## 2026-10-14 - performance redesign (user: "redo the integrated AA, this time without the lag")

The game ran at about 4 FPS with air defence in, and at a normal rate with it out. `adsite`, `iads` and
`airdefence` were removed (backup: `D:\Git\_jmsb_airdefence_removed_2026-10-14`). The likely cause: `fnc_picture`
ran every 0.25 s **per Site**. Each run did a `nearObjects` for each munition family over the Site's whole weapon
reach plus 1.5 km, plus an `Air` `nearEntities`. A 0-delay `fnc_fuze` PFH ran on top. Automatic mode made one Site
per AD cluster on every side, which multiplied all of it.

- **`airdefence` restored as it was.** It only places hardware, and its one timer is the 10-minute rearm PFH. There
  is no per-frame or area-scan work, apart from a one-off `waitUntil time > 0` before an AA Base builds.
  `batteryUp` now feeds the new `adsite`.
- **`iads` (EMCON blinking) stays removed.**
- **`adsite` rewritten**, keeping its name and the `jmfsb_moduleADSite` class. Nothing in it scans:
  - Units are registered once, on vehicle creation (cached per-class test).
  - Munitions are detected from the `fired` class event on the machine where the shooter is local. An ignored shot
    costs one hashmap lookup. A relevant one is predicted once on the server and matched against the protect radii.
  - One engagement PFH (0.15 s) exists only while threats are in the air. It is capped at 16 threats, 64
    feasibility tests and 8 new engagements per pass, and it times itself (WARNING above 2 ms).
  - The kill is a timed roll, as in Air Defenses PLUS. The firing machine deletes the round and leaves a harmless
    blast. There is no proximity-fuse loop.
  - Aircraft and drones are left to the crews' AI.
- **Dropped with the old internals:** Sites with link and coordinators, the air picture, EMCON modes, the crew
  temperament model, CIWS aim learning, notices, the tacpad panel, ZEN attributes, Extra Classes and the probe
  command. The module keeps only Protected Radius and Intercept Chance.
- **The budget is in `addons/adsite/README.md`.**
