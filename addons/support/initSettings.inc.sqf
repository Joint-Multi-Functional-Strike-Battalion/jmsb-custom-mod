// WHO MAY TASK. Moved here from tacpad_apps with the gate itself - the core
// owns the tasking tag gate, so a request made from anywhere - a message to
// an asset's box, a mission script - passes the same check. Same title, same
// category, same default as before.
[
    QGVAR(tag), "EDITBOX",
    ["Support tasking tag", "Audience tag that may task support assets by message (TAC//MSG's SUPPORT group) - JFO, HQ, AVIATION, a squad, a callsign. JFO matches the mission's isJFO customVariable. Empty: everyone."],
    ["JMSB - Tablet & Map", "Tacpad"],
    "",
    true
] call CBA_fnc_addSetting;
