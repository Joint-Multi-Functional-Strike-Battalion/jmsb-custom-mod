# CBA settings

Everything under **Options > Addon Options**. `Default` is the value the addon
ships with, which a mission or the forced list below can override.

## TFAR Adapter (`adapter_tfar`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| RF voice override | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > RF - Voice (TFAR) | `true` | TFAR range follows RF link quality: the set's range shrinks as the link to its net weakens and is cut when RF reaches nobody. Off: TFAR's own range, u |
| Cut at quality | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Voice (TFAR) | `[0, 0.5, DEFAULT_VOICE_CUT, 2]` | Link quality (0-1) at or below which a net's voice is cut. 0 = only when RF says no link (SNR under its threshold). |
| Range at the weakest link | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Voice (TFAR) | `[0.05, 1, DEFAULT_VOICE_FLOOR, 2]` | Share of TFAR's normal range left at the lowest quality above the cut. Range grows linearly from here to full range at quality 1. |
| Hide TFAR's radio UI | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > RF - Voice (TFAR) | `true` | TFAR's transmit and channel-change popups do not show; the HUD's RADIO widget and the tablet's net row and RADIO app are the radio UI. Overrides TFAR' |
| Fill new sets from the plan | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > RF - Voice (TFAR) | `true` | A handheld or backpack set that carries none of the radio plan's nets when it is first seen (spawn, respawn, picked up) is loaded with the plan's fill |

## VON Adapter (`adapter_von`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Volume at the weakest link | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - VON | `[0, 1, DEFAULT_VOLUME_FLOOR, 2]` | VON volume of a radio speaker whose link quality is just above zero; it rises to full at quality 1. At quality 0 he is muted. |

## Admin Panel (`adminpanel`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable admin console | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Admin Console | `true` | Registers the admin console keybinds and the #jmfsb admin commands. Off leaves the addon loaded and inert - it does not grant or revoke anybody's admi |
| JMSB admins may open it | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Admin Console | `true` | Lets anyone carrying jmfsb's own admin flag open the console, as well as the uids in the mission's list. Off means the mission's list is the only way  |

## Air Defence Intercept (`adsite`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| CHECKBOX | Air Defence"]

