# CAS

`jmfsb_cas`

Player-tasked fixed-wing CAS drones, on the support page.

Place one **JMSB - CAS Drone** module per airframe. Many are allowed and each
is its own asset: its own callsign, its own aircraft, its own approach and its
own losses. Two Reapers and a Bayraktar is three modules and three rows in
TAC//SUPPORT.

The module carries the operation values - which airframe, how far out it comes
from, how high it runs, how long it takes to answer, how long before it can be
asked again. **It never carries the geometry.** The target grid, the ingress
heading and the egress heading are set per request on the support page, which
is why one module can run a strike onto any grid on the map rather than only
the ground it was dropped beside.

**Ingress and egress are points on the map, picked the same way the target
is** - click the map, or take a placed marker off the `MKR` list. The aircraft
appears at the ingress point and leaves towards the egress point, so a section
puts the run-in behind the ridge they are looking at rather than converting it
into a heading first. The support page shows the run as two legs through the
target, so the geometry gets checked on the map rather than in the head.

Either may be left unset and the run still flies: **ingress** then comes from
the caller's side of the target, **egress** carries straight on through.
Requiring three map picks before anything could be called in would make the
fast case slow.

**It leaves off the map, not in front of anyone.** Once it is past the egress
point the run is over and the asset reads idle (rearming) again, but the
aircraft does not vanish there: it flies on along the egress heading to just
past the map edge and is deleted once it is outside the map. A recall or a
released loiter leaves the same way. One that has not made the edge in twenty
minutes is deleted where it is, and it can still be shot down on the way out -
that loss counts like any other.

The module's **Ingress Distance** is a floor, not a fixed range - a point
dropped two hundred metres off the target is an aircraft with no room to line
up, so anything closer is pushed back along its own bearing. The player still
chooses the direction, which is what he actually cared about.

**Altitudes are ATL throughout.** Attack Altitude is height above the ground
under the aircraft, so a run flown at seven hundred over a ridge is seven
hundred over the ridge - not seven hundred over the sea with the ridge at
six-fifty.

**The grid is where the strike starts, not where it lands.** A map click is
accurate to the pixel, which over four kilometres of run-in is the building
next to the one that was meant. So the aircraft looks again on the way in -
every second, because a designator comes on late far more often than early -
and shifts onto whatever it finds inside the module's terminal search radius:

| | |
|---|---|
| **Laser** | Own side's spots only. Unambiguous, aimed by a man who can see the target, and the only one of the three that tracks something moving. |
| **Smoke** | Any colour. Every rifleman has it and it needs no equipment; asking a man under fire to find the right grenade is asking for the strike to go in on nothing. |
| **The grid** | No spot and no smoke is not a failure. It is a map-grid strike, which is what was ordered, and it goes in. |

Terminal search 0 turns the whole thing off and the grid is final.

The AI is not flying it and is not shooting it. The group runs CARELESS with
targeting disabled and follows two MOVE waypoints; one function pulls the
trigger, and guided ordnance is pinned to a dummy laser target so a release
either hits or says in the log why it did not. Arma's air AI given a SAD
waypoint orbits an objective without engaging often enough that every support
mod in existence has stopped asking it.

**It is a real aircraft and it can be lost.** Shooting it down is worth doing:
each loss comes off the module's **Airframes Available**, and an asset that
burns its last one reads EXPENDED on the support page for the rest of the
mission rather than quietly vanishing. Set it to 0 for unlimited.

Not jmfsb's design. The run geometry, the terminal guidance and the dummy-laser
delivery are **Simplex Support Services'** model, rebuilt against jmfsb's own
support seam.

## Ordnance

The run comes in with the heaviest air-to-ground thing the airframe is
carrying — bomb, then missile, rocket, shell, gun. That is **AUTO**, and it is
the default, because a section calling a strike in wants a strike and should
not have to answer a loadout question to get one.

**Anything else on the list is a store that is actually hanging on the
aircraft.** The page used to offer five categories — AUTO / BOMB / MISSILE /
ROCKET / GUN — which is the same five words over a Reaper, a Bayraktar and a
Buzzard: it cannot tell a GBU from a Scalpel when an airframe has both, and it
offers three kinds nothing aboard has ever carried. The column now reads the
airframe's own stores, by name and with the rounds left on them:

```
ORDNANCE    < AUTO >
ORDNANCE    < GBU-12 X2 >
ORDNANCE    < SCALPEL X4 >
ORDNANCE    < 20MM HE X600 >
```

Both places ordnance hides are read — turret magazines for the gun and the
fixed-armament airframes, the pylon component for everything with a dynamic
loadout — and air-to-air missiles are dropped, because a Falchion is not
something a man asking for a strike on a treeline can use. The list is ranked
heaviest-first, so it reads down in the order AUTO would have picked.

The list is published on the asset's own row — the same column a battery
carries its shell types in — and the page sends back an **index**, which the
tasking turns into a magazine class before the order leaves the client. The
page never learns what it selected. A store that has been shot off between the
request and the release falls back to AUTO rather than flying over dry, and
says so in the log.

## Loiter

