// CBA Settings [ADDON: jmfsb_evac]

[
    QGVAR(enabled), "CHECKBOX",
    ["Enable Medic Evac", "Master toggle for the medic 'Evacuate (Reinforce)' action that replaces respawn. Stands down on its own when Advanced Combat Medicine (ACM) is loaded, which brings its own evacuation."],
    ["JMSB - Medical & Respawn", "Evac"],
    true,   // default
    true    // isGlobal
] call CBA_fnc_addSetting;

[
    QGVAR(medicOnly), "CHECKBOX",
    ["Medics Only", "If checked, only ACE medics can evacuate a downed player. Uncheck to let anyone do it."],
    ["JMSB - Medical & Respawn", "Evac"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(time), "SLIDER",
    ["Evac Time (s)", "How long the medic's evacuate progress bar takes, in seconds."],
    ["JMSB - Medical & Respawn", "Evac"],
    [0, 60, EVAC_DEFAULT_TIME, 0],
    true
] call CBA_fnc_addSetting;
