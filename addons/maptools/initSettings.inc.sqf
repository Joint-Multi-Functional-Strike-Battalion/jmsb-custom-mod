// CBA Settings [ADDON: jmfsb_maptools]

// How a bearing reads. Per client: a mortarman wants mils, a rifleman degrees.
[
    QGVAR(angleUnit), "LIST",
    ["Bearing units", "How the ruler, protractor and route give a bearing: degrees, NATO mils (6400 to the circle), or both."],
    ["JMSB - Tablet & Map", "Map Tools"],
    [["deg", "mil", "both"], ["Degrees", "Mils", "Both"], 2],
    false
] call CBA_fnc_addSetting;

// Off, a MARK is this player's own note. On, it goes out on the group channel
// as an ordinary player marker the rest of the group sees and can delete.
// Since the marker card (2026-11-01) it is the channel MARK's card starts on;
// the card's channel row changes it per marker.
[
    QGVAR(markShare), "CHECKBOX",
    ["Share marks with group", "MARK opens the marker card with grid and time as its text. Off starts it on your map only; on, on the group channel. The card's channel row changes it per marker."],
    ["JMSB - Tablet & Map", "Map Tools"],
    false,
    false
] call CBA_fnc_addSetting;

// THE MARKER SYSTEM (user, 2026-11-01). A client UI choice, each player's own:
// what a double-click on the device's map and a MARK press open. ACE and ALiVE
// are listed only when loaded; one chosen and then not loaded, or ALiVE
// without its Advanced Markers module in the mission, falls back to Built-in.
[
    QGVAR(markerSystem), "LIST",
    ["Map marker system", "What a double-click on the tablet's map and a MAP TOOLS MARK press open. Built-in: the marker card (icon, colour, text, channel). ACE: ACE's marker dialog. ALiVE: ALiVE's Advanced Marker dialog. The vanilla map's own double-click stays the game's."],
    ["JMSB - Tablet & Map", "Map Tools"],
    [MARKERS_VALUES, MARKERS_LABELS, 0],
    false
] call CBA_fnc_addSetting;

// VIEWSHED'S TWO OPERATION VALUES. How far it looks and how coarse its cells
// are; together they set how many rays it traces, and so how long it takes to
// fill - a frame never traces more than its share either way.
[
    QGVAR(viewshedRadius), "SLIDER",
    ["Viewshed radius", "How far, in metres, VIEWSHED works out line of sight from the clicked point."],
    ["JMSB - Tablet & Map", "Map Tools"],
    [VS_RADIUS_MIN, VS_RADIUS_MAX, VS_RADIUS_DEFAULT, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(viewshedCell), "SLIDER",
    ["Viewshed resolution", "The size, in metres, of one VIEWSHED cell. Smaller is finer and slower to fill. A viewshed draws at most 4000 cells: past that, at a wide radius, the cell is made coarser."],
    ["JMSB - Tablet & Map", "Map Tools"],
    [VS_CELL_MIN, VS_CELL_MAX, VS_CELL_DEFAULT, 0],
    1
] call CBA_fnc_addSetting;

// RANGE RINGS (user, 2026-10-30): how far apart, and how many. Per player.
[
    QGVAR(ringStep), "SLIDER",
    ["Range ring spacing", "Metres between the RINGS tool's rings."],
    ["JMSB - Tablet & Map", "Map Tools"],
    [RING_STEP_MIN, RING_STEP_MAX, RING_STEP_DEFAULT, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(ringCount), "SLIDER",
    ["Range rings", "How many rings the RINGS tool draws about the pressed point."],
    ["JMSB - Tablet & Map", "Map Tools"],
    [RING_COUNT_MIN, RING_COUNT_MAX, RING_COUNT_DEFAULT, 0],
    false
] call CBA_fnc_addSetting;
