// CBA Settings [ADDON: jmfsb_uas]

// WHAT IS LEFT AFTER THE MODULE TOOK ITS SHARE. One module is one patrol and
// carries its own side, airframe, count and artillery - so what remains here is
// only the supply economy, which is genuinely map-wide: caches belong to a side
// rather than to a patrol, and an outage thins every patrol that side has.
//
// jmfsb_moduleUAS's ceilings and per-side airframe fields are gone entirely. A
// patrol's size is the number on its own module now, which is the question
// "how many drones over THIS ground" rather than "how many does this side own".
//
// ALL SERVER-SIDE.

[
    QGVAR(windowMin), "SLIDER",
    ["Outage minimum (s)", "Shortest time a destroyed cache holds the ceiling down. Outages extend rather than stack, so supply raids are raids and not a win button."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    [60, 3600, 600, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(windowMax), "SLIDER",
    ["Outage maximum (s)", "Longest time a destroyed cache holds the ceiling down."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    [60, 7200, 1800, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(cachesPerSide), "SLIDER",
    ["Supply caches per side", "Unmarked crates placed inside that side's patrol zones, split across them. Finding them is what the intel economy is for; killing one drops the ceiling."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    [0, 12, 3, 0],
    true
] call CBA_fnc_addSetting;

// WHICH AIRFRAME EACH SIDE FLIES. A faction name, resolved by FUNC(factionUav) -
// empty scans for a UAV belonging to that side and falls back to the vanilla
// one. It was a module field per side and is the same thing here, minus the
// module.

// WHAT A SWARM MAY BE MADE OF. The JMSB - Drone Swarm module's picker offers
// every UAV the game has, because an Eden attribute is read from config and
// cannot know about a CBA setting; this is the list that actually gets fielded,
// and a module naming anything outside it is refused when it is placed.
//
// Empty means no restriction - whatever was picked flies. That is the right
// default for a mission maker on their own machine and the wrong one for a
// unit that has decided which drones exist in its world, which is why the
// setting is here at all.
[
    QGVAR(swarmClasses), "EDITBOX",
    ["Swarm airframes", "Comma-separated UAV classes a Drone Swarm module may field: a class on the list or a variant of one (a faction's own Switchblade is a variant of the Switchblade). Empty allows any. A module naming a class outside this list refuses to launch and says so when it is placed."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    "O_UAV_01_F,B_UAV_01_F,I_UAV_01_F,B_SwitchBlade_300,B_SwitchBlade_600",
    true
] call CBA_fnc_addSetting;

// ---------------------------------------------------------------- ALiVE -----
// PATROLS OVER A COMMANDER'S OBJECTIVES. jmfsb had no zones: every patrol
// orbited an ALiVE objective, and the JMSB - UAS module was the enable.
// DIVINER deleted that module and made a drawn zone the enable instead. These
// put the ALiVE half back as an OPT-IN - loading ALiVE should not silently put
// drones over every objective on the map. See FUNC(zonesFromAlive).
//
// They do nothing at all without the adapter loaded and its commanders up.
[
    QGVAR(aliveZones), "CHECKBOX",
    ["Patrol ALiVE objectives", "Turn a share of each commander's ALiVE objectives into patrol zones, once, when the campaign comes up. Hand-placed Drone Patrol modules are unaffected and add to these. Needs ALiVE - without it this does nothing."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    false,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(aliveZoneShare), "SLIDER",
    ["ALiVE objectives patrolled (%)", "Share of one commander's objectives that get a patrol zone. This shapes a small map; the cap below is what bounds a big one."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    [0, 100, 30, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(aliveZoneMax), "SLIDER",
    ["Max ALiVE zones per side", "Hard ceiling per commander whatever the share works out to. A percentage has no ceiling - 30% of 173 objectives is 52 zones, and the planner would try to hold an airframe over every one."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    [0, 30, 6, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(aliveZoneRadius), "SLIDER",
    ["ALiVE zone radius (m)", "Orbit radius for a zone taken from an objective. 0 uses the objective's own size, which is what ALiVE thinks that place is worth."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    [0, 3000, 0, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(aliveZoneDrones), "SLIDER",
    ["Airframes per ALiVE zone", "How many drones each objective-derived zone tries to hold up. The airframe itself is always the commander's own faction UAV."],
    ["JMSB - EW, Drones & Intel", "Drones"],
    [1, 6, 1, 0],
    true
] call CBA_fnc_addSetting;
