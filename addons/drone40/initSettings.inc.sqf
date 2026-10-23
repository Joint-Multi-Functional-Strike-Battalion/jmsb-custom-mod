// CBA Settings [ADDON: jmfsb_drone40]
// OPERATION VALUES ONLY: how far and how hard the jammer drone jams. Who
// carries one is the loadout's business. Server-forced: the server prices the
// noise.

[
    QGVAR(jammerRadius), "SLIDER",
    ["Jammer radius (m)", "How far a Drone40 Jammer's barrage counts in the RF link budget. Inside it the noise falls off with the band's path loss; past it, nothing."],
    ["1st Joint Multi-Functional Strike Battalion", "Drone40"],
    [MIN_JAMMER_RADIUS, MAX_JAMMER_RADIUS, DEFAULT_JAMMER_RADIUS, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(jammerPower), "SLIDER",
    ["Jammer power (dBm)", "Transmit power of a Drone40 Jammer's barrage on VHF and UHF, as noise in the RF link budget. 30 = 1 W, 37 = 5 W, 43 = 20 W."],
    ["1st Joint Multi-Functional Strike Battalion", "Drone40"],
    [MIN_JAMMER_POWER, MAX_JAMMER_POWER, DEFAULT_JAMMER_POWER, 0],
    1
] call CBA_fnc_addSetting;
