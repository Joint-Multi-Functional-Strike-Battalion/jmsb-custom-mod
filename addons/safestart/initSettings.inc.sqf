
if (EGVAR(common,aceSafemode)) then {
    [
        QGVAR(startLocked),
        "CHECKBOX",
        ["Lock weapon", "Locks your weapon safety on game start"],
        ["JMSB - Mission & Admin", "Safe Start"],
        true,
        2
    ] call CBA_fnc_addSetting;
};
