# Eden modules

Place from the 3DEN entity list under the listed category.

## ACM (`acm`)

### JMSB - ACM Evacuation Zone

- **Class** `jmfsb_acm_moduleEvacZone`
- **Category** jmfsb_modules
- Any AI that enters the area is evacuated with ACM's evacuation: removed from the mission, out of a vehicle if it is in one, and a converted casualty returns its casualty ticket. Players are never touched. The zone is marked on everyone's map (EVAC).
- **Attributes** `interval`, `who`

## Air Defence Intercept (`adsite`)

### JMSB - Air Defence Site

- **Class** `jmfsb_moduleADSite`
- **Category** jmfsb_modules
- An air defence Site: sync the AA guns, CIWS and SAM launchers that make it. They intercept artillery, rockets, missiles and bombs predicted to land inside the protected radius, and share one alarm. Any air defence vehicle defends itself without this module; the module only sets the radius and the intercept chance for its own.
- **Attributes** `interceptChance`, `radius`

## Air Defence (`airdefence`)

### JMSB - Air Defence (temporary)

- **Class** `jmfsb_moduleAirDefence`
- **Category** jmfsb_modules
- Places air defence for every ALiVE commander on the map. TEMPORARY - it stands in until ALiVE 3's own air defence is stable.<br>Conventional commanders (invasion, occupation) get radar-cued missile batteries. Asymmetric commanders get MANPAD teams instead - a guerrilla does not field a battery.<br>Where they go is read from ALiVE: each commander's own TAOR and objectives, never anything set here. Everything placed is profiled, so it costs nothing while nobody is near it.<br>Without ALiVE: every side with a TAOR field here or jmfsb_taor_west / _east / _guer area markers gets batteries over the towns on that ground. No ground drawn at all: the mission's enemy, over towns clear of the players' start.<br>Batteries Per Side - conventional commanders only, asymmetric get none Launchers Per Battery - set back from the radar that cues them Battery Spacing (m) - least distance between two batteries Radar / Launcher / MANPAD classes are set PER SIDE - the three commanders are three different armies. Leave any of them blank to pick from that commander's own faction. Clear Ground (m) - open ground a battery needs; a radar in a wood sees nothing MANPAD Teams Per Side - asymmetric commanders only
- **Attributes** `launcherEast`, `launcherGuer`, `launcherWest`, `launchers`, `manpadEast`, `manpadGuer`, `manpadManEast`, `manpadManGuer`, `manpadManWest`, `manpadWest`, `openGround`, `radarEast`, `radarGuer`, `radarWest`, `rearmEvery`, `security`, `sitesPerSide`, `spacing`, `taorEast`, `taorGuer`, `taorWest`, `teamsPerSide`

### JMSB - AA Base

- **Class** `jmfsb_moduleAABase`
- **Category** jmfsb_modules
- Builds an AA base inside the module's area: a radar at the module, SAM launchers on a ring around it, AA guns close in as point defence, and guards standing off the hardware.<br>Works on its own - no Air Defence module, ALiVE commander or TAOR marker needed. The area's radius sets the spread.<br>The base's side is the radar class's own side, else the first missile class's, else the first gun class's.<br>Radar, launchers, guns and their crews stay live and out of ALiVE. Only the guards are ALiVE-profiled.
- **Attributes** `guardClasses`, `guards`, `gunClass`, `gunCount`, `missileClass`, `missileCount`, `radarClass`

## Ambience (`ambience`)

### JMSB - Ambient Shelling

- **Class** `jmfsb_moduleAmbientShelling`
- **Category** jmfsb_modules
- Ambient war: every few minutes a short artillery stonk lands on a building near a player inside the named markers. It never targets the players themselves - the distance band keeps it off their heads - and every impact area is announced on the alert bus first.
- **Attributes** `bandMax`, `bandMin`, `intervalMax`, `intervalMin`, `markers`, `roundsMax`, `roundsMin`, `shellClasses`

### JMSB - Ambient Kamikaze Drones

- **Class** `jmfsb_moduleAmbientKamikaze`
- **Category** jmfsb_modules
- Ambient war: every few minutes a one-way drone flies in and dives on a building near a player inside the named markers. It is a real aircraft on the map - audible, visible and killable, and shooting it down is the counterplay. It never dives at the players themselves.
- **Attributes** `bandMax`, `bandMin`, `diveSpeed`, `droneClasses`, `intervalMax`, `intervalMin`, `markers`

