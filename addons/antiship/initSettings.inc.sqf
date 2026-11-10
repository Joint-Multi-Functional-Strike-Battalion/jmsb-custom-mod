// CBA Settings [ADDON: jmfsb_antiship]

// WHAT THE MODULE'S ATTRIBUTES BECAME. jmfsb_moduleAntiShip carried twenty-two
// of them, most describing where to SITE a battery - the sides to enable, each
// side's TAOR markers, each side's launcher class, how many to place. None of
// that survives: there is no module and no TAOR, and a launcher stands where
// somebody put it.
//
// What is left is how a battery BEHAVES, which is the same for every battery on
// the map and therefore a setting rather than a per-object field. A mission that
// needs two batteries behaving differently has a bigger question than this
// addon answers.
//
// ALL SERVER-SIDE. Every one of these decides something that happens on the
// server and is seen by everybody - a client cannot be allowed its own opinion
// about how fast a missile flies.

[
    QGVAR(interval), "SLIDER",
    ["Seconds between launches", "How long a battery waits between shots. The clock resets whether or not it found a hull, so a battery does not fire the instant a ship appears - that is a trap, not a coastal battery."],
    ["JMSB - Vehicles & Defence", "Anti-Ship"],
    [60, 3600, AS_INTERVAL_DEF, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(searchRange), "SLIDER",
    ["Search range (m)", "How far a battery looks for a hull. With a radar on the net it sees what the radar sees; with none it looks for itself, which is what this bounds."],
    ["JMSB - Vehicles & Defence", "Anti-Ship"],
    [1000, 30000, AS_SEARCH_DEF, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(targetClasses), "EDITBOX",
    ["Target classes", "Comma-separated. What counts as a hull worth a missile."],
    ["JMSB - Vehicles & Defence", "Anti-Ship"],
    AS_TARGETS_DEF,
    true
] call CBA_fnc_addSetting;

// ---- the missile ----------------------------------------------------------

[
    QGVAR(missileSpeed), "SLIDER",
    ["Missile speed (m/s)", "Cruise speed on the run in. Fast enough that it has to be met head-on rather than chased, which is the whole shape of defending against one."],
    ["JMSB - Vehicles & Defence", "Anti-Ship"],
    [200, 1500, AS_SPEED_DEF, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(cruiseAlt), "SLIDER",
    ["Cruise altitude (m)", "Height above the sea on the run in. Low is what makes it hard to see coming and hard to engage."],
    ["JMSB - Vehicles & Defence", "Anti-Ship"],
    [5, 500, AS_CRUISE_ALT_DEF, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(terminalRange), "SLIDER",
    ["Terminal range (m)", "Distance from the hull where it stops cruising and dives."],
    ["JMSB - Vehicles & Defence", "Anti-Ship"],
    [100, 5000, AS_TERMINAL_DEF, 0],
    true
] call CBA_fnc_addSetting;

// THE DECOY IS WHAT MAKES THE DEFENCE A FIGHT. Off, the missile is a scripted
// object that arrives or does not; on, it carries something the defending side's
// AA and CIWS can lock and engage, so shooting one down is a thing a crew does
// rather than a die roll.
[
    QGVAR(interceptable), "CHECKBOX",
    ["Interceptable", "The missile carries a decoy the defending side's AA and CIWS can engage. Off: nothing can lock it and it always arrives."],
    ["JMSB - Vehicles & Defence", "Anti-Ship"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(debug), "CHECKBOX",
    ["Debug", "Log every cycle to the RPT: what a battery looked for, what it found, what it fired and where the missile went."],
    ["JMSB - Vehicles & Defence", "Anti-Ship"],
    false,
    true
] call CBA_fnc_addSetting;