**LOITER is a different task, not a strike with a different name.** The support
page has always offered it beside the attack run, and this asset used to fly
both the same way: an aircraft asked to hold overhead put its bombs down and
left, which is neither of the things the word means.

Now the aircraft flies the same ingress, holds an orbit over the task point,
and releases nothing. **On station, the gunner's seat goes to the drone
controller** — the drone is linked and the seat handed over, so the
optics, the sensors and whatever the airframe is hung with belong to a man
rather than to a script with a target list. The AI keeps flying the orbit; the
driver's seat stays locked, so a controller cannot fly the aircraft into the
ridge he is watching.

Who gets it:

| | |
|---|---|
| **The man who asked, if he is ISR** | Drone linked, gunner's seat taken, told so. The ISR flag is the mission's own `isISR` variable — the same one the hacking tablet gates on. The link itself is `jmfsb_devices_fnc_uavControl`'s, so he also needs the UAV operator trait and a DATA link; without them he is told he cannot take it and the aircraft holds. |
| **The man who asked, if he is not** | The aircraft holds overhead and he is told his ISR operator can take the feed. A rifleman may call a loiter; he does not fly it. |
| **Everyone else on the side** | Told it is on station. It is on their DRONES board and a UAV operator can take it himself when the man who called it is finished. |

There is no UAV terminal (2026-10-20: out of the arsenal): the link and the seat
are the devices' own (`jmfsb_devices_fnc_uavControl` - remoteControl, no
terminal item). A link is exclusive — it drops whatever else that player was
flying — so only the man who asked is linked automatically. Nobody else's
drone is taken out from under them.

It holds for an hour, or until **RTB** on the support page, or until it is shot
down. Whatever ends it, the seat is given back first - and again before the
airframe is deleted off the map edge, in case someone took it on the way out:
a controller left in the turret of a vehicle that is deleted under him is a
black screen he cannot get out of.

## Tasking

Assets reach TAC//SUPPORT through the support core (`jmfsb_support`) rather than
by name: this addon registers as provider `cas` - rows, task, sitrep,
availability and its one asset type with its three tasks - the core merges
whatever is registered, and neither learns the other's name. The ids handed out
carry the `cas:` prefix, so an order routes itself back here. The contract is
in `addons/support/README.md`.

Its three tasks declare their INGRESS and EGRESS as point declarations (task
declaration field 7, slots 8 and 9 - the same points support_air's CAS reads),
and its rows carry the airframe while it is out and the run it is flying
(row fields 7 and 8), so the board's map shows the drone and its run.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_support`

## Ships

1 unit class, 17 functions.

## Eden modules

### JMSB - CAS Drone

`jmfsb_moduleCAS`, category jmfsb_modules

One taskable CAS drone on the support page. Place one module per airframe - many are allowed, and each is its own asset with its own losses.<br>The player sets the TARGET GRID, the INGRESS bearing and the EGRESS bearing on the support page. The drone appears at the ingress distance on that bearing, runs the target, and leaves on the egress bearing - off the map edge, where it despawns.<br>ORDNANCE on the support page lists what THIS airframe is carrying, by name - the run uses the heaviest thing aboard unless one is picked.<br>LOITER holds the drone over the point instead of striking it, and hands the gunner's seat to the ISR operator who asked for it - he needs the UAV operator trait and the isISR variable, no UAV terminal. RTB ends it.<br>Airframe Class - Classname of the fixed-wing drone; blank for the side's vanilla UCAV Callsign - What the support page and the radio call it Airframes Available - How many times it may be shot down before the asset is expended; 0 for unlimited Ingress Distance (m) - How far out it appears, and how far past the target it runs before the asset is free again Attack Altitude (m) - Height above the terrain (ATL) the run is flown at Run Speed (km/h) - Capped at the airframe's own maximum Response Delay (sec) - Time from accepted request to the aircraft appearing Cooldown (sec) - Time after a run before this asset can be tasked again Terminal Search (m) - How far from the grid a laser spot or smoke is accepted as the real target; 0 for none

<details><summary>9 attributes</summary>

- `airframes`
- `altitude`
- `callsign`
- `cooldown`
- `droneClass`
- `searchRadius`
- `spawnDelay`
- `spawnDistance`
- `speed`

</details>

## Functions

<details><summary>17</summary>

- `jmfsb_cas_fnc_acquire`
- `jmfsb_cas_fnc_assetAvailable`
- `jmfsb_cas_fnc_assets`
- `jmfsb_cas_fnc_available`
- `jmfsb_cas_fnc_egress`
- `jmfsb_cas_fnc_entityRow`
- `jmfsb_cas_fnc_fireAt`
- `jmfsb_cas_fnc_fmtEta`
- `jmfsb_cas_fnc_killed`
- `jmfsb_cas_fnc_moduleController`
- `jmfsb_cas_fnc_nearestTo`
- `jmfsb_cas_fnc_overlay`
- `jmfsb_cas_fnc_preview`
- `jmfsb_cas_fnc_request`
- `jmfsb_cas_fnc_sitrep`
- `jmfsb_cas_fnc_stores`
- `jmfsb_cas_fnc_task`

</details>
