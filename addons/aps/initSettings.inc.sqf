// CBA Settings [ADDON: jmfsb_aps]
//
// ACTIVE PROTECTION. It arms itself - see FUNC(arm) - and these are the
// numbers. Every
// value the RF burst spec left as TUNE is here, so the balance of that
// system - which is its cooldown - is a slider, not a rebuild.

// ---- hard kill ------------------------------------------------------------

[
    QGVAR(enabled), "CHECKBOX",
    ["Active protection", "Master switch. On, vehicles get the protection their faction's tier allows and the HUD's APS tile is live. Off, nothing is registered and every vehicle reads NO APS. A JMSB - APS module, if one is placed, overrides the switches below but not this."],
    ["JMSB - Vehicles & Defence", "APS"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(maxAngle), "SLIDER",
    ["Max engagement angle", "Steepest approach the launchers can engage, degrees above the horizon. A top-attack missile diving steeper than this gets through - the counter to hard-kill APS is to come from above."],
    ["JMSB - Vehicles & Defence", "APS"],
    [10, 90, 45, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(hitLimit), "SLIDER",
    ["Max round size (hit)", "Rounds whose CfgAmmo hit value is above this are too big to stop - the launchers let them through."],
    ["JMSB - Vehicles & Defence", "APS"],
    [200, 5000, 2000, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rearmRange), "SLIDER",
    ["Rearm range (m)", "A vehicle within this of an ammo truck or crate reloads its charges. Reloading the vehicle's own guns reloads them too."],
    ["JMSB - Vehicles & Defence", "APS"],
    [10, 200, 50, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rearmDelay), "SLIDER",
    ["Rearm check (s)", "How often a fitted vehicle looks for a rearm."],
    ["JMSB - Vehicles & Defence", "APS"],
    [1, 60, 5, 0],
    true
] call CBA_fnc_addSetting;

// ---- who gets what --------------------------------------------------------

[
    QGVAR(defaultTier), "LIST",
    ["Default tier", "The tier of a faction the mod does not know - a third-party mod's, usually. 0-1 nothing, 2 near-peer (basic hard kill on tanks and cannon IFVs), 3 peer (every armoured vehicle, RF burst on tanks), 4 peer+ (the complete set, RF burst on everything armoured and on helicopters)."],
    ["JMSB - Vehicles & Defence", "APS"],
    [[0, 1, 2, 3, 4], ["0 - irregular", "1 - militia", "2 - near-peer", "3 - peer", "4 - peer+"], 3],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(panelScope), "LIST",
    ["APS panel scope", "Which fitted vehicles the map panel lists and lets you switch: only the one you are in, every vehicle your group is crewing, or every crewed vehicle on your side."],
    ["JMSB - Vehicles & Defence", "APS"],
    [[0, 1, 2], ["Own vehicle", "Group's vehicles", "Whole side"], 1],
    true
] call CBA_fnc_addSetting;

// THE SHELL'S NAME FOR IT. jmfsb_tacpad reads every panel's on/off switch as
// jmfsb_tacpad_apps_show_<panel id>, so this is declared under that name and
// sits with the other panel switches in Addon Options.
[
    "jmfsb_tacpad_apps_show_aps", "CHECKBOX",
    ["Show APS panel", "The APS panel on the map screen: every fitted vehicle you are entitled to see, its charges and its emitter, and the HK HOLD / RF HOLD / BURST switches."],
    ["JMSB - Tablet & Map", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(tierOverrides), "EDITBOX",
    ["Tier overrides", "faction:tier pairs, comma separated - 'jmfsb_AAF:3, OPF_F:4'. The module's own field adds to these."],
    ["JMSB - Vehicles & Defence", "APS"],
    "",
    true
] call CBA_fnc_addSetting;

// ---- the RF burst ---------------------------------------------------------

[
    QGVAR(rfRadius), "SLIDER",
    ["RF engagement radius (m)", "The burst is a sphere this big. Guided munitions and drones inside it are hit."],
    ["JMSB - Vehicles & Defence", "APS"],
    [50, 500, 150, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfFloor), "SLIDER",
    ["RF close floor (m)", "Anything susceptible inside this fires the burst whatever it seems to be doing. Outside it, only a contact closing on the vehicle does - transit traffic is left alone so the cooldown is not spent on it."],
    ["JMSB - Vehicles & Defence", "APS"],
    [10, 200, 60, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfClosing), "SLIDER",
    ["RF closing speed (m/s)", "A contact counts as closing when its speed toward the vehicle is above this."],
    ["JMSB - Vehicles & Defence", "APS"],
    [0, 100, 15, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfCooldown), "SLIDER",
    ["RF cooldown (s)", "The only resource the emitter has. A second attacker inside this window gets a free shot - the counter to the burst is to stagger, not mass."],
    ["JMSB - Vehicles & Defence", "APS"],
    [5, 300, 45, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfJamRadius), "SLIDER",
    ["RF jam radius (m)", "Every radio inside this is jammed by the burst, friend and foe. Kept smaller than the engagement radius - it is the near-field leakage off the emitter."],
    ["JMSB - Vehicles & Defence", "APS"],
    [10, 300, 75, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfJamDismount), "SLIDER",
    ["RF jam - dismounts (s)", "How long a player on foot inside the jam radius loses the radio."],
    ["JMSB - Vehicles & Defence", "APS"],
    [0, 30, 5, 1],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfJamCrew), "SLIDER",
    ["RF jam - own crew (s)", "The emitting vehicle's own crew are shielded by the hull: a shorter blackout, never none - it is their cue that the burst fired."],
    ["JMSB - Vehicles & Defence", "APS"],
    [0, 30, 2, 1],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfDamage), "SLIDER",
    ["RF emitter damage limit", "Vehicle damage above this kills the emitter; so does a dead engine or the engine off."],
    ["JMSB - Vehicles & Defence", "APS"],
    [0.1, 1, 0.3, 2],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfProbDrone), "SLIDER",
    ["RF: quadcopter / FPV", "Chance the burst drops a small drone in range."],
    ["JMSB - Vehicles & Defence", "APS"],
    [0, 1, 1, 2],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfProbLoiter), "SLIDER",
    ["RF: loitering munition", "Chance the burst drops a loitering munition - hardened, so a little less."],
    ["JMSB - Vehicles & Defence", "APS"],
    [0, 1, 0.9, 2],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfProbATGM), "SLIDER",
    ["RF: guided missile", "Chance the burst strips guidance from a missile with a modern seeker - hardened seekers resist."],
    ["JMSB - Vehicles & Defence", "APS"],
    [0, 1, 0.6, 2],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(rfProbIR), "SLIDER",
    ["RF: IR / laser guided", "Chance the burst upsets an IR or laser seeker. This is the dazzler's job, done properly - the seeker loses the track rather than merely veering."],
    ["JMSB - Vehicles & Defence", "APS"],
    [0, 1, 0.8, 2],
    true
] call CBA_fnc_addSetting;
