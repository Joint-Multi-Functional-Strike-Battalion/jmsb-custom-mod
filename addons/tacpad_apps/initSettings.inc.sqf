// CBA Settings [ADDON: jmfsb_tacpad_apps]

// One switch per element, which is the point: a player who wants the squad rail
// and nothing else gets exactly that. All per-client - what is on somebody's
// own map screen is theirs.
//
// The names are read by the shell as jmfsb_tacpad_apps_show_<panel id>, so a
// new panel needs a setting with a matching name and nothing else.

[
    QGVAR(show_tiles), "CHECKBOX",
    ["Show live tiles", "The band across the top: drones, jamming, weather and radio. Clicking a tile opens that app."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

// ONE ROW OR TWO. One is the design's band and the default; two stacks the same
// tiles half as wide, for a screen where the squad rail and the reader have
// taken the width the band wanted.
[
    QGVAR(tileRows), "LIST",
    ["Live tile rows", "How many rows the tile band stands in. One is the design's band across the top; two stacks the same tiles in half the width."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    [["1", "2"], ["One row", "Two rows"], 0],
    false,
    {{["tiles"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame}
] call CBA_fnc_addSetting;

[
    QGVAR(show_squad), "CHECKBOX",
    ["Show squad list", "The left rail: one row per man with a health swatch."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(show_reader), "CHECKBOX",
    ["Show message reader", "The docked message reader. Needs the messaging addon - without it the panel says so."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(show_tic), "CHECKBOX",
    ["Show troops in contact button", "The big one under the rail. One press marks the map, alerts the side and files a contact report on the command net. A mission that would rather a contact report was filled in properly can take it off the screen."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(show_tools), "CHECKBOX",
    ["Show map tools", "The tool strip along the bottom: centre, ruler, protractor, route, mark, grid, viewshed and clear."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

// The 1a / 1b choice from the design handoff. Glove mode (1c) and the template
// picker (1d) are not built.
[
    QGVAR(readerDense), "CHECKBOX",
    [
        "Reader: high density",
        "Off is standard density - subject on one line, state under it. On puts one thread per row so a screenful can be scanned at once, which is what a TOC wants and a rifleman does not."
    ],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    false,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(show_settings), "CHECKBOX",
    ["Show settings gear", "The gear under the message reader that opens the settings screen. Off leaves Addon Options as the only way to change the suite."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;
