[
    QGVAR(enableAddon),
    "CHECKBOX",
    ["Enable Back To Game", "Activate teleport and loadout restore after reconnect."],
    ["JMSB - Mission & Admin", "Back To Game"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(teleportToLeader),
    "CHECKBOX",
    ["Teleport to leader", "Allow player teleportation to his group leader."],
    ["JMSB - Mission & Admin", "Back To Game"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(teleportToVehicle),
    "CHECKBOX",
    ["Teleport to vehicle", "Allow player teleportation to his last vehicle or group leader vehicle."],
    ["JMSB - Mission & Admin", "Back To Game"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(removeBody),
    "CHECKBOX",
    ["Remove body", "Removes bodies of alive people who disconnected."],
    ["JMSB - Mission & Admin", "Back To Game"],
    true,
    true
] call CBA_fnc_addSetting;
