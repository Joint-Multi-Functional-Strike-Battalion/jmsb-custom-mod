// CBA Settings [ADDON: jmfsb_mission]
// OPERATION VALUES ONLY: switches. Where the staging zones are is the mission's
// (markers, objects, the Zeus module), never a setting.

[
    QGVAR(stagingSatUplink), "CHECKBOX",
    ["Staging zone satellite uplink", "Every staging zone carries a radio base station at its centre: it relays the players' nets round the zone and links by satellite to the patrol bases and SAT-capable vehicles under open sky, at any distance."],
    ["1st Joint Multi-Functional Strike Battalion", "Staging"],
    true,
    1
] call CBA_fnc_addSetting;
