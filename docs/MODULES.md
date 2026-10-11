# Eden modules

Place from the 3DEN entity list under the listed category.

## Air Defence Sites (`adsite`)

### JMSB - Air Defence Site

- **Class** `jmfsb_moduleADSite`
- **Category** jmfsb_modules
- An air defence Site: sync the radars, launchers, guns and CIWS that make it. It pools what they see, gives each aircraft or incoming round to the best-fit weapon - guns inside, short-range missiles for the bulk, long-range held in reserve - fires the vehicles' own weapons, and runs on the server. Status and control are on the tacpad.
- **Attributes** `access`, `automation`, `burstSeconds`, `emcon`, `engageAir`, `engageMunitions`, `fumble`, `link`, `notices`, `radius`, `reaction`, `reserveLong`, `shotsPerThreat`, `siteName`

## Air Defence (`airdefence`)

### JMSB - Air Defence (temporary)

- **Class** `jmfsb_moduleAirDefence`
- **Category** jmfsb_modules
- Places air defence for every ALiVE commander on the map. TEMPORARY - it stands in until ALiVE 3's own air defence is stable.<br>Conventional commanders (invasion, occupation) get radar-cued missile batteries. Asymmetric commanders get MANPAD teams instead - a guerrilla does not field a battery.<br>Where they go is read from ALiVE: each commander's own TAOR and objectives, never anything set here. Everything placed is profiled, so it costs nothing while nobody is near it.<br>Batteries Per Side - conventional commanders only, asymmetric get none Launchers Per Battery - set back from the radar that cues them Battery Spacing (m) - least distance between two batteries Radar / Launcher / MANPAD classes are set PER SIDE - the three commanders are three different armies. Leave any of them blank to pick from that commander's own faction. Clear Ground (m) - open ground a battery needs; a radar in a wood sees nothing MANPAD Teams Per Side - asymmetric commanders only
- **Attributes** `launcherEast`, `launcherGuer`, `launcherWest`, `launchers`, `manpadEast`, `manpadGuer`, `manpadManEast`, `manpadManGuer`, `manpadManWest`, `manpadWest`, `openGround`, `radarEast`, `radarGuer`, `radarWest`, `rearmEvery`, `security`, `sitesPerSide`, `spacing`, `taorEast`, `taorGuer`, `taorWest`, `teamsPerSide`

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

## CAS (`cas`)

### JMSB - CAS Drone

- **Class** `jmfsb_moduleCAS`
- **Category** jmfsb_modules
- One taskable CAS drone on the support page. Place one module per airframe - many are allowed, and each is its own asset with its own losses.<br>The player sets the TARGET GRID, the INGRESS bearing and the EGRESS bearing on the support page. The drone appears at the ingress distance on that bearing, runs the target, and leaves on the egress bearing.<br>ORDNANCE on the support page lists what THIS airframe is carrying, by name - the run uses the heaviest thing aboard unless one is picked.<br>LOITER holds the drone over the point instead of striking it, and hands the gunner's seat to the ISR operator who asked for it - he needs a UAV terminal and the isISR variable. RTB ends it.<br>Airframe Class - Classname of the fixed-wing drone; blank for the side's vanilla UCAV Callsign - What the support page and the radio call it Airframes Available - How many times it may be shot down before the asset is expended; 0 for unlimited Ingress Distance (m) - How far out it appears, and how far it runs before despawning Attack Altitude (m) - Height above the terrain (ATL) the run is flown at Run Speed (km/h) - Capped at the airframe's own maximum Response Delay (sec) - Time from accepted request to the aircraft appearing Cooldown (sec) - Time after a run before this asset can be tasked again Terminal Search (m) - How far from the grid a laser spot or smoke is accepted as the real target; 0 for none
- **Attributes** `airframes`, `altitude`, `callsign`, `cooldown`, `droneClass`, `searchRadius`, `spawnDelay`, `spawnDistance`, `speed`

## Hacking (`hacking`)

### JMSB - Intel Package

- **Class** `jmfsb_moduleIntelPackage`
- **Category** jmfsb_modules
- Puts an intel package on a device. Hacking that device hands over a share of it.<br>Package - a class under Jmfsb_IntelPackages in the mission config Terminal Class - what to build if this is synchronised to nothing<br>How big a share one hack yields is a CBA setting - 1st Joint Multi-Functional Strike Battalion, Hacking. The package's own contents are mission config, not module attributes: see the wiki.
- **Attributes** `package`, `terminal`

## IADS (`iads`)

### JMSB - IADS / EMCON

