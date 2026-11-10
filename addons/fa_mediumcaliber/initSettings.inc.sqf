[
    QGVAR(factionScaling),
    "CHECKBOX",
    ["Enable Faction Scaling", "Master toggle for the West/Green/Red performance gradient. Off = flat parity, everyone performs at West's 100%."],
    ["JMSB - Vehicles & Defence", "Medium Caliber 2040"],
    true,
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;

[
    QGVAR(greenFraction),
    "SLIDER",
    ["Green (Independent) Faction Fraction", "Fraction of West's performance ceiling realized by Independent/Green forces. 1.00 = parity with West."],
    ["JMSB - Vehicles & Defence", "Medium Caliber 2040"],
    [0.50, 1.00, 0.85, 2],
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;

[
    QGVAR(redFraction),
    "SLIDER",
    ["Red (OPFOR) Faction Fraction", "Fraction of West's performance ceiling realized by OPFOR/Red forces. 1.00 = parity with West."],
    ["JMSB - Vehicles & Defence", "Medium Caliber 2040"],
    [0.50, 1.00, 0.75, 2],
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;

[
    QGVAR(cuasCeiling),
    "SLIDER",
    ["Counter-UAS Effectiveness Ceiling", "Scales the airburst/proximity radii and lethality of every programmable round in this module, on top of the faction fraction."],
    ["JMSB - Vehicles & Defence", "Medium Caliber 2040"],
    [0.75, 1.50, 1.40, 2],
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;

[
    QGVAR(enableAirburst),
    "CHECKBOX",
    ["Enable Scripted Airburst", "Master switch for the programmable-fuze subsystem (ABM, PROX, AHEAD, AMP, HE-AB). Off = these rounds behave as plain point-detonate/kinetic rounds."],
    ["JMSB - Vehicles & Defence", "Medium Caliber 2040"],
    true,
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;
