// CBA Settings [ADDON: jmfsb_maptools]

// How a bearing reads. Per client: a mortarman wants mils, a rifleman degrees.
[
    QGVAR(angleUnit), "LIST",
    ["Bearing units", "How the ruler, protractor and route give a bearing: degrees, NATO mils (6400 to the circle), or both."],
    ["1st Joint Multi-Functional Strike Battalion", "Map Tools"],
    [["deg", "mil", "both"], ["Degrees", "Mils", "Both"], 2],
    false
] call CBA_fnc_addSetting;

// Off, a MARK is this player's own note. On, it goes out on the group channel
// as an ordinary player marker the rest of the group sees and can delete.
[
    QGVAR(markShare), "CHECKBOX",
    ["Share marks with group", "MARK drops a marker with grid and time. Off keeps it on your map only; on puts it on the group channel."],
    ["1st Joint Multi-Functional Strike Battalion", "Map Tools"],
    false,
    false
] call CBA_fnc_addSetting;

// VIEWSHED'S TWO OPERATION VALUES. How far it looks and how coarse its cells
// are; together they set how many rays it traces, and so how long it takes to
// fill - a frame never traces more than its share either way.
[
    QGVAR(viewshedRadius), "SLIDER",
    ["Viewshed radius", "How far, in metres, VIEWSHED works out line of sight from the clicked point."],
    ["1st Joint Multi-Functional Strike Battalion", "Map Tools"],
    [VS_RADIUS_MIN, VS_RADIUS_MAX, VS_RADIUS_DEFAULT, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(viewshedCell), "SLIDER",
    ["Viewshed resolution", "The size, in metres, of one VIEWSHED cell. Smaller is finer and slower to fill."],
    ["1st Joint Multi-Functional Strike Battalion", "Map Tools"],
    [VS_CELL_MIN, VS_CELL_MAX, VS_CELL_DEFAULT, 0],
    1
] call CBA_fnc_addSetting;
