// CBA Settings [ADDON: jmfsb_hacking]

[
    QGVAR(enabled), "CHECKBOX",
    ["Enable Hacking", "Master toggle for the tower/drone hacking self-interaction."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    true,   // default
    true    // isGlobal
] call CBA_fnc_addSetting;

// There is deliberately no "terminal items" setting any more. Hacking used to
// demand the Intrusion Tablet in your pockets on top of the ISR flag, which was
// two gates saying nearly the same thing - a mission that marks a man as its
// ISR operator has already decided he is equipped. Training is the gate and the
// tablet is kit; nothing checks for it.

[
    QGVAR(condition), "EDITBOX",
    ["Hack Condition", "SQF condition that must also return true before anyone can hack. `_this` is the unit. Left as ""true"" it never blocks anything. Example: side group _this == west"],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    "true",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(towerClasses), "EDITBOX",
    ["Hackable Tower Classes", "Comma-separated object classnames hackable as 'towers', in addition to Electronic War Zones emitters."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    "Land_TTowerBig_2_F,Land_TTowerBig_1_F,Land_Communication_F,Land_Antenna_01_F,Land_Antenna_02_F",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(droneClasses), "EDITBOX",
    ["Downable Drone Classes", "Comma-separated vehicle classnames that 'Down Drone' may target. Blank = any enemy UAV, which is the old behaviour. Listed classes still have to be enemy UAVs."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    "",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(requireISR), "CHECKBOX",
    ["Require ISR operator", "On: only a unit flagged as ISR can use the intrusion suite. This is the ONLY gate on hacking - no device is checked. The flag and its variable name are shared with Intel Hunt - see Common."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    true,
    true
] call CBA_fnc_addSetting;

// No device is required for any of this any more - not a terminal to hack and
// not a scanner to sweep. Both are flags on the man, set by the mission, which
// is one decision in one place instead of a decision plus a loadout that has to
// agree with it.
[
    QGVAR(scannerVariable), "EDITBOX",
    ["Scanner Variable", "Unit variable that controls who sweeps for emitters. Everyone does by default - no device and no flag needed. Set this variable FALSE on a unit to deny them the scanner screen, the warning lamps and the alarms."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    "jmfsb_isScanner",
    true
] call CBA_fnc_addSetting;

// Per-client, not global: an alarm ring is the one sound in the addon that
// goes off in everyone's ears at once, so how loud it is belongs to the ears.
[
    QGVAR(alarmVolume), "SLIDER",
    ["Scanner Alarm Volume", "How loud YOUR scanner's alarm beeps. 0 silences the beep entirely - the screen still blinks and the notification still shows."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [0, 2, 1, 1],   // min, max, default, decimals shown
    false           // per-client
] call CBA_fnc_addSetting;

// A DIFFERENT KIND OF HACKING from the towers: a soldier's comms at range.
// Hacking is a hacking feature, so its switch lives here, not on a module.
[
    QGVAR(remoteEnable), "CHECKBOX",
    ["Remote Unit Hack", "Players can hack an enemy soldier's comms at range. Success buys one intel product centred on the target; failure can alert the area and jam your own grid."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    false,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(remoteRange), "SLIDER",
    ["Remote Hack Range (m)", "How far a target handset can be to start a remote hack, and how far before the signal drops. Everything else about the failure package keeps its shipped default."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [50, 3000, 800, 0],
    true
] call CBA_fnc_addSetting;

// THE HACKABLE SURFACE, as directed: every tower inside the TAOR, and a
// percentage of enemy soldiers who actually carry a phone.
[
    QGVAR(towerTaor), "EDITBOX",
    ["Tower TAOR Marker(s)", "Comma-separated area marker names. Towers are hackable only inside them. Blank = anywhere on the map."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    "",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(phonePct), "SLIDER",
    ["Enemy Cell Phone Carriers (%)", "Percentage of enemy soldiers carrying a hackable cell phone. The rest have nothing to hack. Requires Remote Unit Hack on."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [0, 100, 30, 0],
    true
] call CBA_fnc_addSetting;

// --- the intel tally (new.md section 5) -------------------------------------
// OPERATION VALUES ONLY: how many, how close. WHERE the drop is comes from a
// deployed Intel Drop Case, and what the hints point at comes from ALiVE.

[
    QGVAR(perHint), "SLIDER",
    ["Deposits per Hint", "Intel items that must be DEPOSITED at a drop before ISR processes a batch and one hint circle fires. Items carried in a pocket count for nothing."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [1, 50, 10, 0],
    true
] call CBA_fnc_addSetting;


[
    QGVAR(docChance), "SLIDER",
    ["Documents on Bodies (%)", "Chance a body with no phone still carries searchable documents. Insurgents always carry a phone, so this only governs everyone else."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [0, 100, 30, 0],
    true
] call CBA_fnc_addSetting;

// THE RAMP ON WORKING NET AFTER NET. A flat detection chance made the right
// play obvious and boring: sit in a treeline and break every group that walks
// past, because the seventh costs what the first did. See FUNC(netFailChance).
[
    QGVAR(netFailStep), "SLIDER",
    ["Extra detection per net", "How much each net broken recently adds to the chance of being detected on the NEXT one, in percentage points. 0 restores a flat chance."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [0, 40, 10, 0, false],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(netFailWindow), "SLIDER",
    ["Detection memory", "How long, in seconds, a broken net keeps counting against you. One step is shed for every window that passes quietly, so a patient section is forgiven and an impatient one is not."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [60, 3600, 600, 0, false],
    true
] call CBA_fnc_addSetting;

// WHOSE NETS MAY BE BROKEN INTO. Hostile-only is the obvious rule and the wrong
// one for half the missions this gets played on: in an insurgency the phone
// worth listening to belongs to somebody who is not shooting at you, and on a
// two-sided exercise the point may be to listen to the other half of your own
// force. Your own group is never offered, whatever this says - see
// FUNC(scanDevices).
[
    QGVAR(netTargets), "LIST",
    ["Hackable nets", "Whose cell nets the remote hack will offer. Your own group is never on the list. A net that is not hostile is labelled FRIENDLY on the card, so nobody spends a minute and a detection roll on their own side by accident."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [[0, 1, 2], ["Hostile only", "Hostile and civilian", "Anyone"], 2],
    true
] call CBA_fnc_addSetting;

// HOW MUCH OF A PACKAGE ONE BREAK-IN YIELDS. A terminal carries an intel package
// the mission maker or Zeus put on it; this is the share of it a single
// successful hack hands over, from the top, never repeating what that side has
// already taken off that device.
//
// It is a percentage of the package's own length, so a two-entry package and a
// twenty-entry one both take about three visits to empty - the mission maker
// writes as much as the story needs and does not have to think about this
// number at all.
//
// 100 is one hack, everything, which is the old "a hack produces a product"
// shape if that is what a mission wants. A share that rounds to nothing still
// hands over one entry: a hack that succeeded and delivered silence reads as a
// bug to the man who did it.
[
    QGVAR(cfg_package_share), "SLIDER",
    ["Intel package share per hack (%)", "How much of a terminal's intel package one successful break-in yields. Lower means more return visits. 100 hands the whole package over at once."],
    ["JMSB - EW, Drones & Intel", "Hacking"],
    [5, 100, HACK_PACKAGE_SHARE_DEF, 0],
    true
] call CBA_fnc_addSetting;
