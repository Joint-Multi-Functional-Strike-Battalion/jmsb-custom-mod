// CBA Settings [ADDON: jmfsb_equipment]

[
    QGVAR(markerEnabled), "CHECKBOX",
    ["Enable Vector Target Marker", "Allows placing a map marker on the point aimed at through a [JMSB] Vector Designator."],
    ["JMSB - Gear & Vision", "Equipment"],
    true,   // default
    true    // isGlobal
] call CBA_fnc_addSetting;

[
    QGVAR(markerType), "LIST",
    ["Vector Marker Type", "Marker placed on the target position."],
    ["JMSB - Gear & Vision", "Equipment"],
    [
        ["hd_dot", "hd_objective", "hd_destroy", "hd_warning", "hd_unknown", "mil_dot", "mil_objective", "mil_destroy", "mil_warning", "mil_triangle"],
        ["Dot", "Objective", "Destroy", "Warning", "Unknown", "Dot (Military)", "Objective (Military)", "Destroy (Military)", "Warning (Military)", "Triangle (Military)"],
        0
    ],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(markerColor), "LIST",
    ["Vector Marker Color", "Color of the marker placed on the target position."],
    ["JMSB - Gear & Vision", "Equipment"],
    [
        ["Default", "ColorBlack", "ColorGrey", "ColorRed", "ColorGreen", "ColorBlue", "ColorOrange", "ColorYellow", "ColorWhite"],
        ["Default", "Black", "Grey", "Red", "Green", "Blue", "Orange", "Yellow", "White"],
        0
    ],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(marker3DDuration), "SLIDER",
    ["Vector 3D Marker Duration (s)", "Shows the marker name in-world (3D) at the target position for this many seconds. 0 = disabled."],
    ["JMSB - Gear & Vision", "Equipment"],
    [0, 600, 120, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(markerDuration), "SLIDER",
    ["Vector Marker Lifetime (s)", "Marker is deleted after this many seconds. 0 = permanent."],
    ["JMSB - Gear & Vision", "Equipment"],
    [0, 1800, 0, 0],
    true
] call CBA_fnc_addSetting;

// THE PERSONAL WAYPOINT. Its own type and colour rather than the target
// marker's, because the whole point is telling them apart at a glance: one is
// something the section was told, the other is a note to yourself.
[
    QGVAR(waypointEnabled), "CHECKBOX",
    ["Enable Vector Personal Waypoint", "Allows dropping a waypoint only you can see on the point aimed at through a [JMSB] Vector Designator. One at a time; aiming at it again clears it."],
    ["JMSB - Gear & Vision", "Equipment"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(waypointType), "EDITBOX",
    ["Vector Waypoint Type", "Marker type for the personal waypoint. Deliberately smaller than the shared target marker - mil_dot is a good default."],
    ["JMSB - Gear & Vision", "Equipment"],
    "mil_dot",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(waypointColor), "EDITBOX",
    ["Vector Waypoint Colour", "Marker colour for the personal waypoint. Something the shared marker is not."],
    ["JMSB - Gear & Vision", "Equipment"],
    "ColorYellow",
    false
] call CBA_fnc_addSetting;
