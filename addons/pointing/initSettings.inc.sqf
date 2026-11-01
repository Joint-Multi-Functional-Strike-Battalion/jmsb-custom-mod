
if (EGVAR(common,aceFinger)) then {
    [
        QGVAR(vehicleEnabled),
        "CHECKBOX",
        ["Enable pointing in vehicles", "Allows to point current camera direction in vehicles to rest of the crew."],
        ["JMSB - Gear & Vision", "Pointing"],
        true,
        true
    ] call CBA_fnc_addSetting;
};
