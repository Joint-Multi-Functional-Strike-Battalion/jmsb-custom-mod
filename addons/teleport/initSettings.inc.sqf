// Reeveli's two settings, under jmfsb's own category.

[
    QGVAR(actionRadius),
    "SLIDER",
    ["Action visibility radius", "How close to a teleport object the action shows, in metres."],
    ["JMSB - Mission & Admin", "Teleport"],
    [5, 30, 5, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    QGVAR(actionTime),
    "SLIDER",
    ["Teleportation time", "How long the move and its screen fade last, in seconds."],
    ["JMSB - Mission & Admin", "Teleport"],
    [1, 120, 6, 0],
    1,
    {}
] call CBA_fnc_addSetting;