- **Class** `jmfsb_moduleIADS`
- **Category** jmfsb_modules
- Emission control for the air defence net. Every radar the enemy has blinks on and off on its own jittered timer, a minimum number stay lit so the side is never blind, and everything on the net shares one picture.<br>WHY IT MATTERS: a radar that never stops radiating is a beacon that can be waited out. One that blinks cannot - a strike has to accept that something will see it, and the pilot's problem becomes timing rather than patience.<br>It manages every side the players are not on. Nothing is placed and nothing is spawned: it manages the radars already standing, whoever put them there.<br>Blink Min / Max - the range each set re-rolls its own timer in Minimum Emitters - how many stay lit per side, whatever the blink says Rescan - how often it looks for radars that were not there before Link Whole Side - share the picture beyond the air-defence net Reveal Interval - how often the picture reaches the mod's threat board Ambush Mode - UNVERIFIED, see the tooltip and run `#jmfsb iads.probe` first
- **Attributes** `ambush`, `blinkMax`, `blinkMin`, `debugMarkers`, `envelope`, `exempt`, `extraReceivers`, `linkAll`, `manageAir`, `minEmitters`, `rescan`, `revealEvery`

## Jamming (`jamming`)

### JMSB - Jamming

- **Class** `jmfsb_moduleJamming`
- **Category** jmfsb_modules
- Placing this module turns on jamming. Without it, the system is off. It places no jammers - a JMSB - Jammer Site module does that, one per emitter.<br>Site Radius Min / Max (m) - every site rolls its own reach between the two GPS Denial - one uplink per commander steering a wandering 1-2 km GPS sphere Uplink Radius (m) - the uplink's own GPS field Radio Burn-Through - a strong set beats a jammer, and is answered with a QRF Burn-Through Reference (mW) - the set power the field is calibrated against
- **Attributes** `burnRef`, `gpsUplinkRadius`, `largeRadius`, `maxPerSide`, `objectiveShare`, `smallRadius`

### JMSB - Jammer Site

- **Class** `jmfsb_moduleJammerSite`
- **Category** jmfsb_modules
- One jammer site, where you place it. Needs the JMSB - Jamming module on the map to arm.<br>Spectrum - radio, data or gps. One per site Radius (m) - 0 rolls one from the Jamming module's bounds Owner - whoever is hostile to the players, worked out from the mission's side relations<br>Artillery Reply - the site shells whoever loiters in its field Reply Delay (s) - how long a hostile must stay inside before it fires Reply Rounds / Scatter (m) - the size of the mission and how wide it falls Reply Cooldown (s) - minimum gap between two missions from this site
- **Attributes** `artyCooldown`, `artyDelay`, `artyRounds`, `artyScatter`, `domain`, `radius`

## Leaders (`leaders`)

### JMSB - Leader Chain

- **Class** `jmfsb_moduleLeaders`
- **Category** jmfsb_modules
- Placing this module turns on leader chain. Without it, the system is off.<br>Pool Cut Per Leader (%) - How much of the asymmetric commander's force pool dies with each leader Rotate Every (sec) - How often a leader moves to another safe house Trap Chance (%) - Chance a watched safe house is trapped with mortars Internet Pops - How many rugged-server props are placed for players to find and pull leads from
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

## QRF (`qrf`)

### JMSB - QRF

- **Class** `jmfsb_moduleQRF`
- **Category** jmfsb_modules
- Placing this module turns on qrf. Without it, the system is off.<br>Hold Time (sec) - How long players must hold an objective, uncontested, before it counts as taken Players Needed - How many players inside before a hold counts at all Squads Min - Fewest squads the third wave sends Squads Max - Most squads Asymmetric Mortar Chance (%) - An asymmetric commander answers with a few mortar rounds or with nothing - never a full barrage Cooldown (sec) - Retaking the same objective inside this window brings no second QRF
- **Attributes** `asymMortarChance`, `cooldown`, `holdTime`, `minPlayers`, `squadsMax`, `squadsMin`

## Reaction (`reaction`)

### JMSB - Enemy Reaction

- **Class** `jmfsb_moduleReaction`
- **Category** jmfsb_modules
- Placing this module turns on enemy reaction. Without it, the system is off.<br>Hack Fail Chance (%) - Chance an intrusion fails outright Detection Chance (%) - Chance a failure, a drone sighting or a transmission is noticed Barrage Rounds Min - Fewest shells a major response puts down Barrage Rounds Max - Most shells Radio Watts Watched - Transmit power at or above which a radio can be direction-found
- **Attributes** `detectChance`, `failChance`, `roundsMax`, `roundsMin`, `watts`

## Repair (`repair`)

### Timed Repair

- **Class** `jmfsb_moduleTimedRepair`
- **Category** jmfsb_modules
- Keeps everything synchronised to it serviceable: rearmed, refuelled and repaired on a timer, and optionally rebuilt if destroyed. A snapshot of each object is taken at mission start while it is still intact, and that is what a respawn is rebuilt from - so a respawned object comes back where it was placed, not where the blast left it.
- **Attributes** `debug`, `interval`, `rearm`, `refuel`, `repair_amount`, `replace_crew`, `respawn`, `respawn_delay`

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
