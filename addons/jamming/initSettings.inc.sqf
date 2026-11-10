// EVERY OPERATION VALUE THIS SYSTEM HAS NOW LIVES ON ITS EDEN MODULE - see
// CfgVehicles.hpp. A mission tunes the system where it places it, and a
// mission that places no module gets no system, so there is no enable
// checkbox here to disagree with what was placed.
//
// Nothing server-wide is left for this addon except the two below: disabling a
// terminal by hand (ACE > Jammer > Disable; user, 2026-10-24: "the jammers need
// to have a local ace interface to disable or hack") - how long it takes, and
// who may.
[
    QGVAR(disableTime), "SLIDER",
    ["Disable time (s)", "How long a player kneels at a jammer terminal to disable it by hand (ACE > Jammer > Disable)."],
    ["JMSB - EW, Drones & Intel", "Jamming"],
    [5, 120, DISABLE_TIME_DEF, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(disableNeedsEngineer), "CHECKBOX",
    ["Disable needs a specialist", "Only an engineer, an explosives specialist or an ISR operator gets the Disable action on a jammer terminal. Off: anyone."],
    ["JMSB - EW, Drones & Intel", "Jamming"],
    true,
    true
] call CBA_fnc_addSetting;
