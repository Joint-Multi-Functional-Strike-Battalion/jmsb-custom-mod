// CBA Settings [ADDON: jmfsb_artydeploy]
// OPERATION VALUES ONLY.

// How long a carrier's driver takes to set the gun up, and to pack it again
// (user, 2026-10-25: "cba setting to set the length of time but for now 60
// seconds").
[
    QGVAR(time), "SLIDER",
    ["Deploy / pack time (s)", "How long an artillery carrier's driver takes to set its mortar or launcher up behind the vehicle, and to pack it away again."],
    ["JMSB - Vehicles & Defence", "Artillery Carriers"],
    [5, 300, DEPLOY_TIME_DEFAULT, 0],
    true
] call CBA_fnc_addSetting;
