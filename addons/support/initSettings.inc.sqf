// WHO MAY TASK. Moved here from tacpad_apps with the gate itself - the core
// owns the tasking tag gate, so a request made from anywhere passes the same
// check the screen does. Same title, same category, same default as before.
[
    QGVAR(tag), "EDITBOX",
    ["Support tasking tag", "Audience tag that may use TAC//SUPPORT - JFO, HQ, AVIATION, a squad, a callsign. JFO matches the mission's isJFO customVariable. Empty: everyone."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    "",
    true
] call CBA_fnc_addSetting;