## AntiShip (`antiship`)

### JMSB - Anti-Ship Batteries

- **Class** `jmfsb_moduleAntiShip`
- **Category** jmfsb_modules
- Sites coastal anti-ship batteries for every ALiVE commander the players are not on, inside its own TAOR: a surface search radar on the shoreline and launchers inland behind it. Nobody placing the mission knows where. Without ALiVE, the module's own area is the ground and the battery belongs to the side opposing the players. How they fire is under CBA settings, Anti-Ship.
- **Attributes** `batteriesPerSide`, `launchersPerBattery`, `radarsPerBattery`

## APS (`aps`)

### JMSB - APS

- **Class** `jmfsb_moduleAPS`
- **Category** jmfsb_modules
- Placing this module turns on the APS, the active protection. Without it, the system is off.<br>Hard Kill - Launcher-and-charge systems that destroy incoming rockets and missiles short of the hull RF Burst - The microwave emitter: guided munitions lose guidance, drones drop, every radio nearby is jammed for a moment RF Burst On Helicopters - Peer+ helicopters carry the emitter as their DIRCM Tier Overrides - faction:tier pairs that bend the fit table for a mission Fit Overrides - class:fit pairs that name a vehicle's fit outright Debug - Log fits and intercepts, draw burst radii
- **Attributes** `debug`, `fitOverrides`, `hardKill`, `rfAir`, `rfBurst`, `tierOverrides`

## Boarding (`boarding`)

### JMSB - Boarding Point

- **Class** `jmfsb_moduleBoarding`
- **Category** jmfsb_modules
- A muster point that loads players into transport. Synchronise the OBJECT players press - a sign, a crate, a flagpole - and it carries an ACE action; pressing it moves every player within the module's range into cargo. Synchronise VEHICLES too to say which transport is theirs; with none synced it uses whatever has free cargo near the module. Players already in a vehicle are left alone, and anyone who does not fit is told so rather than being silently left behind.
- **Attributes** `includePresser`, `range`, `sideOnly`, `title`

## Backpack On Chest (`boc`)

### Add Chestpack

- **Class** `jmfsb_boc_ModuleAdd`
- **Category** bocr
- Classname of the disered chestpack

### Backpack on Chest

- **Class** `jmfsb_boc_ModuleOnChest`
- **Category** bocr
- Classname of the backpack which should be added after putting the backpack on chest.

## CAS (`cas`)

### JMSB - CAS Drone

- **Class** `jmfsb_moduleCAS`
- **Category** jmfsb_modules
- One taskable CAS drone on the support page. Place one module per airframe - many are allowed, and each is its own asset with its own losses.<br>VIRTUAL UNTIL TASKED: no drone is up between tasks. A request makes one in the air over the module at its hold altitude, dark, full of fuel and stores; after the task it flies back to the module and is removed.<br>The requester sets the TARGET GRID and the INGRESS and EGRESS points. Only a drone LOST uses one of the Respawns.<br>ORDNANCE on the support page lists what THIS airframe is carrying, by name - the run uses the heaviest thing aboard unless one is picked.<br>LOITER holds the drone over the grid instead of striking, and hands the gunner's seat to the ISR operator who asked for it - he needs the UAV operator trait and the isISR variable, no UAV terminal. RTB ends it.<br>Flies tactically: no lights, strikes from 4000 m above the terrain.<br>Airframe Class - Classname of the fixed-wing drone; blank for the side's vanilla UCAV Callsign - What the support page and the radio call it Respawns - Replacement drones after a drone is lost; 0 for none. Going home uses none Respawn Delay (sec) - Time after a loss before the asset can be tasked again Ingress Distance (m) - The run-in floor, and how far past the target it runs before the asset is free again Run Speed (km/h) - Capped at the airframe's own maximum Cooldown (sec) - Time after a run before this asset can be tasked again Terminal Search (m) - How far from the grid a laser spot or smoke is accepted as the real target; 0 for none
- **Attributes** `callsign`, `cooldown`, `droneClass`, `respawnDelay`, `respawns`, `searchRadius`, `spawnDistance`, `speed`

## ECOTI (`ecoti`)

### JMSB - AiTR Building Mark