[
    QGVAR(enabled) | Intercept incoming munitions > On: every air defence vehicle - a CIWS, an AA gun with a radar, a SAM launcher - shoots down artillery, rockets, missiles and bombs predicted to land inside its protected radius. Aircraft and drones are always left to the crews' own AI. | `ADS_CATEGORY` |  |
| Intercept chance | SLIDER | ADS_CATEGORY | `[0, 1, 0.75, 0, true]` | Rolled once per intercept attempt. A failed roll lets that round through that attempt; another unit may still try if there is time. |
| Intercept artillery and mortar | CHECKBOX | ADS_CATEGORY | `true` | Artillery and mortar shells, and the submunition carriers MLRS rockets are made of. |
| Intercept rockets | CHECKBOX | ADS_CATEGORY | `true` | Unguided rockets. |
| Intercept missiles | CHECKBOX | ADS_CATEGORY | `true` | Guided and cruise missiles other than anti-air ones. |
| Intercept bombs | CHECKBOX | ADS_CATEGORY | `true` | Free-fall and guided bombs. |
| Protect radius cap (m) | SLIDER | ADS_CATEGORY | `[500, 15000, 4000, 0]` | A unit protects the ground within its own weapon reach, but never further than this. A Site module's Protected Radius overrides it for that Site's veh |
| Ignore sides | CHECKBOX | ADS_CATEGORY | `false` | On: any round coming down inside a protected radius is intercepted, whoever fired it - friendly artillery too. Off: only rounds fired by a side hostil |
| Alarm - BLUFOR | LIST | ADS_CATEGORY | `[ADS_ALARM_INDICES, ADS_ALARM_NAMES, 2]` | Played on BLUFOR air defence and the loudspeakers near it when munitions are incoming. |
| Alarm - OPFOR | LIST | ADS_CATEGORY | `[ADS_ALARM_INDICES, ADS_ALARM_NAMES, 3]` | As BLUFOR's, for OPFOR air defence. |
| Alarm - Independent | LIST | ADS_CATEGORY | `[ADS_ALARM_INDICES, ADS_ALARM_NAMES, 4]` | As BLUFOR's, for Independent air defence. |
| Alarm repeat (s) | SLIDER | ADS_CATEGORY | `[5, 120, 20, 0]` | An area's alarm sounds once per salvo, and again only after this long. |

## Ai Disembark (`ai_disembark`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Force reload on disembarking AI | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - AI Disembark | `false` | Forces AI to play reload animation after disembarking from vehicle. Prevents instant shooting after disembark. |
| Stay in immobile vehicle chance | SLIDER | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - AI Disembark | `[0, 1, 0, 0, true]` | Chance that AI will be told to stay in immobilized vehicles, applied on vehicle init. |

## AntiShip (`antiship`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Seconds between launches | SLIDER | 1st Joint Multi-Functional Strike Battalion > Anti-Ship | `[60, 3600, AS_INTERVAL_DEF, 0]` | How long a battery waits between shots. The clock resets whether or not it found a hull, so a battery does not fire the instant a ship appears - that  |
| Search range (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Anti-Ship | `[1000, 30000, AS_SEARCH_DEF, 0]` | How far a battery looks for a hull. With a radar on the net it sees what the radar sees; with none it looks for itself, which is what this bounds. |
| Target classes | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Anti-Ship | `AS_TARGETS_DEF` | Comma-separated. What counts as a hull worth a missile. |
| Missile speed (m/s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Anti-Ship | `[200, 1500, AS_SPEED_DEF, 0]` | Cruise speed on the run in. Fast enough that it has to be met head-on rather than chased, which is the whole shape of defending against one. |
| Cruise altitude (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Anti-Ship | `[5, 500, AS_CRUISE_ALT_DEF, 0]` | Height above the sea on the run in. Low is what makes it hard to see coming and hard to engage. |
| Terminal range (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Anti-Ship | `[100, 5000, AS_TERMINAL_DEF, 0]` | Distance from the hull where it stops cruising and dives. |
| Interceptable | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Anti-Ship | `true` | The missile carries a decoy the defending side's AA and CIWS can engage. Off: nothing can lock it and it always arrives. |
| Debug | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Anti-Ship | `false` | Log every cycle to the RPT: what a battery looked for, what it found, what it fired and where the missile went. |

## APS (`aps`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Active protection | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > APS | `true` | Master switch. On, vehicles get the protection their faction's tier allows and the HUD's APS tile is live. Off, nothing is registered and every vehicl |
| Max engagement angle | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[10, 90, 45, 0]` | Steepest approach the launchers can engage, degrees above the horizon. A top-attack missile diving steeper than this gets through - the counter to har |
| Max round size (hit) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[200, 5000, 2000, 0]` | Rounds whose CfgAmmo hit value is above this are too big to stop - the launchers let them through. |
| Rearm range (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[10, 200, 50, 0]` | A vehicle within this of an ammo truck or crate reloads its charges. Reloading the vehicle's own guns reloads them too. |
| Rearm check (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[1, 60, 5, 0]` | How often a fitted vehicle looks for a rearm. |
| Default tier | LIST | 1st Joint Multi-Functional Strike Battalion > APS | `[[0, 1, 2, 3, 4], ["0 - irregular", "1 -` | The tier of a faction the mod does not know - a third-party mod's, usually. 0-1 nothing, 2 near-peer (basic hard kill on tanks and cannon IFVs), 3 pee |
| APS panel scope | LIST | 1st Joint Multi-Functional Strike Battalion > APS | `[[0, 1, 2], ["Own vehicle", "Group's veh` | Which fitted vehicles the map panel lists and lets you switch: only the one you are in, every vehicle your group is crewing, or every crewed vehicle o |
| Show APS panel | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | The APS panel on the map screen: every fitted vehicle you are entitled to see, its charges and its emitter, and the HK HOLD / RF HOLD / BURST switches |
| Tier overrides | EDITBOX | 1st Joint Multi-Functional Strike Battalion > APS | `""` | faction:tier pairs, comma separated - 'jmfsb_AAF:3, OPF_F:4'. The module's own field adds to these. |
| RF engagement radius (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[50, 500, 150, 0]` | The burst is a sphere this big. Guided munitions and drones inside it are hit. |
| RF close floor (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[10, 200, 60, 0]` | Anything susceptible inside this fires the burst whatever it seems to be doing. Outside it, only a contact closing on the vehicle does - transit traff |
| RF closing speed (m/s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[0, 100, 15, 0]` | A contact counts as closing when its speed toward the vehicle is above this. |
| RF cooldown (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[5, 300, 45, 0]` | The only resource the emitter has. A second attacker inside this window gets a free shot - the counter to the burst is to stagger, not mass. |
| RF jam radius (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[10, 300, 75, 0]` | Every radio inside this is jammed by the burst, friend and foe. Kept smaller than the engagement radius - it is the near-field leakage off the emitter |
| RF jam - dismounts (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[0, 30, 5, 1]` | How long a player on foot inside the jam radius loses the radio. |
| RF jam - own crew (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[0, 30, 2, 1]` | The emitting vehicle's own crew are shielded by the hull: a shorter blackout, never none - it is their cue that the burst fired. |
| RF emitter damage limit | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[0.1, 1, 0.3, 2]` | Vehicle damage above this kills the emitter; so does a dead engine or the engine off. |
| RF: quadcopter / FPV | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[0, 1, 1, 2]` | Chance the burst drops a small drone in range. |
| RF: loitering munition | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[0, 1, 0.9, 2]` | Chance the burst drops a loitering munition - hardened, so a little less. |
| RF: guided missile | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[0, 1, 0.6, 2]` | Chance the burst strips guidance from a missile with a modern seeker - hardened seekers resist. |
| RF: IR / laser guided | SLIDER | 1st Joint Multi-Functional Strike Battalion > APS | `[0, 1, 0.8, 2]` | Chance the burst upsets an IR or laser seeker. This is the dazzler's job, done properly - the seeker loses the track rather than merely veering. |

## Back To Game (`back_to_game`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable Back To Game | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Back To Game | `true` | Activate teleport and loadout restore after reconnect. |
| Teleport to leader | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Back To Game | `true` | Allow player teleportation to his group leader. |
| Teleport to vehicle | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Back To Game | `true` | Allow player teleportation to his last vehicle or group leader vehicle. |
| Remove body | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Back To Game | `true` | Removes bodies of alive people who disconnected. |

## BFT (`bft`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable group markers | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `true` | Blue Force Tracking: every group that has its tracker on is drawn on the map for everyone who shares one of its networks. |
| Auto enable for | LIST | 1st Joint Multi-Functional Strike Battalion > BFT | `[[0, 1, 2], ["None", "Player", "All"], 2` | None: nothing is tracked until switched on by hand. Player or All: groups nobody has configured are tracked automatically. |
| Member markers | LIST | 1st Joint Multi-Functional Strike Battalion > BFT | `[[0, 1, 2], ["Off", "Own squad", "All tr` | Individual marks for the men inside tracked groups, coloured by fire team. Own squad: your group's members. All tracked: every same-side tracked group |
| Member voice rings | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `true` | A ring round a member's mark while he talks: red on a radio net, magenta in direct voice. Needs game voice (jmfsb_voice). |
| Hide own group marker | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `true` | Your own group's marker is not drawn on your map - it sits on top of you and hides the ground. Everyone else on the net still sees it, and your own me |
| Show virtual friendlies | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `true` | Friendly groups ALiVE is simulating off-map are drawn faded, from the commander's own picture. Nothing about them is secret to their side. |
| Update delay | SLIDER | 1st Joint Multi-Functional Strike Battalion > BFT | `[1, 60, 5, 0]` | Delay between group marker updates. |
| Marker shape | LIST | 1st Joint Multi-Functional Strike Battalion > BFT | `[["a", "b", "o", "n"], ["Automatic", "Bl` | Warning! Taking this off automatic will also affect enemy groups. |
| Position: tracking mode | LIST | 1st Joint Multi-Functional Strike Battalion > BFT | `[["leader", "weightedAverage"], ["Leader` | The way a group's position is calculated. |
| Position: trailing mode | LIST | 1st Joint Multi-Functional Strike Battalion > BFT | `[["none", "weightedAverage", "delayed"],` | Lets a group's position trail behind its actual position. |
| Position: trailing count | SLIDER | 1st Joint Multi-Functional Strike Battalion > BFT | `[1, 25, 5, 0]` | Amount of recent positions considered. |
| Position: trailing weight | SLIDER | 1st Joint Multi-Functional Strike Battalion > BFT | `[0, 1, 0.75, 2]` | Factor with which the weight decreases with per position. |
| Map settings menu | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `true` | Allows group leaders to change their own marker with ACE self interaction while the map is open. |
| Group name options | EDITBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `["Zulu,Lima,Uniform,Echo,Whiskey,Tango"]` | Names available in the ACE BFT settings, separated by comma. |
| Preferred icons | EDITBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `["inf, motor_inf, mech_inf, air, armor, ` | Icons offered first, before the Other icons submenu. |
| Icons blacklist | EDITBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `["unknown, uav"]` | Icons a group leader may never pick. |
| Preferred colors | EDITBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `["ColorBLUFOR, ColorOPFOR, ColorIndepend` | Colors offered first, before the Other colors submenu. |
| Colors blacklist | EDITBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `["Default, ColorWEST, ColorEAST, ColorGU` | Colors a group leader may never pick. |
| Obfuscate other sides | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `true` | Groups of another side show as an unknown icon with their side's name and colour, rather than their own. |
| Admin sees everything | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > BFT | `true` | A logged-in admin draws every group: networks, tracker state and side obfuscation are all ignored for them. Admins can still switch it off for themsel |

## Backpack On Chest (`boc`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Disable BackpackOnChest | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Backpack On Chest | `false` | Prohibit BackpackOnChest features |
| Force Walking | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Backpack On Chest | `true` | Player is forced to walk when backpack is on chest |

## Chat (`chat`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Allow global/side chat | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Chat | `true` | Should players be allowed to chat on global and their side chat. If disabled chat messages from these channels will only be visible to admins and zeus |

## Common (`common`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| ISR unit variable | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Common | `"isISR"` | Name of the unit variable marking someone as an ISR operator. Gates the hacking tablet and Intel Hunt processing. Set it on a unit with: this setVaria |
| Threat Board Debug | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Common | `false` | Log every contact jmfsb's sensors file on a side's threat board - what that side knows, where, how wrong it might be, and which sensor said so. |

## Devices (`devices`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| F1 key on the tablet opens | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[SOFT_KEY_IDS, SOFT_KEY_NAMES, 1]` | SOFT_KEY_HELP |
| F2 key on the tablet opens | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[SOFT_KEY_IDS, SOFT_KEY_NAMES, 2]` | SOFT_KEY_HELP |
| F3 key on the tablet opens | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[SOFT_KEY_IDS, SOFT_KEY_NAMES, 3]` | SOFT_KEY_HELP |
| F4 key on the tablet opens | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[SOFT_KEY_IDS, SOFT_KEY_NAMES, 12]` | SOFT_KEY_HELP |
| Tablet size | SLIDER | 1st Joint Multi-Functional Strike Battalion > Devices | `[0.5, 1, 1, 2, true]` | How much of the monitor the tablet fills when it is open. 1 is as large as the screen allows; smaller leaves the world visible around it. |
| Phone size | SLIDER | 1st Joint Multi-Functional Strike Battalion > Devices | `[0.15, 0.5, 0.3, 2, true]` | How tall the phone's walking view is, as a fraction of the screen's height. The frame keeps its shape; this only scales it. |
| Phone map zoom | SLIDER | 1st Joint Multi-Functional Strike Battalion > Devices | `[0.005, 0.1, 0.015, 3, false]` | How far the phone and side devices' map is zoomed in. Smaller is closer. The map always stays centred on you. |
| Side device size | SLIDER | 1st Joint Multi-Functional Strike Battalion > Devices | `[0.2, 0.8, 0.42, 2, true]` | How tall a side device is, as a fraction of the screen's height. |
| Device opacity | SLIDER | 1st Joint Multi-Functional Strike Battalion > Devices | `[0.4, 1, 1, 2, true]` | How solid the phone or side device is on screen while walking. 1 is fully opaque. |
| Device button F1 | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[BUTTON_IDS, BUTTON_NAMES, 1]` | BUTTON_HELP |
| Device button F2 | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[BUTTON_IDS, BUTTON_NAMES, 2]` | BUTTON_HELP |
| Device button F3 | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[BUTTON_IDS, BUTTON_NAMES, 3]` | BUTTON_HELP |
| Device button F4 | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[BUTTON_IDS, BUTTON_NAMES, 4]` | BUTTON_HELP |
| Device button left | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[BUTTON_IDS, BUTTON_NAMES, 5]` | BUTTON_HELP |
| Device button right | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[BUTTON_IDS, BUTTON_NAMES, 6]` | BUTTON_HELP |
| Tablet frame | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[TABLET_FRAME_IDS, TABLET_FRAME_NAMES, 0` | Which frame the tablet wears: Auto (the UAV tablet with grips for the UAV skill, the large tablet otherwise), or always the large or always the UAV ta |
| Device grid digits | LIST | 1st Joint Multi-Functional Strike Battalion > Devices | `[GRID_DIGIT_CHOICES, GRID_DIGIT_NAMES, 0` | How many figures the GPS grid on the phone, side devices and tablet bar shows: 8 (10 m square, the default) or 10 (1 m). |

## Drone40 (`drone40`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Jammer radius (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drone40 | `[MIN_JAMMER_RADIUS, MAX_JAMMER_RADIUS, D` | How far a Drone40 Jammer's barrage counts in the RF link budget. Inside it the noise falls off with the band's path loss; past it, nothing. |
| Jammer power (dBm) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drone40 | `[MIN_JAMMER_POWER, MAX_JAMMER_POWER, DEF` | Transmit power of a Drone40 Jammer's barrage on VHF and UHF, as noise in the RF link budget. 30 = 1 W, 37 = 5 W, 43 = 20 W. |

## ECOTI (`ecoti`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable AiTR | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > ECOTI | `true` | Off: no AiTR boxes, labels or net cards for you, on any goggle. Your goggles' night vision and thermal are unaffected. |
| Sensor range (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > ECOTI | `[50, 1500, 600, 0]` | How far the clip-on picks up heat. Nothing beyond it is drawn. |
| Thermal window size | SLIDER | 1st Joint Multi-Functional Strike Battalion > ECOTI | `[0.1, 0.5, 0.375, 3]` | Radius of the round thermal window, as a fraction of the screen height. Nothing is drawn outside it. A JMSB goggle set to NVG full screen has no windo |
| Full contrast distance (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > ECOTI | `[10, 300, 75, 0]` | Inside this a box is drawn at full contrast. Past it, out to the sensor range, it fades. |
| Box line width (px) | SLIDER | 1st Joint Multi-Functional Strike Battalion > ECOTI | `[1, 8, 3, 0]` | How thick box lines are drawn, in screen pixels. |
| Own faction colour | COLOR | 1st Joint Multi-Functional Strike Battalion > ECOTI | `[0.2, 0.45, 1]` | Anyone of your own faction, and vehicles they crew. |
| Same side colour | COLOR | 1st Joint Multi-Functional Strike Battalion > ECOTI | `[0.2, 0.9, 0.3]` | Another faction on your side or a friendly one, and vehicles they crew. |
| Armed colour | COLOR | 1st Joint Multi-Functional Strike Battalion > ECOTI | `[1, 0.3, 0.25]` | Anyone hostile to your side, a civilian carrying a weapon, and vehicles they crew. Unarmed civilians are white; empty vehicles, animals and anyone of  |
| AiTR labels | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > ECOTI | `true` | Under each box, what it is, one thing about it and its range - PERSON \| ARMED \| 240 m. |

## Equipment (`equipment`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable Vector Target Marker | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Equipment | `true` | Allows placing a map marker on the point aimed at through a [JMSB] Vector Designator. |
| Vector Marker Type | LIST | 1st Joint Multi-Functional Strike Battalion > Equipment | `[ ["hd_dot", "hd_objective", "hd_destroy` | Marker placed on the target position. |
| Vector Marker Color | LIST | 1st Joint Multi-Functional Strike Battalion > Equipment | `[ ["Default", "ColorBlack", "ColorGrey",` | Color of the marker placed on the target position. |
| Vector 3D Marker Duration (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Equipment | `[0, 600, 120, 0]` | Shows the marker name in-world (3D) at the target position for this many seconds. 0 = disabled. |
| Vector Marker Lifetime (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Equipment | `[0, 1800, 0, 0]` | Marker is deleted after this many seconds. 0 = permanent. |
| Enable Vector Personal Waypoint | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Equipment | `true` | Allows dropping a waypoint only you can see on the point aimed at through a [JMSB] Vector Designator. One at a time; aiming at it again clears it. |
| Vector Waypoint Type | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Equipment | `"mil_dot"` | Marker type for the personal waypoint. Deliberately smaller than the shared target marker - mil_dot is a good default. |
| Vector Waypoint Colour | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Equipment | `"ColorYellow"` | Marker colour for the personal waypoint. Something the shared marker is not. |

## Evac (`evac`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable Medic Evac | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Evac | `true` | Master toggle for the medic 'Evacuate (Reinforce)' action that replaces respawn. Stands down on its own when Advanced Combat Medicine (ACM) is loaded, |
| Medics Only | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Evac | `true` | If checked, only ACE medics can evacuate a downed player. Uncheck to let anyone do it. |
| Evac Time (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Evac | `[0, 60, EVAC_DEFAULT_TIME, 0]` | How long the medic's evacuate progress bar takes, in seconds. |

## EW (`ew`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| DF tick (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[1, 15, DEFAULT_DF_TICK, 0]` | How often intercepts are taken, cuts crossed into fixes and each side's picture sent. |
| Fix window (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[5, 120, DEFAULT_FIX_WINDOW, 0]` | Two cuts from different places inside this window make a fix. Move after transmitting to beat it. |
| Track lifetime (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[30, 1800, DEFAULT_TRACK_TTL, 0]` | A track nobody has heard for this long is dropped. |
| Decoy battery (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[60, 3600, DEFAULT_DECOY_LIFE, 0]` | How long a placed decoy radiates before its battery is flat and it is removed. |
| GPS spoof radius (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[100, 3000, DEFAULT_SPOOF_RADIUS, 0]` | Reach of a GPS spoofer at full power; lower power steps reach less. |
| GPS spoof max drift (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[50, 2000, DEFAULT_SPOOF_DRIFT, 0]` | How far an unprotected GPS inside a spoofer's field is walked off its true position. |
| Jammer reach (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[500, 10000, DEFAULT_JAM_RANGE, 0]` | Past this distance a jammer adds no noise, whatever its power. |
| Jammer battery (Wh) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[20, 2000, DEFAULT_JAM_BATTERY_WH, 0]` | What a jammer module's battery holds. It runs the transmitter while the vehicle's engine is off; flat, the jammer goes off the air until the engine ru |
| Jammer charge with the engine running (W) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[10, 2000, DEFAULT_JAM_CHARGE_W, 0]` | What a running engine puts into the jammer's battery over the transmitter's own draw. |
| Jammer heating (% per sec at full output) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[0.05, 5, DEFAULT_JAM_HEAT_RISE, 2]` | How fast a jammer heats at 50 W continuous; less output heats it less. At 100% it cuts out until it has cooled to 60%. |
| Jammer cooling (% per sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[0.01, 2, DEFAULT_JAM_HEAT_COOL, 2]` | How fast a jammer sheds heat, transmitting or not. A jammer whose heating at its output is below this never cuts out. |
| Hacked GPS spoof (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[30, 1800, DEFAULT_SPOOF_HACK_TIME, 0]` | How long a net broken with the HACK app's SPOOF has its GPS walked off true, before it walks back. |
| Enemy AI EW skill | LIST | 1st Joint Multi-Functional Strike Battalion > EW | `[[AI_OFF, AI_BASIC, AI_ACTIVE, AI_SMART]` | OFF: the enemy AI takes no DF cuts. BASIC: its groups with a DF-capable radio take cuts on player transmitters, and a fix near its groups alerts those |
| Enemy AI fix reaction range (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > EW | `[200, 5000, DEFAULT_AI_RANGE, 0]` | An enemy fix this close to one of its groups is answered; farther fixes are only tracked. |

## Future Ammunition (`fa_ammo`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable Mk353 BRC Breaching Script | CHECKBOX | Fa Ammo | `true` | When enabled, firing the Mk353 BRC round near a door will attempt to force it open. Disable if a dedicated breaching mod handles this. |
| Debug Mk353 BRC Breaching | CHECKBOX | Fa Ammo | `false` | Prints each step of the breach detection/open logic to chat when firing the Mk353 BRC round, to help diagnose why a door isn't opening. |

## Future Ammunition - Anti-Drone (`fa_antidrone`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Anti-Drone Trigger Radius Multiplier | SLIDER | Fa Antidrone | `[0.25, 2, 1, 2]` | Scales the proximity trigger radius of all PAB rounds. 1 = default. |
| Anti-Drone Lethal Radius Multiplier | SLIDER | Fa Antidrone | `[0.25, 2, 1, 2]` | Scales the lethal (blast) radius of all PAB rounds. 1 = default. |
| Anti-Drone Damage Multiplier | SLIDER | Fa Antidrone | `[0.25, 2, 1, 2]` | Scales the proximity-airburst damage applied to UAVs by all PAB rounds. 1 = default. |

## Future Ammunition - Medium Caliber (`fa_mediumcaliber`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable Faction Scaling | CHECKBOX | [JMSB] Medium Caliber 2040 | `true` | Master toggle for the West/Green/Red performance gradient. Off = flat parity, everyone performs at West's 100%. |
| Green (Independent) Faction Fraction | SLIDER | [JMSB] Medium Caliber 2040 | `[0.50, 1.00, 0.85, 2]` | Fraction of West's performance ceiling realized by Independent/Green forces. 1.00 = parity with West. |
| Red (OPFOR) Faction Fraction | SLIDER | [JMSB] Medium Caliber 2040 | `[0.50, 1.00, 0.75, 2]` | Fraction of West's performance ceiling realized by OPFOR/Red forces. 1.00 = parity with West. |
| Counter-UAS Effectiveness Ceiling | SLIDER | [JMSB] Medium Caliber 2040 | `[0.75, 1.50, 1.40, 2]` | Scales the airburst/proximity radii and lethality of every programmable round in this module, on top of the faction fraction. |
| Enable Scripted Airburst | CHECKBOX | [JMSB] Medium Caliber 2040 | `true` | Master switch for the programmable-fuze subsystem (ABM, PROX, AHEAD, AMP, HE-AB). Off = these rounds behave as plain point-detonate/kinetic rounds. |

## Fatigue (`fatigue`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable custom high jog coefficient | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Fatigue | `false` | Enables custom high jog coefficient when moving with weapon ready. Requires ACE Advanced Fatigue working. |
| Custom high jog coefficient | SLIDER | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Fatigue | `[0.8, 1, 0.9, 0, true]` | Additional stamina used coefficient when moving with weapon ready. 100% is default ACE, 80% it's like you had low weapon ready. |

## Friendly Fire (`friendly_fire`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Friendly fire logging | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Friendly Fire | `false` |  |

## Grass (`grass`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Force Grass | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Grass | `false` | Forces grass for all players |

## Hacking (`hacking`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable Hacking | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Hacking | `true` | Master toggle for the tower/drone hacking self-interaction. |
| Hack Condition | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Hacking | `"true"` | SQF condition that must also return true before anyone can hack. `_this` is the unit. Left as ""true"" it never blocks anything. Example: side group _ |
| Hackable Tower Classes | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Hacking | `"Land_TTowerBig_2_F,Land_TTowerBig_1_F,L` | Comma-separated object classnames hackable as 'towers', in addition to Electronic War Zones emitters. |
| Downable Drone Classes | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Hacking | `""` | Comma-separated vehicle classnames that 'Down Drone' may target. Blank = any enemy UAV, which is the old behaviour. Listed classes still have to be en |
| Require ISR operator | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Hacking | `true` | On: only a unit flagged as ISR can use the intrusion suite. This is the ONLY gate on hacking - no device is checked. The flag and its variable name ar |
| Scanner Variable | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Hacking | `"jmfsb_isScanner"` | Unit variable that controls who sweeps for emitters. Everyone does by default - no device and no flag needed. Set this variable FALSE on a unit to den |
| Scanner Alarm Volume | SLIDER | 1st Joint Multi-Functional Strike Battalion > Hacking | `[0, 2, 1, 1]` | How loud YOUR scanner's alarm beeps. 0 silences the beep entirely - the screen still blinks and the notification still shows. |
| Remote Unit Hack | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Hacking | `false` | Players can hack an enemy soldier's comms at range. Success buys one intel product centred on the target; failure can alert the area and jam your own  |
| Remote Hack Range (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Hacking | `[50, 3000, 800, 0]` | How far a target handset can be to start a remote hack, and how far before the signal drops. Everything else about the failure package keeps its shipp |
| Tower TAOR Marker(s) | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Hacking | `""` | Comma-separated area marker names. Towers are hackable only inside them. Blank = anywhere on the map. |
| Enemy Cell Phone Carriers (%) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Hacking | `[0, 100, 30, 0]` | Percentage of enemy soldiers carrying a hackable cell phone. The rest have nothing to hack. Requires Remote Unit Hack on. |
| Deposits per Hint | SLIDER | 1st Joint Multi-Functional Strike Battalion > Hacking | `[1, 50, 10, 0]` | Intel items that must be DEPOSITED at a drop before ISR processes a batch and one hint circle fires. Items carried in a pocket count for nothing. |
| Documents on Bodies (%) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Hacking | `[0, 100, 30, 0]` | Chance a body with no phone still carries searchable documents. Insurgents always carry a phone, so this only governs everyone else. |
| Extra detection per net | SLIDER | 1st Joint Multi-Functional Strike Battalion > Hacking | `[0, 40, 10, 0, false]` | How much each net broken recently adds to the chance of being detected on the NEXT one, in percentage points. 0 restores a flat chance. |
| Detection memory | SLIDER | 1st Joint Multi-Functional Strike Battalion > Hacking | `[60, 3600, 600, 0, false]` | How long, in seconds, a broken net keeps counting against you. One step is shed for every window that passes quietly, so a patient section is forgiven |
| Hackable nets | LIST | 1st Joint Multi-Functional Strike Battalion > Hacking | `[[0, 1, 2], ["Hostile only", "Hostile an` | Whose cell nets the remote hack will offer. Your own group is never on the list. A net that is not hostile is labelled FRIENDLY on the card, so nobody |
| Intel package share per hack (%) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Hacking | `[5, 100, HACK_PACKAGE_SHARE_DEF, 0]` | How much of a terminal's intel package one successful break-in yields. Lower means more return visits. 100 hands the whole package over at once. |

## HUD (`hud`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable HUD | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > HUD | `true` | Draws the two readout slots on the game screen. Off leaves the screen exactly as it was; the map suite is unaffected either way. |
| Hide with the map | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > HUD | `true` | Takes the HUD off screen while the map is open, where the tacpad shows the same readings in more detail. Off leaves it up, over the map. |
| Show in tablet mode | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > HUD | `false` | Keeps the HUD slots on the game screen when the tacpad display mode is TABLET. Off by default there: the device shows the same readouts. |
| HUD opacity | SLIDER | 1st Joint Multi-Functional Strike Battalion > HUD | `[0, 1, 0.55, 2, true]` | How solid the slot backgrounds are over the world. The text stays fully opaque at any setting. |

## Init (`init`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Mission Type | LIST | _YMFsettings > Mission | `[[0,1,2,3], ["Custom", "Operation", "Tra` | This will deside on what kind of startup hint you get on mission start. |
| AI Setting | LIST | _YMFsettings > Mission | `[[0,1,2], ["Arma Default", "Adjusted", "` | Adjusts AI skill so they are less godlike. Arma Default leaves every AI's skill exactly as its own config sets it and runs no skill script at all. |
| Enable | CHECKBOX | _YMFsettings > Radios | `true` | Allow mission to set up and handle radio distributution |
| Squad Radio Channels (ACRE) | CHECKBOX | _YMFsettings > Radios | `true` | Allow radio channels to be changed based on player squadname. |
| Documents | CHECKBOX | _YMFsettings > Player | `true` | Allow the mission to write diary help documents. |
| Rank | CHECKBOX | _YMFsettings > Player | `true` | Allow mission to apply arma rank based on name rank prefixes. |
| Insignia | CHECKBOX | _YMFsettings > Player | `true` | Put the battalion patch on every player's uniform. A patch a player picks in the arsenal (Medic, EOD, JFIRE...) is kept. |
| Apply Earplugs | CHECKBOX | _YMFsettings > Player | `true` | Automaticly apply earplugs to players on spawn and respawn. |
| Enable | CHECKBOX | _YMFsettings > Staging | `true` | Enables the staging system. |
| Enable | CHECKBOX | _YMFsettings > Vehicle | `true` | Enables scripted settings and functions to apply to vehicles. |
| Pylon | CHECKBOX | _YMFsettings > Vehicle | `true` | Enables scripted loadouts or pylon to be applied to vehicles based on faction |
| Inventory | CHECKBOX | _YMFsettings > Vehicle | `true` | Enables scripted inventory to be applied to vehicles based on faction |
| Radio | CHECKBOX | _YMFsettings > Vehicle | `false` | Enables vehicles radio to be enabled and set on vehicles |
| Factions | EDITBOX | _YMFsettings > Vehicle | `'["BLU_CTRG_F","BLU_W_F","BLU_T_F","BLU_` | Array of factions allowing system loadout and pylon changes |
| Simulation Type | LIST | _YMFsettings > Combat Jump Simulation | `[[0,1,2], ["None", "Basic", "Advanced"],` | Combat jump simulation is a system that checks for lose equiped gear in the form of;\nnight vision googles, hats or glasses and make you lose the on a |
| Include Night Vision Googles | CHECKBOX | _YMFsettings > Combat Jump Simulation | `true` | Include equiped Night Vison Googles in the simulation. |
| Include Non-combat Googles | CHECKBOX | _YMFsettings > Combat Jump Simulation | `true` | Include Non-combat Googles in the simulation. This refere to sunshades and simular non-safety googles. |
| Include Non-combat Headgear | CHECKBOX | _YMFsettings > Combat Jump Simulation | `true` | Include Non-combat Headgear in the simulation. This refere to hats bandanas and baretes. |
| Radar network | CHECKBOX | _YMFsettings > Radar | `true` | Put the vehicle classes below on their side's sensor network at mission start. Off means no vehicle is touched, whatever is listed. |
| Vehicle classes | EDITBOX | _YMFsettings > Radar | `""` | Classnames, separated by commas or new lines. Each one joins its side's datalink the moment it exists, including vehicles spawned an hour in. A class  |

## Insurgents (`insurgents`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| (built at runtime) | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Insurgents | `true` | If disabled gear from this configFile class will be not used. Mission defined gear will be not disabled. |

## Main Menu (`main_menu`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| 1 - Left button name | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"JMSB Training Server"` | What the left button says. Empty leaves whatever the config called it. |
| 1 - Left button address | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"172.93.101.237"` | Host or IP the left button connects to. Empty removes the button. |
| 1 - Left button port | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"2402"` | Port for the left button. 0 or empty removes the button. |
| 1 - Left button password | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"aitd"` | Sent with the connection. Empty for an open server. Stored in your profile in plain text. |
| 1 - Left button colour | COLOR | 1st Joint Multi-Functional Strike Battalion > Main Menu | `[0.761, 0.659, 0.471, 1]` | Background of the left button. the unit's tan by default. |
| 2 - Centre button name | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"JMSB Operations Server"` | What the centre button says. Empty leaves whatever the config called it. |
| 2 - Centre button address | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"172.93.101.237"` | Host or IP the centre button connects to. Empty removes the button. |
| 2 - Centre button port | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"2302"` | Port for the centre button. 0 or empty removes the button. |
| 2 - Centre button password | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"aitd"` | Sent with the connection. Empty for an open server. Stored in your profile in plain text. |
| 2 - Centre button colour | COLOR | 1st Joint Multi-Functional Strike Battalion > Main Menu | `[0.761, 0.659, 0.471, 1]` | Background of the centre button. the unit's tan by default. |
| 3 - Right button name | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"JMSB Events Server"` | What the right button says. Empty leaves whatever the config called it. |
| 3 - Right button address | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"172.93.101.237"` | Host or IP the right button connects to. Empty removes the button. |
| 3 - Right button port | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"2502"` | Port for the right button. 0 or empty removes the button. |
| 3 - Right button password | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Main Menu | `"aitd"` | Sent with the connection. Empty for an open server. Stored in your profile in plain text. |
| 3 - Right button colour | COLOR | 1st Joint Multi-Functional Strike Battalion > Main Menu | `[0.761, 0.659, 0.471, 1]` | Background of the right button. the unit's tan by default. |

## Map Tools (`maptools`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Bearing units | LIST | 1st Joint Multi-Functional Strike Battalion > Map Tools | `[["deg", "mil", "both"], ["Degrees", "Mi` | How the ruler, protractor and route give a bearing: degrees, NATO mils (6400 to the circle), or both. |
| Share marks with group | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Map Tools | `false` | MARK drops a marker with grid and time. Off keeps it on your map only; on puts it on the group channel. |
| Viewshed radius | SLIDER | 1st Joint Multi-Functional Strike Battalion > Map Tools | `[VS_RADIUS_MIN, VS_RADIUS_MAX, VS_RADIUS` | How far, in metres, VIEWSHED works out line of sight from the clicked point. |
| Viewshed resolution | SLIDER | 1st Joint Multi-Functional Strike Battalion > Map Tools | `[VS_CELL_MIN, VS_CELL_MAX, VS_CELL_DEFAU` | The size, in metres, of one VIEWSHED cell. Smaller is finer and slower to fill. |

## MedBags (`medbags`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Boo Boo Bag contents | EDITBOX | 1st Joint Multi-Functional Strike Battalion > MedBags | `"ACE_fieldDressing:6, ACE_quikClot:6, AC` | class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps. |
| Medic Bag contents | EDITBOX | 1st Joint Multi-Functional Strike Battalion > MedBags | `"ACE_fieldDressing:18, ACE_elasticBandag` | class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps. |
| Trauma Kit contents | EDITBOX | 1st Joint Multi-Functional Strike Battalion > MedBags | `"ACE_fieldDressing:28, ACE_elasticBandag` | class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps. |
| Fluid Kit contents | EDITBOX | 1st Joint Multi-Functional Strike Battalion > MedBags | `"ACE_salineIV:24, ACE_plasmaIV:12, ACE_b` | class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps. |
| Drug Kit contents | EDITBOX | 1st Joint Multi-Functional Strike Battalion > MedBags | `"ACE_morphine:16, ACE_adenosine:8, ACE_e` | class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps. |
| MOPP Bag contents | EDITBOX | 1st Joint Multi-Functional Strike Battalion > MedBags | `"JCA_G_AirPurifyingRespirator_03_black_c` | class:count, comma separated, issued after the bag's own CBRN suit. Respirator and the ACM CBRN self-aid autoinjectors. |
| Fill order | LIST | 1st Joint Multi-Functional Strike Battalion > MedBags | `[ ["3,2,1", "1,2,3", "2,3,1", "2,1,3"], ` | Which container an unpacked item goes in first. The rest are tried in turn as each fills up. Applies to every bag, and to bags taken off a casualty. |
| Overflow to the ground | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > MedBags | `true` | What will not fit is dropped at the unit's feet. Off: the surplus is not issued at all. Never drops anything in a vehicle or in deep water. |

## Medical Treatment (`medical_treatment`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Fatal Injuries Cardiac Arrest Time Coefficient | SLIDER | 1st Joint Multi-Functional Strike Battalion > Medical Treatment | `[0.01, 1, 0.2, 2]` | Coefficient for controlling the Cardiac Arrest Time on fatal injuries when 'Fatal Injuries' is NOT 'Always'. |

## Messaging (`messaging`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable messaging | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `true` | Off refuses every submission and leaves the store empty. Nothing else in the mod depends on it being on. |
| Shared mailboxes | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `"C2, C2.reports, FIRES, FIRES.cas, FIRES` | Comma-separated names of mailboxes anybody can address. A thread sent to one is filed there rather than mailed to a person. Empty means personal and g |
| Command group | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `""` | Group name, as shown on its roster row, that a report reaches when its ROUTING line is ticked. Empty disables the tick. |
| Idle close (min) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Messaging | `[0, 240, 60, 0, true]` | A thread nobody has touched for this long closes itself. 0 never closes one. |
| EW link state | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `true` | Jamming affects the data link: inside a jammer's falloff a send transmits late, inside its core it is refused outright. Receiving is never blocked. Th |
| TIC alerts the side | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `true` | A CONTACT REPORT (TIC) reaches every player on the sender's side and raises the shared alert bus, on top of whoever it was addressed to. |
| TIC drops a map marker | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `true` | Marks the contact grid for the sender's side. |
| TIC marker type | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `"loc_Attack"` | CfgMarkers class for the marker a TIC drops. loc_Attack is the crossed-swords task icon - a contact is an event, not a unit symbol, and o_inf put a re |
| TIC marker colour | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `"ColorRed"` | CfgMarkerColors class for the marker a TIC drops. |
| Post reports to ALiVE | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `true` | A template marked reportable - CONTACTREP and SITREP - is also filed with ALiVE's C2ISTAR as a spotrep or sitrep, with a companion map marker. Silentl |
| ALiVE report locality | LIST | 1st Joint Multi-Functional Strike Battalion > Messaging | `[["GLOBAL", "SIDE", "GROUP"], ["Everyone` | Who an ALiVE-posted report and its marker are visible to. |
| SITREP marker type | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `"b_inf"` | CfgMarkers class for the marker that accompanies an ALiVE-posted SITREP. |
| Seed test traffic | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Messaging | `false` | Posts three sample threads - a FLASH CASEVAC, a SITREP and a CONTACTREP - shortly after you join, so the reader has something in it. For testing the U |

## Mission (`mission`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Staging zone satellite uplink | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Staging | `true` | Every staging zone carries a radio base station at its centre: it relays the players' nets round the zone and links by satellite to the patrol bases a |

## Notify (`notify`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable stacked notifications | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Notifications | `true` | Off falls back to the plain hint the caller would otherwise have used. |
| Hide notifications | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Notifications | `false` | Shows no popup and no hint. Notifications are still kept in the tacpad reader's LOG view. |
| Corner | LIST | 1st Joint Multi-Functional Strike Battalion > Notifications | `[[0, 1, 2, 3], ["Top left", "Top right",` | Which corner the stack grows from. |
| Max on screen | SLIDER | 1st Joint Multi-Functional Strike Battalion > Notifications | `[1, SLOT_COUNT, 4, 0, true]` | Notifications shown at once; the rest queue until a slot frees. |
| Duration (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Notifications | `[2, 30, 8, 0, true]` | How long a notification stays before it fades out. |
| Width | SLIDER | 1st Joint Multi-Functional Strike Battalion > Notifications | `[0.1, 0.5, 0.22, 2, true]` | Width of the stack as a fraction of the safe zone. |
| Text size | SLIDER | 1st Joint Multi-Functional Strike Battalion > Notifications | `[0.5, 3, 1, 2, true]` | Scales the notification text. The panel grows with it, so a larger size means taller notifications rather than cramped ones. |
| Font | LIST | 1st Joint Multi-Functional Strike Battalion > Notifications | `[ ["RobotoCondensed", "RobotoCondensedBo` | Typeface for notifications. The monospace and console faces suit a technical readout; the Purista faces are what Arma's own UI uses. |

## Nvg (`nvg`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| NVG full screen | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > NVG | `true` | On: JMSB goggles fill the whole screen in NVG mode. Off: the view is seen through the tubes - ACE's mask for the goggle the JMSB one was made from. |

## TAC//PAC (`pac`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Test as Steam id (editor only) | EDITBOX | 1st Joint Multi-Functional Strike Battalion PAC > Service | `""` | Editor and singleplayer have no Steam id. Put yours here (17 digits) to test as your real operator - the database record for you loads. Empty = a thro |
| Log this server's public IP at boot | CHECKBOX | 1st Joint Multi-Functional Strike Battalion PAC > Service | `false` | Off by default. At mission start the server asks an outside service (api.ipify.org) what address it calls out from, and writes it to the .rpt with a v |

## Patrol Base (`patrol_base`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enabled | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Patrol Base | `true` | Enable the patrol base system. |
| Patrol base radio relay | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Patrol Base | `true` | A built patrol base carries a base station: it relays the side's radio nets round the base and links by satellite to the staging zone and the other ba |
| Max patrol bases | SLIDER | 1st Joint Multi-Functional Strike Battalion > Patrol Base | `[1, 10, 3, 0, true]` | How many patrol bases may exist at once. |
| Kits required | SLIDER | 1st Joint Multi-Functional Strike Battalion > Patrol Base | `[1, 10, 4, 0, true]` | How many Patrol Base Kits must be dropped within range to build one base. |
| Kit gather range (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Patrol Base | `[1, 30, 5, 1, true]` | Radius the dropped kits must lie within to count. |
| Base object | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Patrol Base | `"jmfsb_satcom_deployed"` | Class spawned at the base on deploy - it marks the location and carries the Unbuild action. Defaults to jmfsb's own SatCom mast; if that class is not  |
| On-deploy init (SQF) | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Patrol Base | `"params ['_base', '_pos', '_name', '_sid` | SQF run on the server after a base is built. Passed: [_beacon, _pos, _name, _side, _builder]. Blank = nothing. |
| On-undeploy init (SQF) | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Patrol Base | `"params ['_object']; [_object] remoteExe` | SQF run on the server while the base beacon still exists (before it is deleted). Passed: [_beacon, _pos, _name, _side]. Blank = nothing. |

## Players (`players`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Use squad tags in names | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Players | `false` | Reads each player's squad.xml tag and puts it in front of their name. Off (the default) leaves the profile name untouched and never asks the engine fo |

## Pointing (`pointing`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable pointing in vehicles | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Pointing | `true` | Allows to point current camera direction in vehicles to rest of the crew. |

## Radio Mesh (`radio_mesh`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable mesh relaying | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Radio Mesh | `false` | OFF by default. On: friendly manpacks and vehicle racks on the same frequency relay transmissions that cannot reach a receiver directly. Off: ACRE's s |
| Relay radios | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Radio Mesh | `"ACRE_PRC152,ACRE_PRC117F"` | Comma-separated ACRE base radio classes that act as relay nodes when carried or racked. Anything can still be an end point. |
| Loss per weak hop | SLIDER | 1st Joint Multi-Functional Strike Battalion > Radio Mesh | `[0, 0.5, 0.1, 2]` | Fraction of signal quality lost for every relay hop made by a radio transmitting below the power threshold. 0 = lossless. |
| Weak-hop threshold (mW) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Radio Mesh | `[0, 10000, 1000, 0]` | Relays transmitting below this power pay the loss per hop; at or above it they repeat cleanly. 1000 = 1 W. |
| Relay table refresh (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Radio Mesh | `[1, 30, 5, 0]` | Seconds between rebuilds of the list of relay-capable radios on this client. |
| Relays considered per transmission | SLIDER | 1st Joint Multi-Functional Strike Battalion > Radio Mesh | `[2, 64, 16, 0]` | Upper bound on relay radios examined for one transmission - the nearest to the transmitter/receiver line. Keeps the path search bounded on busy nets. |

## Remotesensors (`remotesensors`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable remote sensors on clients | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Remote Sensors | `true` | This command will halt raycasting calculations (on the local machine only) for all groups which don't contain any local entities. Units, that are not  |

## Respawn (`respawn`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable respawn | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Respawn | `false` | Enables respawn with given delay. |
| Respawn delay | SLIDER | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Respawn | `[1, 900, getNumber (configFile >> "CfgRe` | How much time must pass before player will respawn (if respawn is enabled). |

## RF (`rf`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Player tick (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Tick | `[0.5, 10, DEFAULT_TICK_PLAYERS, 1]` | How often links involving a moving node are recomputed. |
| Static tick (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Tick | `[1, 60, DEFAULT_TICK_STATIC, 0]` | How long a link between nodes that have not moved is reused before it is recomputed. |
| AI nodes counted | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > RF - Tick | `false` | Off: nodes held by AI men take no part in the mesh unless the node is flagged. Vehicles and placed nodes always count. |
| Debug map overlay | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > RF - Tick | `false` | Lines on the map between linked nodes, red to green by quality. Sends every link to every client while on. |
| VHF path-loss exponent | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[2, 6, VHF_EXP, 2]` | Log-distance exponent for the VHF band. |
| VHF loss at 1 m (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[0, 80, VHF_REF, 0]` | Path loss at the 1 m reference for the VHF band. |
| VHF noise floor (dBm) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[-130, -80, VHF_FLOOR, 0]` | Receiver noise floor for the VHF band, before any interference. |
| UHF path-loss exponent | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[2, 6, UHF_EXP, 2]` | Log-distance exponent for the UHF band. |
| UHF loss at 1 m (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[0, 80, UHF_REF, 0]` | Path loss at the 1 m reference for the UHF band. |
| UHF noise floor (dBm) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[-130, -80, UHF_FLOOR, 0]` | Receiver noise floor for the UHF band, before any interference. |
| SAT path-loss exponent | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[2, 5, SAT_EXP, 2]` | Log-distance exponent for ground emitters on the SAT band (jammers, intercept). The satellite link itself has no path loss. |
| SAT loss at 1 m (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[20, 80, SAT_REF, 0]` | Path loss at the 1 m reference for ground emitters on the SAT band (jammers, intercept). The satellite link itself has no path loss. |
| SAT noise floor (dBm) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[-130, -80, SAT_FLOOR, 0]` | Receiver noise floor for the SAT band, before any interference. |
| SAT rain fade (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[0, 20, DEFAULT_SAT_FADE_DB, 1]` | How much the satellite link loses in full rain. An overcast sky with no rain counts a quarter of it. 0 = weather never touches SAT. |
| VIDEO path-loss exponent | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[2, 5, VIDEO_EXP, 2]` | Log-distance exponent for the VIDEO band. |
| VIDEO loss at 1 m (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[20, 80, VIDEO_REF, 0]` | Path loss at the 1 m reference for the VIDEO band. |
| VIDEO noise floor (dBm) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[-130, -80, VIDEO_FLOOR, 0]` | Receiver noise floor for the VIDEO band, before any interference. |
| Quality threshold (dB SNR) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[0, 20, DEFAULT_THR_DB, 0]` | SNR at which link quality is 0. Open item: the spec says 6 dB, the tablet mockups 3 dB. |
| Quality span (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Bands | `[5, 40, DEFAULT_SPAN_DB, 0]` | SNR above the threshold at which link quality is 1. |
| Terrain per blocked sample (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Obstacles | `[0, 40, DEFAULT_TERRAIN_DB, 0]` | Loss for each of the three path samples the ground blocks. |
| Wall (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Obstacles | `[0, 40, DEFAULT_WALL_DB, 0]` | Loss for each building or structure on the path. |
| Tree (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Obstacles | `[0, 40, DEFAULT_TREE_DB, 0]` | Loss for each tree or bush on the path. |
| Prone (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Obstacles | `[0, 40, DEFAULT_PRONE_DB, 0]` | Loss at an end whose holder is prone. |
| Inside a vehicle (dB) | SLIDER | 1st Joint Multi-Functional Strike Battalion > RF - Obstacles | `[0, 40, DEFAULT_VEHICLE_DB, 0]` | Loss at an end whose holder is inside a vehicle on a handheld set. |

## Safestart (`safestart`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Lock weapon | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - safestart | `true` | Locks your weapon safety on game start |

## Spectator (`spectator`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable spectator | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Enables spectator for dead players |
| Allow spectator for unconscious | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows spectator also for unconscious players. Requires enabling spectator. |
| Enable spectator (CLIENT) | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `true` | Enables spectator when unconscious if it's allowed by server setting. |
| Unconscious spectator delay | SLIDER | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `[1, 300, 30, 0]` | How much time must pass before unconscious players get spectator. |
| Sides available for spectating | LIST | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `[[0, 1, 3, 4, 2], ["Friendly", "Player s` | Spectator will be able to see and track units from given sides. |
| Sides available for spectating | LIST | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `[[0, 1, 3, 4, 2], ["Friendly", "Player s` | Spectator will be able to see and track units from given sides. |
| Allow civilian spectating | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows tracking units from civilian side. |
| Allow civilian spectating | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows tracking units from civilian side. |
| Allow AI spectating | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows tracking AI units from whitelisted sides. |
| Allow AI spectating | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows tracking AI units from whitelisted sides. |
| Allow free camera | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows spectator to move his camera freely. |
| Allow free camera | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows spectator to move his camera freely. |
| Allow TPP Camera | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows spectator to use third person camera. |
| Allow TPP Camera | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Spectator | `false` | Allows spectator to use third person camera. |

## Tacpad (`tacpad`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable tacpad | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | Draws the tacpad panels on the map screen. Off leaves the vanilla map exactly as it was. |
| Display mode | LIST | 1st Joint Multi-Functional Strike Battalion > Tacpad | `[["native", "tablet"], ["Native", "Table` | NATIVE draws the tacpad on the map screen as it always has. TABLET takes it off the map and puts the same screens inside a device - open it from the A |
| Colour scheme | LIST | 1st Joint Multi-Functional Strike Battalion > Tacpad | `[ ["jmsb", "light", "olive", "sand", "ni` | Four day grounds and four night ones, in matching pairs: JMSB DAY with JMSB NIGHT (the unit's ranger green and tan; night is the default), FIELD GREY  |
| Panel opacity | SLIDER | 1st Joint Multi-Functional Strike Battalion > Tacpad | `[0.3, 1, 0.92, 2, true]` | How solid a panel's ground is over the map. The text stays fully opaque at any setting - a translucent panel you cannot read is not a panel. |
| Keep clear of reserved areas | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | Slides a panel out of the game menu, the chat overlay and the map's scale and contour legend when you drop it on one. Off lets you put a panel anywher |
| Custom: ground | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `""` | Panel background as r,g,b from 0 to 1, e.g. 0.05,0.06,0.05. Used only by the Custom scheme. |
| Custom: text | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `""` | Text and divider colour as r,g,b from 0 to 1. Used only by the Custom scheme. |
| Custom: accent | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `""` | Selection, alerts and FLASH traffic as r,g,b from 0 to 1. Used only by the Custom scheme. |
| Quick replies | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `["roger, wilco, WAIT ONE, SMOKE OUT, LZ ` | The buttons under an open thread, separated by commas. A template id (roger, wilco, inprogress, cantco, close) sends that reply; anything else is sent |
| UI size | SLIDER | 1st Joint Multi-Functional Strike Battalion > Tacpad | `[0.5, 2, 1, 2, true]` | Scales the whole tacpad - panels, rows and type together. The in-game settings screen steps it by 1, 5 or 10 percent; this is the same number. |
| Text size | SLIDER | 1st Joint Multi-Functional Strike Battalion > Tacpad | `[0.6, 2.5, 1.2, 2, true]` | Scales all tacpad text. Rows and headers grow with it, so a larger setting means fewer rows visible rather than text spilling out of them. |

## Tacpad Apps (`tacpad_apps`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Show live tiles | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | The band across the top: drones, jamming, weather and radio. Clicking a tile opens that app. |
| Live tile rows | LIST | 1st Joint Multi-Functional Strike Battalion > Tacpad | `[["1", "2"], ["One row", "Two rows"], 0]` | How many rows the tile band stands in. One is the design's band across the top; two stacks the same tiles in half the width. |
| Show squad list | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | The left rail: one row per man with a health swatch. |
| Show message reader | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | The docked message reader. Needs the messaging addon - without it the panel says so. |
| Show troops in contact button | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | The big one under the rail. One press marks the map, alerts the side and files a contact report on the command net. A mission that would rather a cont |
| Show map tools | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | The tool strip along the bottom: centre, ruler, protractor, route, mark, grid, viewshed and clear. |
| Reader: high density | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `false` | Off is standard density - subject on one line, state under it. On puts one thread per row so a screenful can be scanned at once, which is what a TOC w |
| Show settings gear | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Tacpad | `true` | The gear under the message reader that opens the settings screen. Off leaves Addon Options as the only way to change the suite. |

## Tagging (`tagging`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Enable ACE Tagging markers | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Tagging | `false` | Automatically create markers on buildings sprayed with ACE Spray. |

## Teleport (`teleport`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Action visibility radius | SLIDER | 1st Joint Multi-Functional Strike Battalion > Teleport | `[5, 30, 5, 0]` | How close to a teleport object the action shows, in metres. |
| Teleportation time | SLIDER | 1st Joint Multi-Functional Strike Battalion > Teleport | `[1, 120, 6, 0]` | How long the move and its screen fade last, in seconds. |

## Towing (`towing`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Add ropes to heavy duty vehicles | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Towing | `true` | Enables adding ropes to inventories of heavy duty vehicles such as MRAPs, IFVs, APCs and Tanks. |
| Add ropes to cars | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > 1st Joint Multi-Functional Strike Battalion - Towing | `false` | Enables adding ropes to inventories of cars. |

## UAS (`uas`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Outage minimum (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drones | `[60, 3600, 600, 0]` | Shortest time a destroyed cache holds the ceiling down. Outages extend rather than stack, so supply raids are raids and not a win button. |
| Outage maximum (s) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drones | `[60, 7200, 1800, 0]` | Longest time a destroyed cache holds the ceiling down. |
| Supply caches per side | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drones | `[0, 12, 3, 0]` | Unmarked crates placed inside that side's patrol zones, split across them. Finding them is what the intel economy is for; killing one drops the ceilin |
| Swarm airframes | EDITBOX | 1st Joint Multi-Functional Strike Battalion > Drones | `"O_UAV_01_F,B_UAV_01_F,I_UAV_01_F"` | Comma-separated UAV classes a Drone Swarm module may field. Empty allows any. A module naming a class outside this list refuses to launch and says so  |
| Patrol ALiVE objectives | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Drones | `false` | Turn a share of each commander's ALiVE objectives into patrol zones, once, when the campaign comes up. Hand-placed Drone Patrol modules are unaffected |
| ALiVE objectives patrolled (%) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drones | `[0, 100, 30, 0]` | Share of one commander's objectives that get a patrol zone. This shapes a small map; the cap below is what bounds a big one. |
| Max ALiVE zones per side | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drones | `[0, 30, 6, 0]` | Hard ceiling per commander whatever the share works out to. A percentage has no ceiling - 30% of 173 objectives is 52 zones, and the planner would try |
| ALiVE zone radius (m) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drones | `[0, 3000, 0, 0]` | Orbit radius for a zone taken from an objective. 0 uses the objective's own size, which is what ALiVE thinks that place is worth. |
| Airframes per ALiVE zone | SLIDER | 1st Joint Multi-Functional Strike Battalion > Drones | `[1, 6, 1, 0]` | How many drones each objective-derived zone tries to hold up. The airframe itself is always the commander's own faction UAV. |

## Voice (`voice`)

| Setting | Type | Category | Default | What it does |
|---|---|---|---|---|
| Grace time (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - Mesh | `[0, 10, DEFAULT_GRACE_S, 1]` | How long a speaker whose route drops is still heard at his last quality before he is muted. |
| Ring time (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - Calls | `[5, 60, DEFAULT_RING_S, 0]` | How long a call rings before it counts as no answer (and a callback is offered). |
| Call drop time (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - Calls | `[1, 60, DEFAULT_CALL_DROP_S, 0]` | How long a call member can be without reach on DATA to every other member before he is dropped from the call. |
| FLASH bump warning (sec) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - Calls | `[1, 15, DEFAULT_BUMP_WARN_S, 0]` | How long the priority warning plays on a ROUTINE call before a FLASH call takes its slot. |
| Callback expiry (min) | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - Calls | `[1, 60, DEFAULT_CB_EXPIRE_MIN, 0]` | How long the server holds a callback request before it is dropped. |
| Callbacks per player | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - Calls | `[1, 10, DEFAULT_CB_PER_PLAYER, 0]` | Most pending callback requests one player can be part of at once. |
| Radio beeps | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Voice - Sounds | `true` | TX chirp, roger beep, squelch, cut, net switch and blocked tones. |
| Call beeps | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Voice - Sounds | `true` | Dial, ringback, ring, busy, connect, hang-up, join and priority warning tones. |
| Beep volume | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - Sounds | `[0, MAX_BEEP_VOLUME, DEFAULT_BEEP_VOLUME` | Volume of every radio and call tone, and of the static. |
| Pitch per net | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Voice - Sounds | `true` | C2 low, TEAM mid, A2G high, CALL two-tone, so the net is known before the voice starts. |
| Static by quality | CHECKBOX | 1st Joint Multi-Functional Strike Battalion > Voice - Sounds | `true` | Static under a radio speaker, louder as his link quality falls. |
| RTO nets at once | SLIDER | 1st Joint Multi-Functional Strike Battalion > Voice - Calls | `[0, CUSTOM_NETS_MAX_CAP, DEFAULT_CUSTOM_` | How many nets RTOs may have made at one time. Each takes one of the game's ten custom voice channels for the rest of the mission - C2 and A2G hold two |

## Forced by `cba_settings`

`addons/cba_settings/cba_settings.sqf` force-sets 725 values at mission start.
A forced setting cannot be changed in-game, and overrides the defaults above.

| Variable | Value |
|---|---|
| `jmfsbfa_mediumcaliber_cuasCeiling` | `1.4` |
| `jmfsbfa_mediumcaliber_enableAirburst` | `true` |
| `jmfsbfa_mediumcaliber_factionScaling` | `true` |
| `jmfsbfa_mediumcaliber_greenFraction` | `0.85` |
| `jmfsbfa_mediumcaliber_redFraction` | `0.75` |
| `UM_autoTriage_mode` | `2` |
| `UM_medNotif_clearActionEnabled` | `true` |
| `UM_unconIcon_enabled` | `true` |
| `UM_unconIcon_maxRange` | `100` |
| `UM_unconIcon_medicOnly` | `true` |
| `UM_unconIcon_minRange` | `4` |
| `UM_unconSpectator` | `false` |
| `UM_unconSpectator_arrestOnly` | `false` |
| `UM_unconSpectator_cameraModes` | `1` |
| `UM_unconVoice_arrestMute` | `true` |
| `UM_unconVoice_mode` | `0` |
| `UM_unconZeusExempt` | `true` |
| `ace_advanced_ballistics_ammoTemperatureEnabled` | `true` |
| `ace_advanced_ballistics_barrelLengthInfluenceEnabled` | `true` |
| `ace_advanced_ballistics_bulletTraceEnabled` | `true` |
| `ace_advanced_ballistics_enabled` | `true` |
| `ace_advanced_ballistics_muzzleVelocityVariationEnabled` | `true` |
| `ace_advanced_ballistics_simulationInterval` | `0.05` |
| `ace_advanced_fatigue_enabled` | `true` |
| `ace_advanced_fatigue_enableStaminaBar` | `false` |
| `ace_advanced_fatigue_loadFactor` | `0.5` |
| `ace_advanced_fatigue_performanceFactor` | `4` |
| `ace_advanced_fatigue_recoveryFactor` | `4` |
| `ace_advanced_fatigue_terrainGradientFactor` | `0.5` |
| `ace_missileguidance_chaffEffectivenessCoef` | `1` |
| `ace_missileguidance_flareAngleCoef` | `1` |
| `ace_missileguidance_flareEffectivenessCoef` | `1` |
| `ace_advanced_throwing_enabled` | `true` |
| `ace_advanced_throwing_enablePickUp` | `true` |
| `ace_advanced_throwing_enablePickUpAttached` | `true` |
| `ace_advanced_throwing_showMouseControls` | `true` |
| `ace_vehicle_damage_enableCarDamage` | `true` |
| `ace_vehicle_damage_enabled` | `true` |
| `ace_ai_assignNVG` | `true` |
| `ace_arsenal_allowDefaultLoadouts` | `true` |
| `ace_arsenal_allowSharedLoadouts` | `true` |
| `ace_arsenal_enableIdentityTabs` | `false` |
| `ace_arsenal_enableModIcons` | `1` |
| `ace_artillerytables_advancedCorrections` | `true` |
| `ace_artillerytables_disableArtilleryComputer` | `true` |
| `ace_mk6mortar_airResistanceEnabled` | `true` |
| `ace_mk6mortar_allowCompass` | `true` |
| `ace_mk6mortar_allowComputerRangefinder` | `true` |
| `ace_mk6mortar_useAmmoHandling` | `true` |
| `ace_captives_allowHandcuffOwnSide` | `true` |
| `ace_captives_allowSurrender` | `true` |
| `ace_captives_requireSurrender` | `2` |
| `ace_captives_requireSurrenderAi` | `false` |
| `ace_common_allowFadeMusic` | `true` |
| `ace_common_checkExtensions` | `false` |
| `ace_common_checkPBOsAction` | `2` |
| `ace_common_checkPBOsCheckAll` | `false` |
| `ace_common_checkPBOsWhitelist` | `"[]"` |
| `ace_common_deployedSwayFactor` | `0.25` |
| `ace_common_enableSway` | `true` |
| `ace_common_magneticDeclination` | `false` |
| `ace_common_restedSwayFactor` | `0.5` |
| `ace_common_swayFactor` | `0.4` |
| `ace_cookoff_ammoCookoffDuration` | `0.5` |
| `ace_cookoff_cookoffDuration` | `1` |
| `ace_cookoff_cookoffEnableProjectiles` | `true` |
| `ace_cookoff_cookoffEnableSound` | `true` |
| `ace_cookoff_destroyVehicleAfterCookoff` | `true` |
| `ace_cookoff_enableAmmobox` | `true` |
| `ace_cookoff_enableAmmoCookoff` | `true` |
| `ace_cookoff_enableFire` | `true` |
| `ace_cookoff_probabilityCoef` | `3` |
| `ace_cookoff_removeAmmoDuringCookoff` | `true` |
| `ace_csw_ammoHandling` | `2` |
| `ace_csw_defaultAssemblyMode` | `true` |
| `ace_csw_dragAfterDeploy` | `true` |
| `ace_csw_handleExtraMagazines` | `true` |
| `ace_csw_handleExtraMagazinesType` | `0` |
| `ace_csw_progressBarTimeCoefficent` | `1` |
| `ace_dragging_allowRunWithLightweight` | `true` |
| `ace_dragging_dragAndFire` | `true` |
| `ace_dragging_skipContainerWeight` | `false` |
| `ace_dragging_weightCoefficient` | `1` |
| `ace_explosives_customTimerDefault` | `30` |
| `ace_explosives_customTimerMax` | `900` |
| `ace_explosives_customTimerMin` | `5` |
| `ace_explosives_explodeOnDefuse` | `true` |
| `ace_explosives_punishNonSpecialists` | `true` |
| `ace_explosives_requireSpecialist` | `true` |
| `acex_field_rations_enabled` | `false` |
| `ace_fire_dropWeapon` | `2` |
| `ace_fire_enabled` | `true` |
| `ace_fire_enableFlare` | `true` |
| `ace_fortify_markObjectsOnMap` | `1` |
| `ace_fortify_timeCostCoefficient` | `1` |
| `ace_fortify_timeMin` | `1.5` |
| `acex_fortify_settingHint` | `1` |
| `ace_frag_enabled` | `true` |
| `ace_frag_reflectionsEnabled` | `false` |
| `ace_frag_spallEnabled` | `true` |
| `ace_frag_spallIntensity` | `1` |
| `ace_gforces_coef` | `1` |
| `ace_gforces_enabledFor` | `2` |
| `ace_goggles_effects` | `2` |
| `ace_goggles_showClearGlasses` | `true` |
| `ace_grenades_convertExplosives` | `true` |
| `ace_hearing_autoAddEarplugsToUnits` | `1` |
| `ace_hearing_enableCombatDeafness` | `true` |
| `ace_hearing_enabledForZeusUnits` | `true` |
| `ace_interaction_disableNegativeRating` | `true` |
| `ace_interaction_enableAnimActions` | `true` |
| `ace_interaction_enableGroupRenaming` | `true` |
| `ace_interaction_enableMagazinePassing` | `true` |
| `ace_interaction_enableTeamManagement` | `true` |
| `ace_interaction_enableWeaponAttachments` | `true` |
| `ace_interaction_interactWithEnemyCrew` | `0` |
| `ace_interaction_interactWithTerrainObjects` | `true` |
| `ace_interaction_remoteTeamManagement` | `true` |
| `ace_killtracker_showCrewKills` | `true` |
| `ace_killtracker_showMedicalWounds` | `2` |
| `ace_killtracker_trackAI` | `true` |
| `ace_cargo_carryAfterUnload` | `true` |
| `ace_cargo_enable` | `true` |
| `ace_cargo_enableDeploy` | `true` |
| `ace_cargo_enableRename` | `true` |
| `ace_cargo_loadTimeCoefficient` | `5` |
| `ace_cargo_paradropTimeCoefficent` | `2.5` |
| `ace_cargo_unloadOnKilled` | `0.5` |
| `ace_rearm_distance` | `20` |
| `ace_rearm_enabled` | `true` |
| `ace_rearm_level` | `0` |
| `ace_rearm_supply` | `0` |
| `ace_refuel_cargoRate` | `10` |
| `ace_refuel_enabled` | `true` |
| `ace_refuel_hoseLength` | `20` |
| `ace_refuel_progressDuration` | `2` |
| `ace_refuel_rate` | `0.9` |
| `ace_towing_addRopeToVehicleInventory` | `true` |
| `ace_magazinerepack_repackAnimation` | `true` |
| `ace_magazinerepack_repackLoadedMagazines` | `true` |
| `ace_magazinerepack_timePerAmmo` | `1.5` |
| `ace_magazinerepack_timePerBeltLink` | `8` |
| `ace_magazinerepack_timePerMagazine` | `2` |
| `ace_map_BFT_Enabled` | `false` |
| `ace_map_BFT_HideAiGroups` | `false` |
| `ace_map_BFT_Interval` | `1` |
| `ace_map_BFT_ShowPlayerNames` | `false` |
| `ace_map_DefaultChannel` | `1` |
| `ace_map_mapGlow` | `true` |
| `ace_map_mapIllumination` | `true` |
| `ace_map_mapLimitZoom` | `false` |
| `ace_map_mapShake` | `true` |
| `ace_map_mapShowCursorCoordinates` | `true` |
| `ace_markers_moveRestriction` | `0` |
| `ace_markers_timestampEnabled` | `true` |
| `ace_markers_timestampFormat` | `"HH:MM"` |
| `ace_markers_timestampHourFormat` | `24` |
| `ace_markers_timestampTimezone` | `0` |
| `ace_markers_TimestampUTCMinutesOffset` | `0` |
| `ace_markers_timestampUTCOffset` | `0` |
| `ace_map_gestures_allowCurator` | `true` |
| `ace_map_gestures_allowSpectator` | `true` |
| `ace_map_gestures_briefingMode` | `0` |
| `ace_map_gestures_enabled` | `true` |
| `ace_map_gestures_interval` | `0.03` |
| `ace_map_gestures_maxRange` | `7` |
| `ace_map_gestures_maxRangeCamera` | `14` |
| `ace_map_gestures_onlyShowFriendlys` | `false` |
| `ace_maptools_drawStraightLines` | `true` |
| `ace_maptools_plottingBoardAllowChannelDrawing` | `1` |
| `ace_medical_ai_enabledFor` | `1` |
| `ace_medical_ai_requireItems` | `0` |
| `ace_medical_AIDamageThreshold` | `0.7` |
| `ace_medical_alternateArmorPenetration` | `true` |
| `ace_medical_bleedingCoefficient` | `0.5` |
| `ace_medical_blood_bloodLifetime` | `900` |
| `ace_medical_blood_enabledFor` | `2` |
| `ace_medical_blood_maxBloodObjects` | `50` |
| `ace_medical_deathChance` | `0.2` |
| `ace_medical_dropWeaponUnconsciousChance` | `0` |
| `ace_medical_enableVehicleCrashes` | `true` |
| `ace_medical_fatalDamageSource` | `1` |
| `ace_medical_fractureChance` | `0.5` |
| `ace_medical_fractures` | `1` |
| `ace_medical_ivFlowRate` | `1.5` |
| `ace_medical_limbDamageThreshold` | `5` |
| `ace_medical_limping` | `1` |
| `ace_medical_painCoefficient` | `1` |
| `ace_medical_painUnconsciousChance` | `0.15` |
| `ace_medical_painUnconsciousThreshold` | `0.6` |
| `ace_medical_playerDamageThreshold` | `2.25` |
| `ace_medical_spontaneousWakeUpChance` | `0.8` |
| `ace_medical_spontaneousWakeUpEpinephrineBoost` | `1.4` |
| `ace_medical_statemachine_AIUnconsciousness` | `true` |
| `ace_medical_statemachine_cardiacArrestBleedoutEnabled` | `true` |
| `ace_medical_statemachine_cardiacArrestTime` | `360` |
| `ace_medical_statemachine_fatalInjuriesAI` | `0` |
| `ace_medical_statemachine_fatalInjuriesPlayer` | `2` |
| `ace_medical_useLimbDamage` | `2` |
| `ace_medical_vitals_simulateSpO2` | `false` |
| `ace_medical_windowOnWakeUp` | `1` |
| `ace_medical_treatment_advancedBandages` | `2` |
| `ace_medical_treatment_advancedDiagnose` | `2` |
| `ace_medical_treatment_advancedMedication` | `true` |
| `ace_medical_treatment_allowBodyBagUnconscious` | `false` |
| `ace_medical_treatment_allowGraveDigging` | `0` |
| `ace_medical_treatment_allowLitterCreation` | `true` |
| `ace_medical_treatment_allowSelfIV` | `1` |
| `ace_medical_treatment_allowSelfPAK` | `1` |
| `ace_medical_treatment_allowSelfStitch` | `0` |
| `ace_medical_treatment_allowSharedEquipment` | `0` |
| `ace_medical_treatment_bandageEffectiveness` | `1` |
| `ace_medical_treatment_bandageRollover` | `true` |
| `ace_medical_treatment_clearTrauma` | `1` |
| `ace_medical_treatment_consumePAK` | `1` |
| `ace_medical_treatment_consumeSurgicalKit` | `0` |
| `ace_medical_treatment_convertItems` | `1` |
| `ace_medical_treatment_cprSuccessChanceMax` | `0.6` |
| `ace_medical_treatment_cprSuccessChanceMin` | `0.4` |
| `ace_medical_treatment_graveDiggingMarker` | `true` |
| `ace_medical_treatment_holsterRequired` | `0` |
| `ace_medical_treatment_litterCleanupDelay` | `100` |
| `ace_medical_treatment_locationAdenosine` | `0` |
| `ace_medical_treatment_locationEpinephrine` | `0` |
| `ace_medical_treatment_locationIV` | `0` |
| `ace_medical_treatment_locationMorphine` | `0` |
| `ace_medical_treatment_locationPAK` | `3` |
| `ace_medical_treatment_locationsBoostTraining` | `true` |
| `ace_medical_treatment_locationSplint` | `0` |
| `ace_medical_treatment_locationSurgicalKit` | `0` |
| `ace_medical_treatment_maxLitterObjects` | `50` |
| `ace_medical_treatment_medicAdenosine` | `2` |
| `ace_medical_treatment_medicEpinephrine` | `2` |
| `ace_medical_treatment_medicIV` | `2` |
| `ace_medical_treatment_medicMorphine` | `2` |
| `ace_medical_treatment_medicPAK` | `2` |
| `ace_medical_treatment_medicSplint` | `0` |
| `ace_medical_treatment_medicSurgicalKit` | `2` |
| `ace_medical_treatment_numericalPulse` | `1` |
| `ace_medical_treatment_timeCoefficientPAK` | `0.7` |
| `ace_medical_treatment_treatmentTimeAutoinjector` | `5` |
| `ace_medical_treatment_treatmentTimeBodyBag` | `10` |
| `ace_medical_treatment_treatmentTimeCoeffZeus` | `1` |
| `ace_medical_treatment_treatmentTimeCPR` | `15` |
| `ace_medical_treatment_treatmentTimeGrave` | `10` |
| `ace_medical_treatment_treatmentTimeIV` | `8` |
| `ace_medical_treatment_treatmentTimeSplint` | `7` |
| `ace_medical_treatment_treatmentTimeTourniquet` | `6` |
| `ace_medical_treatment_treatmentTimeTrainedAutoinjector` | `3` |
| `ace_medical_treatment_treatmentTimeTrainedIV` | `6` |
| `ace_medical_treatment_treatmentTimeTrainedSplint` | `5` |
| `ace_medical_treatment_treatmentTimeTrainedTourniquet` | `5` |
| `ace_medical_treatment_woundReopenChance` | `0.4` |
| `ace_medical_treatment_woundStitchTime` | `5` |
| `ace_nametags_ambientBrightnessAffectViewDist` | `1` |
| `ace_nametags_playerNamesMaxAlpha` | `0.8` |
| `ace_nametags_playerNamesViewDistance` | `5` |
| `ace_nametags_showCursorTagForVehicles` | `false` |
| `ace_nightvision_aimDownSightsBlur` | `0` |
| `ace_nightvision_disableNVGsWithSights` | `false` |
| `ace_nightvision_effectScaling` | `0.9` |
| `ace_nightvision_fogScaling` | `0.1` |
| `ace_nightvision_noiseScaling` | `0.1` |
| `ace_nightvision_shutterEffects` | `true` |
| `ace_overheating_cookoffCoef` | `1` |
| `ace_overheating_coolingCoef` | `1` |
| `ace_overheating_displayTextOnJam` | `true` |
| `ace_overheating_enabled` | `true` |
| `ace_overheating_heatCoef` | `0.4` |
| `ace_overheating_jamChanceCoef` | `1` |
| `ace_overheating_overheatingDispersion` | `true` |
| `ace_overheating_overheatingRateOfFire` | `true` |
| `ace_overheating_particleEffectsAndDispersionDistance` | `3000` |
| `ace_overheating_suppressorCoef` | `1` |
| `ace_overheating_unJamFailChance` | `0.1` |
| `ace_overheating_unJamOnreload` | `true` |
| `ace_overheating_unJamOnSwapBarrel` | `true` |
| `ace_finger_enabled` | `true` |
| `ace_finger_maxRange` | `4` |
| `ace_finger_proximityScaling` | `true` |
| `ace_finger_sizeCoef` | `1` |
| `ace_pylons_enabledForZeus` | `true` |
| `ace_pylons_enabledFromAmmoTrucks` | `true` |
| `ace_pylons_rearmNewPylons` | `true` |
| `ace_pylons_requireEngineer` | `false` |
| `ace_pylons_requireToolkit` | `false` |
| `ace_pylons_searchDistance` | `45` |
| `ace_pylons_timePerPylon` | `5` |
| `ace_quickmount_distance` | `3` |
| `ace_quickmount_enabled` | `true` |
| `ace_quickmount_enableMenu` | `3` |
| `ace_quickmount_speed` | `18` |
| `ace_repair_addSpareParts` | `true` |
| `ace_repair_autoShutOffEngineWhenStartingRepair` | `true` |
| `ace_repair_consumeItem_toolKit` | `0` |
| `ace_repair_displayTextOnRepair` | `true` |
| `ace_repair_enabled` | `true` |
| `ace_repair_engineerSetting_fullRepair` | `2` |
| `ace_repair_engineerSetting_repair` | `1` |
| `ace_repair_engineerSetting_wheel` | `0` |
| `ace_repair_fullRepairLocation` | `2` |
| `ace_repair_fullRepairRequiredItems` | `["ace_repair_anyToolKit"]` |
| `ace_repair_locationsBoostTraining` | `true` |
| `ace_repair_miscRepairRequiredItems` | `["ace_repair_anyToolKit"]` |
| `ace_repair_miscRepairTime` | `15` |
| `ace_repair_patchWheelEnabled` | `0` |
| `ace_repair_patchWheelLocation` | `["ground","vehicle"]` |
| `ace_repair_patchWheelMaximumRepair` | `0.3` |
| `ace_repair_patchWheelRequiredItems` | `["ace_repair_anyToolKit"]` |
| `ace_repair_patchWheelTime` | `5` |
| `ace_repair_repairDamageThreshold` | `0.6` |
| `ace_repair_repairDamageThreshold_engineer` | `0.4` |
| `ace_repair_timeCoefficientFullRepair` | `1.5` |
| `ace_repair_wheelChangeTime` | `10` |
| `ace_repair_wheelRepairRequiredItems` | `[]` |
| `ace_respawn_removeDeadBodiesDisconnected` | `false` |
| `ace_respawn_savePreDeathGear` | `true` |
| `ace_scopes_correctZeroing` | `true` |
| `ace_scopes_deduceBarometricPressureFromTerrainAltitude` | `true` |
| `ace_scopes_defaultZeroRange` | `100` |
| `ace_scopes_enabled` | `true` |
| `ace_scopes_forceUseOfAdjustmentTurrets` | `true` |
| `ace_scopes_overwriteZeroRange` | `true` |
| `ace_scopes_simplifiedZeroing` | `false` |
| `ace_scopes_zeroReferenceBarometricPressure` | `1013.25` |
| `ace_scopes_zeroReferenceHumidity` | `0` |
| `ace_scopes_zeroReferenceTemperature` | `15` |
| `acex_sitting_enable` | `true` |
| `ace_spectator_enableAI` | `false` |
| `ace_spectator_maxFollowDistance` | `5` |
| `ace_spectator_restrictModes` | `0` |
| `ace_spectator_restrictVisions` | `0` |
| `ace_switchunits_enableSafeZone` | `true` |
| `ace_switchunits_enableSwitchUnits` | `false` |
| `ace_switchunits_safeZoneRadius` | `100` |
| `ace_switchunits_switchToCivilian` | `false` |
| `ace_switchunits_switchToEast` | `false` |
| `ace_switchunits_switchToIndependent` | `false` |
| `ace_switchunits_switchToWest` | `false` |
| `ace_trenches_bigEnvelopeDigDuration` | `25` |
| `ace_trenches_bigEnvelopeRemoveDuration` | `15` |
| `ace_trenches_smallEnvelopeDigDuration` | `20` |
| `ace_trenches_smallEnvelopeRemoveDuration` | `12` |
| `ace_fastroping_autoAddFRIES` | `false` |
| `ace_fastroping_requireRopeItems` | `true` |
| `ace_flags_enableCarrying` | `true` |
| `ace_flags_enablePlacing` | `true` |
| `ace_gunbag_swapGunbagEnabled` | `true` |
| `ace_hitreactions_minDamageToTrigger` | `0.1` |
| `ace_hitreactions_weaponDropChanceArmHitAI` | `0.15` |
| `ace_hitreactions_weaponDropChanceArmHitPlayer` | `0.1` |
| `ace_laser_dispersionCount` | `2` |
| `ace_laser_showLaserOnMap` | `1` |
| `ace_marker_flags_placeAnywhere` | `false` |
| `ace_microdagr_mapDataAvailable` | `2` |
| `ace_microdagr_waypointPrecision` | `3` |
| `ace_noradio_enabled` | `true` |
| `ace_optionsmenu_showNewsOnMainMenu` | `false` |
| `ace_overpressure_backblastDistanceCoefficient` | `1` |
| `ace_overpressure_overpressureDistanceCoefficient` | `1` |
| `ace_parachute_failureChance` | `0.15` |
| `ace_parachute_hideAltimeter` | `true` |
| `ace_tagging_quickTag` | `1` |
| `ace_vehiclelock_defaultLockpickStrength` | `20` |
| `ace_vehiclelock_lockVehicleInventory` | `true` |
| `ace_vehiclelock_vehicleStartingLockState` | `-1` |
| `ace_novehicleclanlogo_enabled` | `true` |
| `ace_vehicles_keepEngineRunning` | `false` |
| `ace_vehicles_speedLimiterStep` | `5` |
| `ace_viewports_enabled` | `true` |
| `ace_viewdistance_enabled` | `false` |
| `ace_viewdistance_limitViewDistance` | `10000` |
| `ace_viewdistance_objectViewDistanceCoeff` | `0` |
| `ace_viewdistance_viewDistanceAirVehicle` | `0` |
| `ace_viewdistance_viewDistanceLandVehicle` | `0` |
| `ace_viewdistance_viewDistanceOnFoot` | `0` |
| `acex_viewrestriction_mode` | `3` |
| `acex_viewrestriction_modeSelectiveAir` | `0` |
| `acex_viewrestriction_modeSelectiveFoot` | `0` |
| `acex_viewrestriction_modeSelectiveLand` | `0` |
| `acex_viewrestriction_modeSelectiveSea` | `0` |
| `acex_viewrestriction_preserveView` | `true` |
| `ace_weather_enabled` | `true` |
| `ace_weather_showCheckAirTemperature` | `true` |
| `ace_weather_updateInterval` | `60` |
| `ace_weather_windSimulation` | `true` |
| `ace_winddeflection_enabled` | `true` |
| `ace_winddeflection_simulationInterval` | `0.05` |
| `ace_winddeflection_vehicleEnabled` | `true` |
| `ace_zeus_autoAddObjects` | `false` |
| `ace_zeus_canCreateZeus` | `0` |
| `ace_zeus_radioOrdnance` | `false` |
| `ace_zeus_remoteWind` | `false` |
| `ace_zeus_revealMines` | `0` |
| `ace_zeus_zeusAscension` | `true` |
| `ace_zeus_zeusBird` | `false` |
| `acre_sys_core_fullDuplex` | `true` |
| `acre_sys_core_ts3ChannelName` | `"acre"` |
| `acre_sys_core_ts3ChannelPassword` | `"1234"` |
| `acre_sys_radio_defaultRadio` | `""` |
| `acre_sys_signal_signalModel` | `3` |
| `GW_setting_noModuleBehavior` | `"default"` |
| `AHDNC_main_enabled_VTOL` | `true` |
| `cba_diagnostic_watchInfoRefreshRate` | `0.2` |
| `cba_disposable_dropUsedLauncher` | `2` |
| `cba_disposable_replaceDisposableLauncher` | `false` |
| `cba_network_loadoutValidation` | `1` |
| `cba_optics_usePipOptics` | `false` |
| `DT_terrainGridMax` | `50` |
| `DT_viewDistanceMax` | `12000` |
| `emr_main_allowClimbOnStandingUnits` | `false` |
| `emr_main_allowMidairClimbing` | `true` |
| `emr_main_animSpeedCoef` | `1` |
| `emr_main_animSpeedStaminaCoef` | `0.4` |
| `emr_main_assistDuty` | `1.5` |
| `emr_main_assistHeight` | `1` |
| `emr_main_blacklistStr` | `""` |
| `emr_main_climbingEnabled` | `true` |
| `emr_main_climbOnDuty` | `3.4` |
| `emr_main_climbOverDuty` | `3` |
| `emr_main_dropDuty` | `0.7` |
| `emr_main_enableWeightCheck` | `false` |
| `emr_main_jumpDuty` | `1` |
| `emr_main_jumpForwardVelocity` | `1.2` |
| `emr_main_jumpingEnabled` | `true` |
| `emr_main_jumpingLoadCoefficient` | `1` |
| `emr_main_jumpVelocity` | `3.5` |
| `emr_main_maxClimbHeight` | `2.6` |
| `emr_main_maxDropHeight` | `6` |
| `emr_main_maxWeightClimb1` | `100` |
| `emr_main_maxWeightClimb2` | `85` |
| `emr_main_maxWeightClimb3` | `60` |
| `emr_main_maxWeightJump` | `100` |
| `emr_main_minClimbTerrain` | `0.3` |
| `emr_main_staminaCoefficient` | `1` |
| `emr_main_whitelistStr` | `""` |
| `emr_main_yeetCoefficient` | `1.4` |
| `vnd_allowBotsShoot` | `true` |
| `vnd_fiberTTL` | `60` |
| `FPV_isUavCaptive` | `true` |
| `FPV_MaxFlightDistance` | `4000` |
| `jmfsb_ai_disembark_enabled` | `true` |
| `jmfsb_ai_disembark_stayInImmobileChance` | `0.2927` |
| `jmfsb_back_to_game_enableAddon` | `true` |
| `jmfsb_back_to_game_removeBody` | `true` |
| `jmfsb_back_to_game_teleportToLeader` | `true` |
| `jmfsb_back_to_game_teleportToVehicle` | `true` |
| `jmfsb_boc_disabled` | `false` |
| `jmfsb_bft_adminGodView` | `false` |
| `jmfsb_bft_autoEnable` | `2` |
| `jmfsb_bft_colorsBlacklist` | `"Default, ColorWEST, ColorEAST, ColorGUER, ColorCIV, Color1_` |
| `jmfsb_bft_enabled` | `true` |
| `jmfsb_bft_fuzzOtherSides` | `false` |
| `jmfsb_bft_iconsBlacklist` | `"unknown, uav"` |
| `jmfsb_bft_mapSettings` | `true` |
| `jmfsb_bft_markerShape` | `"a"` |
| `jmfsb_bft_nameOptions` | `"Zulu,Lima,Uniform,Echo,Whiskey,Tango"` |
| `jmfsb_bft_preferredColors` | `"ColorBLUFOR, ColorOPFOR, ColorIndependent, ColorCivilian, C` |
| `jmfsb_bft_preferredIcons` | `"inf, motor_inf, mech_inf, air, armor, recon"` |
| `jmfsb_bft_trackingMode` | `"weightedAverage"` |
| `jmfsb_bft_trailingCount` | `5` |
| `jmfsb_bft_trailingMode` | `"weightedAverage"` |
| `jmfsb_bft_trailingWeight` | `0.75` |
| `jmfsb_bft_updateDelay` | `5` |
| `jmfsb_boc_walk` | `true` |
| `jmfsb_chat_allowGlobalChat` | `true` |
| `jmfsb_evac_enabled` | `false` |
| `jmfsb_evac_medicOnly` | `true` |
| `jmfsb_evac_time` | `10` |
| `jmfsb_fatigue_highJogCoef` | `0.8` |
| `jmfsb_fatigue_highJogCoefEnabled` | `true` |
| `jmfsb_friendly_fire_loggingEnabled` | `true` |
| `jmfsb_grass_enabled` | `true` |
| `jmfsb_hacking_enabled` | `true` |
| `jmfsb_hacking_requireISR` | `true` |
| `jmfsb_hacking_towerClasses` | `"Land_TTowerBig_2_F,Land_TTowerBig_1_F,Land_Communication_F,` |
| `jmfsb_insurgents_enabled_CUP` | `false` |
| `jmfsb_insurgents_enabled_Vanilla` | `true` |
| `jmfsb_medical_treatment_fatalInjuriesCardiacArrestTimeCoefficient` | `0.2` |
| `jmfsb_pointing_vehicleEnabled` | `true` |
| `jmfsb_remotesensors_enabled` | `true` |
| `jmfsb_respawn_enabled` | `true` |
| `jmfsb_respawn_time` | `6` |
| `jmfsb_spectator_allowAI` | `false` |
| `jmfsb_spectator_allowAIUnconscious` | `false` |
| `jmfsb_spectator_allowUnconscious` | `true` |
| `jmfsb_spectator_civilianSide` | `false` |
| `jmfsb_spectator_civilianSideUnconscious` | `false` |
| `jmfsb_spectator_enabled` | `false` |
| `jmfsb_spectator_freeCamera` | `false` |
| `jmfsb_spectator_freeCameraUnconscious` | `false` |
| `jmfsb_spectator_sides` | `0` |
| `jmfsb_spectator_sidesUnconscious` | `0` |
| `jmfsb_spectator_TPPCamera` | `false` |
| `jmfsb_spectator_TPPCameraUnconscious` | `false` |
| `jmfsb_spectator_unconsciousDelay` | `30` |
| `jmfsb_suppress_checkLOS` | `true` |
| `jmfsb_suppress_overlayFadeoutTime` | `10` |
| `jmfsb_suppress_overlayOpacity` | `0.96` |
| `jmfsb_suppress_overlayTexture` | `1` |
| `jmfsb_suppress_projectileMaxDistance` | `9` |
| `jmfsb_suppress_shooterMinDistance` | `0` |
| `jmfsb_tagging_enabled` | `true` |
| `jmfsb_towing_addToCars` | `true` |
| `jmfsb_towing_addToHeavyDutyVehicles` | `true` |
| `Rev_tp_action_radius` | `5` |
| `Rev_tp_action_time` | `6` |
| `jmfsb_Settings_addEarplugs` | `true` |
| `jmfsb_Settings_allowInsigniaApplication` | `true` |
| `jmfsb_Settings_enableRadios` | `true` |
| `jmfsb_Settings_enableStagingSystem` | `true` |
| `jmfsb_Settings_enableVehicleInventory` | `true` |
| `jmfsb_Settings_enableVehiclePylon` | `true` |
| `jmfsb_Settings_enableVehicleRadios` | `false` |
| `jmfsb_Settings_enableVehicleSystem` | `true` |
| `jmfsb_Settings_jumpSimulation` | `2` |
| `jmfsb_Settings_jumpSimulationGlasses` | `true` |
| `jmfsb_Settings_jumpSimulationHat` | `true` |
| `jmfsb_Settings_jumpSimulationNVG` | `true` |
| `jmfsb_patrol_base_enabled` | `true` |
| `jmfsb_patrol_base_kitCount` | `4` |
| `jmfsb_patrol_base_kitRange` | `5` |
| `jmfsb_patrol_base_maxCount` | `3` |
| `jmfsb_Settings_setAiSystemDifficulty` | `0` |
| `jmfsb_Settings_setMissionType` | `1` |
| `jmfsb_Settings_setPlayerRank` | `true` |
| `jmfsb_Settings_setRadio` | `true` |
| `jmfsb_Settings_showDiaryRecords` | `true` |
| `jmfsb_Settings_vehicleFactions` | `"[""BLU_W_F"",""BLU_T_F"",""BLU_NATO_lxWS"",""BLU_F"",""USAF` |
| `jmfsbfa_ammo_debugBreaching` | `false` |
| `jmfsbfa_ammo_enableBreaching` | `true` |
| `jmfsbfa_antidrone_damageMultiplier` | `1` |
| `jmfsbfa_antidrone_lethalRadiusMultiplier` | `1` |
| `jmfsbfa_antidrone_triggerRadiusMultiplier` | `1` |
| `jmfsb_nvg_ACE` | `false` |
| `jmfsb_nvg_Blacklist` | `""` |
| `jmfsb_nvg_Effect` | `""` |
| `grad_trenches_functions_allowBigEnvelope` | `true` |
| `grad_trenches_functions_allowCamouflage` | `true` |
| `grad_trenches_functions_allowDigging` | `true` |
| `grad_trenches_functions_allowEffects` | `true` |
| `grad_trenches_functions_allowGiantEnvelope` | `true` |
| `grad_trenches_functions_allowHitDecay` | `true` |
| `grad_trenches_functions_allowLongEnvelope` | `true` |
| `grad_trenches_functions_allowShortEnvelope` | `true` |
| `grad_trenches_functions_allowSmallEnvelope` | `true` |
| `grad_trenches_functions_allowTextureLock` | `true` |
| `grad_trenches_functions_allowTrenchDecay` | `false` |
| `grad_trenches_functions_allowVehicleEnvelope` | `true` |
| `grad_trenches_functions_bigEnvelopeDamageMultiplier` | `2` |
| `grad_trenches_functions_bigEnvelopeDigTime` | `40` |
| `grad_trenches_functions_bigEnvelopeRemovalTime` | `-1` |
| `grad_trenches_functions_buildFatigueFactor` | `1` |
| `grad_trenches_functions_camouflageRequireEntrenchmentTool` | `true` |
| `grad_trenches_functions_createTrenchMarker` | `false` |
| `grad_trenches_functions_decayTime` | `1800` |
| `grad_trenches_functions_giantEnvelopeDamageMultiplier` | `1` |
| `grad_trenches_functions_giantEnvelopeDigTime` | `90` |
| `grad_trenches_functions_giantEnvelopeRemovalTime` | `-1` |
| `grad_trenches_functions_hitDecayMultiplier` | `1` |
| `grad_trenches_functions_LongEnvelopeDigTime` | `100` |
| `grad_trenches_functions_LongEnvelopeRemovalTime` | `-1` |
| `grad_trenches_functions_playersInAreaRadius` | `0` |
| `grad_trenches_functions_shortEnvelopeDamageMultiplier` | `2` |
| `grad_trenches_functions_shortEnvelopeDigTime` | `15` |
| `grad_trenches_functions_shortEnvelopeRemovalTime` | `-1` |
| `grad_trenches_functions_smallEnvelopeDamageMultiplier` | `3` |
| `grad_trenches_functions_smallEnvelopeDigTime` | `30` |
| `grad_trenches_functions_smallEnvelopeRemovalTime` | `-1` |
| `grad_trenches_functions_stopBuildingAtFatigueMax` | `true` |
| `grad_trenches_functions_textureLockDistance` | `5` |
| `grad_trenches_functions_timeoutToDecay` | `7200` |
| `grad_trenches_functions_vehicleEnvelopeDamageMultiplier` | `1` |
| `grad_trenches_functions_vehicleEnvelopeDigTime` | `120` |
| `grad_trenches_functions_vehicleEnvelopeRemovalTime` | `-1` |
| `grad_trenches_functions_vehicleTrenchBuildSpeed` | `5` |
| `GX_DRONES_AUTOCONNECT` | `true` |
| `GX_DRONES_COMMAND_INTERACTION_ENABLE` | `false` |
| `GX_DRONES_COMMAND_NON_CONNECTED_ENABLE` | `true` |
| `GX_DRONES_TIME_TO_DEPLOY` | `3` |
| `GX_DRONES_TIME_TO_PICKUP` | `3` |
| `GX_DRONES_TIME_TO_REARM` | `2` |
| `GX_DRONES_TIME_TO_RECHARGE` | `2` |
| `KJW_TwoPrimaryWeapons_blacklistedClasses` | `"[]"` |
| `KJW_TwoPrimaryWeapons_Enabled` | `true` |
| `KJW_TwoPrimaryWeapons_Launchers` | `true` |
| `KJW_TwoPrimaryWeapons_whitelistedClasses` | `"[]"` |
| `Fat_Lurch_Grid` | `true` |
| `Fat_Lurch_GridNum` | `10` |
| `Fat_Lurch_MapSlew` | `true` |
| `Fat_Lurch_Markers` | `true` |
| `Fat_Lurch_Measure` | `true` |
| `Fat_Lurch_ShowAz` | `true` |
| `Fat_Lurch_ShowEl` | `true` |
| `Fat_Lurch_ShowNorth` | `true` |
| `Fat_Lurch_ShowTarget` | `true` |
| `zen_area_markers_editableMarkers` | `0` |
| `zen_building_markers_enabled` | `true` |
| `zen_common_ascensionMessages` | `true` |
| `zen_common_autoAddObjects` | `false` |
| `zen_common_disableGearAnim` | `false` |
| `zen_compat_ace_hideModules` | `true` |
| `lambs_danger_cqbRange` | `100.128` |
| `lambs_danger_panicChance` | `0` |
| `lambs_eventhandlers_ExplosionEventHandlerEnabled` | `true` |
| `lambs_eventhandlers_ExplosionReactionTime` | `16` |
| `lambs_wp_autoAddArtillery` | `true` |
| `lambs_main_combatShareRange` | `750.692` |
| `lambs_main_maxRevealValue` | `1` |
| `lambs_main_minFriendlySuppressionDistance` | `0` |
| `lambs_main_minObstacleProximity` | `5` |
| `lambs_main_minSuppressionRange` | `50` |
| `lambs_main_radioBackpack` | `3600` |
| `lambs_main_radioDisabled` | `false` |
| `lambs_main_radioEast` | `1200` |
| `lambs_main_radioGuer` | `1200` |
| `lambs_main_radioShout` | `100` |
| `lambs_main_radioWest` | `1200` |
| `ace_medical_gui_bodyPartOutlineColor` | `[1,1,1,1]` |
| `ace_medical_gui_enableActions` | `0` |
| `ace_medical_gui_enableMedicalMenu` | `1` |
| `ace_medical_gui_enableSelfActions` | `true` |
| `ace_medical_gui_interactionMenuShowTriage` | `1` |
| `ace_medical_gui_maxDistance` | `3` |
| `ace_medical_gui_openAfterTreatment` | `true` |
| `ace_medical_gui_peekMedicalInfoReleaseDelay` | `1` |
| `ace_medical_gui_peekMedicalOnHit` | `false` |
| `ace_medical_gui_peekMedicalOnHitDuration` | `1` |
| `ace_medical_gui_showBleeding` | `2` |
| `ace_medical_gui_showBloodlossEntry` | `true` |
| `ace_medical_gui_showDamageEntry` | `false` |
| `ace_medical_gui_tourniquetWarning` | `false` |
| `ACM_airway_airwayCollapseChance` | `1` |
| `ACM_airway_airwayObstructionBloodChance` | `1` |
| `ACM_airway_airwayObstructionVomitChance` | `1` |
| `ACM_airway_enable` | `true` |
| `ACM_airway_treatmentTimeNPA` | `5` |
| `ACM_airway_treatmentTimeOPA` | `3` |
| `ACM_airway_treatmentTimeRecoveryPosition` | `8` |
| `ACM_airway_treatmentTimeSGA` | `7` |
| `ACM_breathing_altitudeAffectOxygen` | `false` |
| `ACM_breathing_chestInjuryChance` | `1` |
| `ACM_breathing_Hardcore_ChestInjury` | `false` |
| `ACM_breathing_Hardcore_HemothoraxBleeding` | `false` |
| `ACM_breathing_hemothoraxChance` | `0.1` |
| `ACM_breathing_locationThoracostomy` | `0` |
| `ACM_breathing_pneumothoraxDeteriorateChance` | `0.5` |
| `ACM_breathing_pneumothoraxEnabled` | `true` |
| `ACM_breathing_showCyanosisSeverity` | `true` |
| `ACM_breathing_treatmentTimeInspectChest` | `6` |
| `ACM_cbrn_chemicalAffectAI` | `true` |
| `ACM_cbrn_chemicalAffectAISkill` | `true` |
| `ACM_cbrn_chlorineCauseBlindness` | `true` |
| `ACM_cbrn_CSCauseBlindness` | `true` |
| `ACM_cbrn_customPPEList_gasmask` | `"JCA_G_AirPurifyingRespirator_03_black_clear_F, JCA_G_AirPur` |
| `ACM_cbrn_customPPEList_suit` | `"lxim_rhs_moppsuit"` |
| `ACM_cbrn_customVehicleList_CBRN` | `"RHS_M2A3_BUSKIII, RHS_M6, rhsusf_m1240a1_m2crows_usarmy_d, ` |
| `ACM_cbrn_customVehicleList_sealed` | `""` |
| `ACM_cbrn_enable` | `true` |
| `ACM_cbrn_lewisiteCauseBlindness` | `true` |
| `ACM_cbrn_lewisiteIsColorless` | `true` |
| `ACM_cbrn_sarinIsColorless` | `true` |
| `ACM_circulation_AEDDistanceLimit` | `5` |
| `ACM_circulation_BloodType_Ratio_A` | `28` |
| `ACM_circulation_BloodType_Ratio_AB` | `4` |
| `ACM_circulation_BloodType_Ratio_ABN` | `1` |
| `ACM_circulation_BloodType_Ratio_AN` | `3` |
| `ACM_circulation_BloodType_Ratio_B` | `18` |
| `ACM_circulation_BloodType_Ratio_BN` | `2` |
| `ACM_circulation_BloodType_Ratio_O` | `39` |
| `ACM_circulation_BloodType_Ratio_ON` | `5` |
| `ACM_circulation_cardiacArrestBleedRate` | `0.05` |
| `ACM_circulation_cardiacArrestChance` | `0.3` |
| `ACM_circulation_cardiacArrestDeteriorationRate` | `1` |
| `ACM_circulation_coagulationClotting` | `true` |
| `ACM_circulation_coagulationClottingAffectAI` | `true` |
| `ACM_circulation_CPREffectiveness` | `1` |
| `ACM_circulation_customBloodTypeList_enable` | `false` |
| `ACM_circulation_Hardcore_PostCardiacArrest` | `false` |
| `ACM_circulation_IVComplications` | `true` |
| `ACM_circulation_IVComplicationsDeteriorate` | `true` |
| `ACM_circulation_reusableSyringe` | `true` |
| `ACM_circulation_selfIO` | `0` |
| `ACM_circulation_selfIV` | `0` |
| `ACM_circulation_treatmentTimeIO_EZ` | `4` |
| `ACM_circulation_treatmentTimeIO_FAST1` | `4` |
| `ACM_circulation_treatmentTimeIV_14` | `8` |
| `ACM_circulation_treatmentTimeIV_16` | `6` |
| `ACM_core_Dogtag_ShowWeight` | `true` |
| `ACM_core_ignoreIncompatibleAddonWarning` | `false` |
| `ACM_core_MedicAI_AllowIntermediateTreatment` | `false` |
| `ACM_core_treatmentTimeSutureStitch` | `0.5` |
| `ACM_core_treatmentTimeTakeOffTourniquet` | `4` |
| `ACM_core_treatmentTimeWrappedStitch` | `2` |
| `ACM_core_wrappedWoundReopenChance` | `1` |
| `ACM_damage_AIStayDownChance` | `1` |
| `ACM_damage_bodyTraumaCardiacArrestThreshold` | `0` |
| `ACM_damage_bodyTraumaCardiacArrestThresholdAI` | `16` |
| `ACM_damage_bodyTraumaDeathThreshold` | `0` |
| `ACM_damage_bodyTraumaDeathThresholdAI` | `24` |
| `ACM_damage_enable` | `true` |
| `ACM_damage_headTraumaCardiacArrestThreshold` | `0` |
| `ACM_damage_headTraumaCardiacArrestThresholdAI` | `8` |
| `ACM_damage_headTraumaDeathThreshold` | `0` |
| `ACM_damage_headTraumaDeathThresholdAI` | `19` |
| `ACM_damage_internalBleedingChanceMultiplier` | `0.4` |
| `ACM_disability_enableFractureSeverity` | `true` |
| `ACM_disability_Hardcore_ComplexFracture` | `false` |
| `ACM_disability_splintFallOffTime` | `60` |
| `ACM_disability_tourniquetImpactLimbs` | `true` |
| `ACM_disability_treatmentTimeSAMSplint` | `3` |
| `ACM_disability_treatmentTimeWrapSplint` | `5` |
| `ACM_evacuation_clearCasualtyLoadout` | `false` |
| `ACM_evacuation_convertedCasualtyDeathPenalty` | `1` |
| `ACM_evacuation_enable` | `true` |
| `ACM_evacuation_locationConvert` | `0` |
| `ACM_evacuation_requireAntibiotics` | `true` |
| `ACM_evacuation_ticketCountCasualty` | `15` |
| `ACM_evacuation_ticketCountRespawn` | `50` |
| `ACM_gui_overlayBodyPart` | `false` |
| `ACM_gui_showActionItemIcons` | `true` |
| `ACM_gui_showExactPainAmount` | `true` |
| `ACM_gui_showFracture` | `true` |
| `ACM_gui_showInactiveStatuses` | `false` |
| `ACM_gui_showPatientSideLabels` | `false` |
