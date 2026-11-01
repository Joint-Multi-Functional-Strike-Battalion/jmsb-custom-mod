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
[
    QGVAR(markShare), "CHECKBOX",
    ["Share marks with group", "MARK drops a marker with grid and time. Off keeps it on your map only; on puts it on the group channel."],
    ["JMSB - Tablet & Map", "Map Tools"],
    false,
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