- **Class** `jmfsb_ecoti_moduleMark`
- **Category** jmfsb_modules
- Marks a building for every AiTR (ECOTI): a box round it in the Colour, the Label and range under it, out to 2 km, through walls.<br>Place it on the building, or sync buildings to it. Nothing synced: the nearest building within 25 m.<br>Players mark from their own key (AiTR - mark building) and pick the colour on numpad 6-9 on the phone or side device. A Zeus with ZEN has a dialog: 1st Joint Multi-Functional Strike Battalion > AiTR building mark.
- **Attributes** `colour`, `label`

## Hacking (`hacking`)

### JMSB - Intel Package

- **Class** `jmfsb_moduleIntelPackage`
- **Category** jmfsb_modules
- Puts an intel package on a device. Hacking that device hands over a share of it.<br>Package - a class under Jmfsb_IntelPackages in the mission config Terminal Class - what to build if this is synchronised to nothing<br>How big a share one hack yields is a CBA setting - JMSB - EW, Drones & Intel, Hacking. The package's own contents are mission config, not module attributes: see the wiki.
- **Attributes** `package`, `terminal`

## Jamming (`jamming`)

### JMSB - Jamming

- **Class** `jmfsb_moduleJamming`
- **Category** jmfsb_modules
- Placing this module turns on jamming. Without it, the system is off. It places no jammers - a JMSB - Jammer Site module does that, one per emitter.<br>Site Radius Min / Max (m) - every site rolls its own reach between the two GPS Denial - one uplink per commander steering a wandering 1-2 km GPS sphere Uplink Radius (m) - the uplink's own GPS field Radio Burn-Through - a strong set beats a jammer, and is answered with a QRF Burn-Through Reference (mW) - the set power the field is calibrated against Zone Noise at the Core (dBm) - what a radio or data zone adds to the RF link budget
- **Attributes** `burnRef`, `gpsUplinkRadius`, `largeRadius`, `maxPerSide`, `objectiveShare`, `rfNoise`, `smallRadius`

### JMSB - Jammer Site

- **Class** `jmfsb_moduleJammerSite`
- **Category** jmfsb_modules
- One jammer site, where you place it. Needs the JMSB - Jamming module on the map to arm.<br>Spectrum - radio, data or gps. One per site Radius (m) - 0 rolls one from the Jamming module's bounds Owner - whoever is hostile to the players, worked out from the mission's side relations<br>Artillery Reply - the site shells whoever loiters in its field Reply Delay (s) - how long a hostile must stay inside before it fires Reply Rounds / Scatter (m) - the size of the mission and how wide it falls Reply Cooldown (s) - minimum gap between two missions from this site
- **Attributes** `artyCooldown`, `artyDelay`, `artyRounds`, `artyScatter`, `domain`, `radius`

## Jumpmaster (`jumpmaster`)

### JMSB - Jump Aircraft

- **Class** `jmfsb_jumpmaster_moduleJump`
- **Category** jmfsb_modules
- One jump aircraft in TAC , , , , , , , , , , HALO / HAHO / Static Line Altitude (m) - Height of each kind of run Passes By Default - When the request leaves PASSES empty Exit By Default - When the request ticks no EXIT In The Aircraft - Seats, or standing in the bay Cooldown (sec) - Time after a run before the next Respawns - Aircraft that may be lost and replaced; 0 for none Respawn Delay (sec) - Time after a loss before a new aircraft can be tasked Fixed-Wing Escort Class - Two drones with a plane, always; blank for the side's UCAV Rotary Escort Class - Two drones with a helicopter for a YELLOW or RED LZ only
- **Attributes** `aircraftClass`, `bay`, `callsign`, `cooldown`, `escortHeli`, `escortPlane`, `exit`, `hahoAltitude`, `haloAltitude`, `passes`, `respawnDelay`, `respawns`, `staticAltitude`

## Leaders (`leaders`)

### JMSB - Leader Chain

- **Class** `jmfsb_moduleLeaders`
- **Category** jmfsb_modules
- Placing this module turns on leader chain. Without it, the system is off.<br>Without ALiVE: the mission's enemy is the insurgent side (or the side of a man synchronised to this module, whose faction the leaders wear), safe houses are in the map's towns, inside TAOR Markers or jmfsb_taor_west / _east / _guer markers when set.<br>Pool Cut Per Leader (%) - How much of the asymmetric commander's force pool dies with each leader Rotate Every (sec) - How often a leader moves to another safe house Trap Chance (%) - Chance a watched safe house is trapped with mortars Internet Pops - How many rugged-server props are placed for players to find and pull leads from
- **Attributes** `poolCut`, `pops`, `rotateEvery`, `taor`, `trapChance`

