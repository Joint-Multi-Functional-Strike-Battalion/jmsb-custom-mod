[
    QGVAR(enabled),
    "CHECKBOX",
    ["Force Grass", "Forces grass for all players"],
    ["JMSB - Mission & Admin", "Grass"],
    false,
    1,
    {[_this] call FUNC(toggle)}
] call CBA_fnc_addSetting;
