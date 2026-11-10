[
    QGVAR(triggerRadiusMultiplier),
    "SLIDER",
    ["Anti-Drone Trigger Radius Multiplier", "Scales the proximity trigger radius of all PAB rounds. 1 = default."],
    ["JMSB - Vehicles & Defence", "Anti-Drone Ammunition"],
    [0.25, 2, 1, 2],
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;

[
    QGVAR(lethalRadiusMultiplier),
    "SLIDER",
    ["Anti-Drone Lethal Radius Multiplier", "Scales the lethal (blast) radius of all PAB rounds. 1 = default."],
    ["JMSB - Vehicles & Defence", "Anti-Drone Ammunition"],
    [0.25, 2, 1, 2],
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;

[
    QGVAR(damageMultiplier),
    "SLIDER",
    ["Anti-Drone Damage Multiplier", "Scales the proximity-airburst damage applied to UAVs by all PAB rounds. 1 = default."],
    ["JMSB - Vehicles & Defence", "Anti-Drone Ammunition"],
    [0.25, 2, 1, 2],
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;