## Modules (`modules`)

### Safe Start Disabler

- **Class** `jmfsb_modulesafestart`
- **Category** -
- Disable in single player

### Heal Area

- **Class** `jmfsb_moduleHealArea`
- **Category** -
- Heal Players In Area

### AI Spawner

- **Class** `jmfsb_moduleAiSpawner`
- **Category** -
- Group Side

### AI Hunter

- **Class** `jmfsb_moduleAiHunter`
- **Category** -
- Group Side

### JMSB - Hold ALiVE

- **Class** `jmfsb_modules_holdAlive`
- **Category** -
- Training: ALiVE starts paused. An admin types #jmfsbalivestart in chat to start it.

## QRF (`qrf`)

### JMSB - QRF

- **Class** `jmfsb_moduleQRF`
- **Category** jmfsb_modules
- Placing this module turns on qrf. Without it, the system is off.<br>Without ALiVE: only jmfsb_qrf area markers are watched, the mission's enemy answers, and its squads walk in live. No artillery is asked - there are no commander's guns.<br>Hold Time (sec) - How long players must hold an objective, uncontested, before it counts as taken Players Needed - How many players inside before a hold counts at all Squads Min - Fewest squads the third wave sends Squads Max - Most squads Asymmetric Mortar Chance (%) - An asymmetric commander answers with a few mortar rounds or with nothing - never a full barrage Cooldown (sec) - Retaking the same objective inside this window brings no second QRF
- **Attributes** `asymMortarChance`, `cooldown`, `holdTime`, `minPlayers`, `squadsMax`, `squadsMin`

## Range (`range`)

### JMSB - Shooting Range

- **Class** `jmfsb_range_module`
- **Category** -
- Shown in the menu, the results and the PAC record. Keep it the same between missions so scores line up.

## Reaction (`reaction`)

### JMSB - Enemy Reaction

- **Class** `jmfsb_moduleReaction`
- **Category** jmfsb_modules
- Placing this module turns on enemy reaction. Without it, the system is off.<br>Hack Fail Chance (%) - Chance an intrusion fails outright Detection Chance (%) - Chance a failure, a drone sighting or a transmission is noticed Barrage Rounds Min - Fewest shells a major response puts down Barrage Rounds Max - Most shells Radio Watts Watched - Transmit power at or above which a radio can be direction-found<br>Counter-battery - player-crewed guns only; the players' virtual artillery (support batteries called by message) and AI artillery never: Chance (%) - 0 turns it off. Rounds To Fix and Fix Window - how much fire the enemy radar needs Delay Min / Max (s) - when the answer lands, on where the guns were. Rounds, Spread - the answer Cooldown (s) - per gun. Warning (1/0) - INCOMING to the gun crew
- **Attributes** `cbChance`, `cbCooldown`, `cbDelayMax`, `cbDelayMin`, `cbRadar`, `cbRadarCooldown`, `cbRadarError`, `cbRounds`, `cbShots`, `cbSpread`, `cbWarn`, `cbWindow`, `detectChance`, `failChance`, `roundsMax`, `roundsMin`, `watts`

## Repair (`repair`)

### Timed Repair

- **Class** `jmfsb_moduleTimedRepair`
- **Category** jmfsb_modules
- Keeps everything synchronised to it serviceable: rearmed, refuelled and repaired on a timer, and optionally rebuilt if destroyed. A snapshot of each object is taken at mission start while it is still intact, and that is what a respawn is rebuilt from - so a respawned object comes back where it was placed, not where the blast left it.
- **Attributes** `debug`, `interval`, `rearm`, `refuel`, `repair_amount`, `replace_crew`, `respawn`, `respawn_delay`

## Support Air (`support_air`)

### JMSB - CAS

