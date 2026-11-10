[
    QGVAR(enabled),
    "CHECKBOX",
    ["Enable respawn", "Enables respawn with given delay."],
    ["JMSB - Medical & Respawn", "Respawn"],
    false,
    1,
    {[_this] call FUNC(toggle)}
] call CBA_fnc_addSetting;

[
    QGVAR(time),
    "SLIDER",
    ["Respawn delay", "How much time must pass before player will respawn (if respawn is enabled)."],
    ["JMSB - Medical & Respawn", "Respawn"],
    [1, 900, getNumber (configFile >> "CfgRespawnTemplates" >> QGVAR(default) >> "respawnDelay"), 0],
    1,
    {[_this] call FUNC(adjustTime)}
] call CBA_fnc_addSetting;
