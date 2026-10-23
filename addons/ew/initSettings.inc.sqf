// CBA Settings [ADDON: jmfsb_ew]
// OPERATION VALUES ONLY: ticks, windows, timers, ranges. Nothing here says
// where or who - emitters come from RF, sides from the units that hold them.
// All are global (server-forced): the server computes every track.

[
    QGVAR(dfTick), "SLIDER",
    ["DF tick (sec)", "How often intercepts are taken, cuts crossed into fixes and each side's picture sent."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [1, 15, DEFAULT_DF_TICK, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(fixWindow), "SLIDER",
    ["Fix window (sec)", "Two cuts from different places inside this window make a fix. Move after transmitting to beat it."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [5, 120, DEFAULT_FIX_WINDOW, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(trackTtl), "SLIDER",
    ["Track lifetime (sec)", "A track nobody has heard for this long is dropped."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [30, 1800, DEFAULT_TRACK_TTL, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(decoyLife), "SLIDER",
    ["Decoy battery (sec)", "How long a placed decoy radiates before its battery is flat and it is removed."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [60, 3600, DEFAULT_DECOY_LIFE, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(spoofRadius), "SLIDER",
    ["GPS spoof radius (m)", "Reach of a GPS spoofer at full power; lower power steps reach less."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [100, 3000, DEFAULT_SPOOF_RADIUS, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(spoofDrift), "SLIDER",
    ["GPS spoof max drift (m)", "How far an unprotected GPS inside a spoofer's field is walked off its true position."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [50, 2000, DEFAULT_SPOOF_DRIFT, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(jamRange), "SLIDER",
    ["Jammer reach (m)", "Past this distance a jammer adds no noise, whatever its power."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [500, 10000, DEFAULT_JAM_RANGE, 0],
    1
] call CBA_fnc_addSetting;

// THE JAMMER MODULE'S POWER SYSTEM (FUNC(jamPower)).
[
    QGVAR(jamBatteryWh), "SLIDER",
    ["Jammer battery (Wh)", "What a jammer module's battery holds. It runs the transmitter while the vehicle's engine is off; flat, the jammer goes off the air until the engine runs."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [20, 2000, DEFAULT_JAM_BATTERY_WH, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(jamChargeW), "SLIDER",
    ["Jammer charge with the engine running (W)", "What a running engine puts into the jammer's battery over the transmitter's own draw."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [10, 2000, DEFAULT_JAM_CHARGE_W, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(jamHeatRise), "SLIDER",
    ["Jammer heating (% per sec at full output)", "How fast a jammer heats at 50 W continuous; less output heats it less. At 100% it cuts out until it has cooled to 60%."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [0.05, 5, DEFAULT_JAM_HEAT_RISE, 2],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(jamHeatCool), "SLIDER",
    ["Jammer cooling (% per sec)", "How fast a jammer sheds heat, transmitting or not. A jammer whose heating at its output is below this never cuts out."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [0.01, 2, DEFAULT_JAM_HEAT_COOL, 2],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(spoofHackTime), "SLIDER",
    ["Hacked GPS spoof (sec)", "How long a net broken with the HACK app's SPOOF has its GPS walked off true, before it walks back."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [30, 1800, DEFAULT_SPOOF_HACK_TIME, 0],
    1
] call CBA_fnc_addSetting;

// AI EW (DESIGN_EW "Both ways: AI EW", D17). How well the enemy side's AI -
// the side worked out from the mission (jmfsb_common_fnc_enemySide), never
// typed here - uses EW against the players.
[
    QGVAR(aiSkill), "LIST",
    ["Enemy AI EW skill", "OFF: the enemy AI takes no DF cuts. BASIC: its groups with a DF-capable radio take cuts on player transmitters, and a fix near its groups alerts those the report reaches and goes through the reaction ladder. ACTIVE: also sends a drone to the fix. SMART: also a QRF."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [[AI_OFF, AI_BASIC, AI_ACTIVE, AI_SMART], AI_SKILL_NAMES, DEFAULT_AI_SKILL],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(aiReactRange), "SLIDER",
    ["Enemy AI fix reaction range (m)", "An enemy fix this close to one of its groups is answered; farther fixes are only tracked."],
    ["1st Joint Multi-Functional Strike Battalion", "EW"],
    [200, 5000, DEFAULT_AI_RANGE, 0],
    1
] call CBA_fnc_addSetting;