- **Class** `jmfsb_support_air_moduleCAS`
- **Category** jmfsb_modules
- One taskable CAS aircraft on TAC , , , , , , , , Run-In Distance (m) - How far past the target a run turns out Time On Station (sec) - How long a SAD, LOITER or REQUEST ON STATION holds Terminal Search (m) - Laser/smoke search radius on a run; 0 for none Cooldown (sec) - Time after an aircraft is gone before it can be tasked again Respawns - Replacements after a loss; 0 for none Respawn Delay (sec) - Time after a loss before it can be tasked again Cooldown Starts - End of the sortie, or at the request Friendly Range (m) - Releases held this close to friendlies unless DANGER CLOSE Fixed-Wing Escort Class - A jet's two drones, always; empty for the side's UCAV Rotary Escort Class - A helicopter's two drones on a YELLOW or RED LZ; empty for none
- **Attributes** `aircraftClass`, `callsign`, `cooldown`, `cooldownTrigger`, `escortHeli`, `escortPlane`, `friendlyRange`, `respawnDelay`, `respawns`, `runIn`, `searchRadius`, `stationTime`

### JMSB - Transport

- **Class** `jmfsb_support_air_moduleTransport`
- **Category** jmfsb_modules
- One taskable transport helicopter on TAC , , , , , , Seats - Passenger seats offered; 0 for all Extract Wait (sec) - How long an EXTRACT waits for the requester's group Task: ... - Which of PICKUP, LAND, LAND ENG OFF, HOVER, EXTRACT, PICKUP > LZ, LOITER, FASTROPE, HELOCAST, PARADROP and SLINGLOAD it offers Paradrop Height (m) - Height a paradrop crosses the drop zone at Cooldown (sec) - Time after it is home before it can be tasked again Respawns - Replacements after a loss; 0 for none Respawn Delay (sec) - Time after a loss before it can be tasked again Cooldown Starts - End of the sortie, or at the request Rotary Escort Class - Two drones on a YELLOW or RED LZ; empty for none
- **Attributes** `aircraftClass`, `callsign`, `cooldown`, `cooldownTrigger`, `escortHeli`, `jumpHeight`, `respawnDelay`, `respawns`, `seats`, `waitTime`

### JMSB - QRF Insertion

- **Class** `jmfsb_support_air_moduleQRF`
- **Category** jmfsb_modules
- One taskable quick reaction force on TAC , , , , Squad (CfgGroups) / Unit Classes - Who is inserted Insert: ... - Which insertion methods are offered On The Ground - Defend the grid or join the requester Defend Radius (m) - Area a defending squad holds Static Line Height (m) - Height of the static-line pass Cooldown (sec) - Time after the aircraft is home before the next squad Respawns - Replacements after a loss; 0 for none Respawn Delay (sec) - Time after a loss before it can be tasked again Cooldown Starts - End of the sortie, or at the request Fixed-Wing Escort Class - A plane's two drones, always; empty for the side's UCAV Rotary Escort Class - A helicopter's two drones on a YELLOW or RED LZ; empty for none
- **Attributes** `aircraftClass`, `callsign`, `cooldown`, `cooldownTrigger`, `defendRadius`, `escortHeli`, `escortPlane`, `groupClass`, `onLanding`, `respawnDelay`, `respawns`, `staticAlt`, `unitClasses`

## Support Fires (`support_fires`)

### JMSB - Artillery Battery (retired)

- **Class** `jmfsb_moduleFiresArtillery`
- **Category** jmfsb_modules
- RETIRED - place JMSB - Virtual Artillery instead. Kept so missions that placed it still load.<br>Runs as a virtual battery: no gun aims or fires. Synced artillery, if any, gives only the battery's position, its gun count and (with Ammunition Per Gun blank) the rounds its magazines carry.<br>Callsign - What the support page calls it Ammunition Per Gun - class:rounds per gun; blank reads the synced guns Cooldown (sec) - Time after a mission before it can be tasked again
- **Attributes** `ammunition`, `callsign`, `cooldown`

### JMSB - Virtual Artillery

