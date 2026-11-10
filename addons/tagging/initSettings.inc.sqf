
if (EGVAR(common,aceTagging)) then {
    [
        QGVAR(enabled),
        "CHECKBOX",
        ["Enable ACE Tagging markers", "Automatically create markers on buildings sprayed with ACE Spray."],
        ["JMSB - Gear & Vision", "Tagging"],
        false,
        true
    ] call CBA_fnc_addSetting;
};
