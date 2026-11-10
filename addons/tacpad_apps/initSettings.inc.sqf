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
    ["JMSB - Tablet & Map", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

// ONE ROW OR TWO. One is the design's band and the default; two stacks the same
// tiles half as wide, for a screen where the squad rail and the reader have
// taken the width the band wanted.
[
    QGVAR(tileRows), "LIST",
    ["Live tile rows", "How many rows the tile band stands in. One is the design's band across the top; two stacks the same tiles in half the width."],
    ["JMSB - Tablet & Map", "Tacpad"],
    [["1", "2"], ["One row", "Two rows"], 0],
    false,
    {{["tiles"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame}
] call CBA_fnc_addSetting;

[
    QGVAR(show_squad), "CHECKBOX",
    ["Show squad list", "The left rail: one row per man with a health swatch."],
    ["JMSB - Tablet & Map", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(show_reader), "CHECKBOX",
    ["Show message reader", "The docked message reader. Needs the messaging addon - without it the panel says so."],
    ["JMSB - Tablet & Map", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(show_tic), "CHECKBOX",
    ["Show troops in contact button", "The big one under the rail. One press marks the map, alerts the side and files a contact report on the command net. A mission that would rather a contact report was filled in properly can take it off the screen."],
    ["JMSB - Tablet & Map", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(show_tools), "CHECKBOX",
    ["Show map tools", "The tool strip along the bottom: centre, ruler, protractor, route, mark, grid, viewshed and clear."],
    ["JMSB - Tablet & Map", "Tacpad"],
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
    ["JMSB - Tablet & Map", "Tacpad"],
    false,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(show_settings), "CHECKBOX",
    ["Show settings gear", "The gear under the message reader that opens the settings screen. Off leaves Addon Options as the only way to change the suite."],
    ["JMSB - Tablet & Map", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

// WHICH TILES, IN WHICH SLOTS - the player's own (user, 2026-10-24: "players
// need to be able to turn on and off live tiles in settings and assign a
// slot"). Edited from SETTINGS > LIVE TILES - a dropdown of tiles per position,
// an ON / OFF row per tile; the text form is only how it is kept:
// "drones:1,jam:off,pac:2". A tile not named fills the positions nobody placed,
// in the default order (FUNC(tileData)).
// THE ARTY CALCULATOR, the player's own (user, 2026-10-25: "features can be
// toggled in real time through mod settings").
[
    QGVAR(artyMrsi), "CHECKBOX",
    ["ARTY: MRSI solutions", "The calculator lists up to three solutions from one gun, with the delay to fire each, so the rounds land together."],
    ["JMSB - Tablet & Map", "ARTY Calculator"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(artyMrsiGap), "SLIDER",
    ["ARTY: MRSI reload gap (s)", "Two MRSI solutions are offered only when their times of flight differ by at least this - the time your crew needs to reload and re-lay."],
    ["JMSB - Tablet & Map", "ARTY Calculator"],
    [2, 30, 6, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(artyGunRange), "SLIDER",
    ["ARTY: gun search range (m)", "Not in a gun, the calculator solves for the nearest artillery piece within this distance."],
    ["JMSB - Tablet & Map", "ARTY Calculator"],
    [10, 500, 100, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(tileLayout), "EDITBOX",
    ["Live tile layout", "Tile id to slot number or off, comma separated - drones:1,jam:off. Set it from the tablet: SETTINGS > LIVE TILES. Tiles not named show in the default order."],
    ["JMSB - Tablet & Map", "Tacpad"],
    "",
    false
] call CBA_fnc_addSetting;

// The call's picture (FUNC(callFeed)): where the camera sits on the man shown,
// each 0.2 m either way of its default. This player's own picture only.
[
    QGVAR(callFaceDist), "SLIDER",
    ["Call picture: FACE distance (m)", "How far in front of the caller's eyes the FACE camera sits, looking back at him."],
    ["JMSB - Tablet & Map", "Call picture"],
    [CALL_CAM_FACE_DIST - CALL_CAM_NUDGE, CALL_CAM_FACE_DIST + CALL_CAM_NUDGE, CALL_CAM_FACE_DIST, 2],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(callViewAhead), "SLIDER",
    ["Call picture: VIEW offset (m)", "How far ahead of the caller's eyes the VIEW camera sits, looking where he looks. Lower puts it nearer his eyes; below 0 it can show the inside of his head."],
    ["JMSB - Tablet & Map", "Call picture"],
    [CALL_CAM_VIEW_AHEAD - CALL_CAM_NUDGE, CALL_CAM_VIEW_AHEAD + CALL_CAM_NUDGE, CALL_CAM_VIEW_AHEAD, 2],
    false
] call CBA_fnc_addSetting;