- **Class** `jmfsb_moduleFiresVirtual`
- **Category** jmfsb_modules
- THE artillery module. A battery on the support page, on or off the map: no guns exist, the module IS the battery's position. Each round is the shell class itself, spawned high over the target on its descending arc after the time of flight from here, so it is heard coming in. Counter-battery has nothing to find.<br>A Simplex fire mission: ordnance, rounds per gun, sheaf type and size, guns, interval, delay, repeat volleys, and coordination with nearby batteries. The target is marked on the map until the mission ends. Rounds are counted per type and run out.<br>Callsign - What the support page calls it Guns - Tubes in the battery HE, Smoke, Illumination, Cluster, Guided - Shell or magazine class and rounds of each; 0 none, -1 unlimited Minimum / Maximum Range (m) - From this module Dispersion (m) - Each round's own error, an ellipse along the line of fire Aiming Error (m) - A mission's first salvo off the point; each adjust halves it Muzzle Velocity (m/s) - Top charge; time-of-flight model Trajectory - High or low angle Reload (sec) - Between one gun's rounds Cooldown (sec) - After the mission, and between repeats Cooldown Per Round (sec) - Added per round fired Response Time Min / Max (sec) - Random wait before the first round Sheaf Types - Which the support page offers Max Rounds Per Gun, Max Interval, Max Delay, Max Repeats - Stepper limits; 0 hides a stepper Coordination Distance (m) - Batteries this close may fire together; 0 never Max Sheaf Length (m) - Longest sheaf, area radius, linear target or creeping walk Max Continuous Fire (min) - Longest CONTINUOUS FOR n MIN; 0 none Target Prefix - Two letters for recorded targets (AB1001); blank from the callsign
- **Attributes** `aimError`, `callsign`, `clusterClass`, `clusterRounds`, `cooldown`, `coordination`, `dispersion`, `guidedClass`, `guidedRounds`, `guns`, `heClass`, `heRounds`, `illumClass`, `illumRounds`, `maxContinuous`, `maxDelay`, `maxInterval`, `maxRange`, `maxRepeat`, `maxRounds`, `minRange`, `muzzleVelocity`, `reload`, `responseMax`, `responseMin`, `roundCooldown`, `sheafMax`, `sheafTypes`, `smokeClass`, `smokeRounds`, `targetPrefix`, `trajectory`

### JMSB - Cruise Missiles

- **Class** `jmfsb_moduleFiresCruise`
- **Category** jmfsb_modules
- A cruise missile launcher on the support page, at this module's position - a ship or ground site, off the map edge is fine.<br>Each missile is a real projectile that flies the whole route: up off the rail, terrain-following at cruise altitude to the target, then a terminal dive. Air defence and active protection can shoot it down. The target is marked on the map until the salvo is gone.<br>Callsign - What the support page calls it Missiles - How many for the whole mission Missile Class - The CfgAmmo flown; blank for ammo_Missile_Cruise_01 Warhead - CfgAmmo set off at the target; blank for the missile's own Salvo Size - Most per request Cruise Speed (m/s) / Cruise Altitude (m) - The route Cooldown (sec) - After a salvo Cooldown Per Missile (sec) - Added per missile launched Response Time Min / Max (sec) - Random wait before the first launch Max Delay (sec) - Top of the DELAY stepper; 0 hides it
- **Attributes** `altitude`, `callsign`, `cooldown`, `maxDelay`, `missileClass`, `missileCooldown`, `missiles`, `responseMax`, `responseMin`, `salvo`, `speed`, `warhead`

### JMSB - Loitering Munitions

- **Class** `jmfsb_moduleFiresLoiter`
- **Category** jmfsb_modules
- A loitering munition launch site on the support page, at this module's position.<br>Each munition is a real air vehicle: it flies to the target area, orbits it for the loiter time hunting, dives on the best target its strike rules allow, and self-destructs when time runs out. It can be shot down. The hunt area is marked on the map until the last munition is gone; a target further than the munition can fly in its transit time is refused.<br>Callsign - What the support page calls it Munition Class - Blank for the Switchblade 600 (Switchblade mod) or the side's Darter Munitions - How many for the whole mission Launch Size - Most per request Loiter Time (sec) - Time on station Strike Rules - Vehicles, infantry or both, enemy side only Loiter Altitude (m) - Height above the ground Warhead - CfgAmmo set off on the target; blank for the munition's own Cooldown (sec) - After the last munition is gone
- **Attributes** `altitude`, `callsign`, `cooldown`, `launchSize`, `loiterTime`, `munitionClass`, `munitions`, `strikeRules`, `warhead`

## Support Logistics (`support_logistics`)

### JMSB - Logistics

