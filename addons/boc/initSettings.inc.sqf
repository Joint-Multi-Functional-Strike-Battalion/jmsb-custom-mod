// CBA Settings [ADDON: bocr_main]:

[
    QGVAR(disabled), "CHECKBOX",
    ["Disable BackpackOnChest", "Prohibit BackpackOnChest features"],
    ["JMSB - Gear & Vision", "Backpack On Chest"],
    false, // default value
    true // isGlobal
] call CBA_fnc_addSetting;

[
    QGVAR(walk), "CHECKBOX",
    ["Force Walking", "Player is forced to walk when backpack is on chest"],
    ["JMSB - Gear & Vision", "Backpack On Chest"],
    true, // default value
    true // isGlobal
] call CBA_fnc_addSetting;

// Blacklisted variables for mods that don't want variables to be transferred. Useful for very particular cases.
GVAR(VarBlacklist) = [

];
