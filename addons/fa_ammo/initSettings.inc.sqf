[
    QGVAR(enableBreaching),
    "CHECKBOX",
    ["Enable Mk353 BRC Breaching Script", "When enabled, firing the Mk353 BRC round near a door will attempt to force it open. Disable if a dedicated breaching mod handles this."],
    ["JMSB - Vehicles & Defence", "Future Ammunition"],
    true,
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;

[
    QGVAR(debugBreaching),
    "CHECKBOX",
    ["Debug Mk353 BRC Breaching", "Prints each step of the breach detection/open logic to chat when firing the Mk353 BRC round, to help diagnose why a door isn't opening."],
    ["JMSB - Vehicles & Defence", "Future Ammunition"],
    false,
    true,
    SETTING_OVERRIDE_HOOK
] call CBA_fnc_addSetting;