- **Class** `jmfsb_support_logistics_module`
- **Category** jmfsb_modules
- One taskable logistics asset: a TAC , , , , , , , , Method: ... - Airdrop and/or sling load Capacity - Items one order may hold Sling Fulfillment - One helicopter, or one per item Drop Height / Chute Opens At (m) - The airdrop pass and the chutes Unload Height (m) - The hover over the point before a sling load is lowered to the ground Cooldown / Item Cooldown (sec) - Time before the next delivery, plus per item Respawns - Replacements for aircraft lost; 0 none, -1 unlimited Respawn Delay (sec) - Time after a loss before the next delivery can fly Cooldown Starts - End of the delivery, or at the request Crate Class / PAC Arsenal Lists / Per Class - The PAC crates Marking - Smoke, IR strobe, chemlight, flare or none on what lands Fixed-Wing Escort Class - Two drone wingmen with a plane, always; empty for the side's vanilla UCAV Rotary Escort Class - Two drone wingmen with a helicopter when the LZ security is YELLOW or RED; empty for none
- **Attributes** `aircraftClass`, `arsenalLists`, `callsign`, `capacity`, `cooldown`, `cooldownTrigger`, `crateClass`, `dropHeight`, `escortHeli`, `escortPlane`, `fulfillment`, `itemCooldown`, `itemCount`, `magCount`, `openHeight`, `respawnDelay`, `respawns`, `signal`, `unloadHeight`

### JMSB - Logistics Catalog

- **Class** `jmfsb_support_logistics_moduleCatalog`
- **Category** jmfsb_modules
- What a JMSB - Logistics module can deliver. Sync this module to one or more of them.<br>Every vehicle, crate or other object inside the area, or synced to this module, is one item of the catalog - its editor inventory and paint go with it. Units and crewed vehicles are not items; identical objects are one item.<br>Remove The Objects - Clear the area once it is read

### JMSB - Logistics Drop (old)

- **Class** `jmfsb_support_air_moduleLogistics`
- **Category** jmfsb_modules
- Replaced by JMSB - Logistics (2026-11-01). Kept so missions that placed it still load: it becomes a JMSB - Logistics asset with a capacity of one crate, flown from the module.<br>Place JMSB - Logistics in new missions.
- **Attributes** `aircraftClass`, `arsenalLists`, `callsign`, `cooldown`, `cooldownTrigger`, `crateClass`, `dropHeight`, `drops`, `itemCount`, `magCount`, `method`, `respawnDelay`, `signal`

## Training (`training`)

### JMSB - Garrison Area

- **Class** `jmfsb_training_moduleGarrison`
- **Category** -
- CfgGroups class names, comma separated. One is picked at random for each group.

### JMSB - Training Area

- **Class** `jmfsb_training_moduleArea`
- **Category** -
- Shown in the TAC
                typeName = 

### JMSB - Medical Training

- **Class** `jmfsb_training_moduleMedical`
- **Category** -
- Shown in the app over its points, e.g. AID STATION 1. Blank: MEDICAL and its grid.

### JMSB - Vehicle Range

- **Class** `jmfsb_training_moduleVehicles`
- **Category** -
- Shown in the TAC
                typeName = 

## UAS (`uas`)

### JMSB - Drone Patrol

- **Class** `jmfsb_moduleDronePatrol`
- **Category** jmfsb_modules
- One patrol. Resize it - the area is the ground the drones fly over.<br>Side - whoever is hostile to the players, worked out from the mission's side relations Drones - how many airframes this patrol keeps up Drone Class - empty flies the enemy side's own<br>Artillery On Detect - a drone that sees somebody shells where it saw them Rounds / Scatter (m) / Cooldown (s) - the size of that mission and its gap<br>A module never resized is one 800 m orbit. Nobody within 3.2 km, nothing flies.
- **Attributes** `artyCooldown`, `artyRounds`, `artyScatter`, `droneClass`, `droneCount`

### JMSB - Drone Swarm

- **Class** `jmfsb_moduleDroneSwarm`
- **Category** jmfsb_modules
- A swarm, launched where you place it. Trigger it to launch on cue.<br>Airframe - which drone. Limited by the Swarm Airframes setting Drones - 2 to 12 Action - Impact dives on this module; Circle orbits it Spawn Min / Max (m) - how far out they appear and fly in from Side - the fallback crew's side<br>Resize the module to set the orbit radius. Impact ignores the area.
- **Attributes** `spawnMax`, `spawnMin`, `swarmAction`, `swarmClass`, `swarmCount`, `swarmSide`
