[
    "1st Joint Multi-Functional Strike Battalion",
    QGVAR(placeTargetMarker),
    ["Vector: Place Target Marker", "Places a map marker on the point aimed at through a [JMSB] Vector Designator."],
    {
        call FUNC(placeTargetMarker) // return
    },
    {},
    [50, [true, true, false]]   // Ctrl+Shift+M
] call CBA_fnc_addKeybind;

// THE PERSONAL WAYPOINT - the target marker's gesture with a different audience:
// one goes to the section, one stays with you. Ctrl+Shift+T, not N: N is the
// ECOTI clip-on's power (user, 2026-11-02: "remap vector to ctrl shift t").
[
    "1st Joint Multi-Functional Strike Battalion",
    QGVAR(placeWaypoint),
    ["Vector: Place Personal Waypoint", "Drops a waypoint only you can see on the point aimed at through a [JMSB] Vector Designator. One at a time; aim at it again to clear it."],
    {
        call FUNC(placeWaypoint) // return
    },
    {},
    [20, [true, true, false]]   // Ctrl+Shift+T
] call CBA_fnc_addKeybind;
