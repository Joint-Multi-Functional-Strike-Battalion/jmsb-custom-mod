// CBA Settings [ADDON: jmfsb_adsite]
//
// AIR DEFENCE INTERCEPT. Every number here is how the defences OPERATE - what
// they intercept, how far, how likely, what they sound. Where they are and
// whose they are is the hardware's: a vehicle's own crew side, a Site module's
// sync, a battery jmfsb_airdefence placed.

#define ADS_CATEGORY ["1st Joint Multi-Functional Strike Battalion", "Air Defence"]

[
    QGVAR(enabled), "CHECKBOX",
    ["Intercept incoming munitions", "On: every air defence vehicle - a CIWS, an AA gun with a radar, a SAM launcher - shoots down artillery, rockets, missiles and bombs predicted to land inside its protected radius. Aircraft and drones are always left to the crews' own AI."],
    ADS_CATEGORY,
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(interceptChance), "SLIDER",
    ["Intercept chance", "Rolled once per intercept attempt. A failed roll lets that round through that attempt; another unit may still try if there is time."],
    ADS_CATEGORY,
    [0, 1, 0.75, 0, true],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(threatArtillery), "CHECKBOX",
    ["Intercept artillery and mortar", "Artillery and mortar shells, and the submunition carriers MLRS rockets are made of."],
    ADS_CATEGORY,
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(threatRockets), "CHECKBOX",
    ["Intercept rockets", "Unguided rockets."],
    ADS_CATEGORY,
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(threatMissiles), "CHECKBOX",
    ["Intercept missiles", "Guided and cruise missiles other than anti-air ones."],
    ADS_CATEGORY,
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(threatBombs), "CHECKBOX",
    ["Intercept bombs", "Free-fall and guided bombs."],
    ADS_CATEGORY,
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(radiusCap), "SLIDER",
    ["Protect radius cap (m)", "A unit protects the ground within its own weapon reach, but never further than this. A Site module's Protected Radius overrides it for that Site's vehicles."],
    ADS_CATEGORY,
    [500, 15000, 4000, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(ignoreSides), "CHECKBOX",
    ["Ignore sides", "On: any round coming down inside a protected radius is intercepted, whoever fired it - friendly artillery too. Off: only rounds fired by a side hostile to the unit's."],
    ADS_CATEGORY,
    false,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(alarmWest), "LIST",
    ["Alarm - BLUFOR", "Played on BLUFOR air defence and the loudspeakers near it when munitions are incoming."],
    ADS_CATEGORY,
    [ADS_ALARM_INDICES, ADS_ALARM_NAMES, 2],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(alarmEast), "LIST",
    ["Alarm - OPFOR", "As BLUFOR's, for OPFOR air defence."],
    ADS_CATEGORY,
    [ADS_ALARM_INDICES, ADS_ALARM_NAMES, 3],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(alarmIndependent), "LIST",
    ["Alarm - Independent", "As BLUFOR's, for Independent air defence."],
    ADS_CATEGORY,
    [ADS_ALARM_INDICES, ADS_ALARM_NAMES, 4],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(alarmCooldown), "SLIDER",
    ["Alarm repeat (s)", "An area's alarm sounds once per salvo, and again only after this long."],
    ADS_CATEGORY,
    [5, 120, 20, 0],
    true
] call CBA_fnc_addSetting;
