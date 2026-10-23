// CBA Settings [ADDON: jmfsb_hud]
//
// DELIBERATELY SHORT. Where the two slots sit is the Layout editor's business -
// Options > Game > Layout, see gui.hpp - and what they are painted in is the
// tacpad's scheme. Neither belongs here.

[
    QGVAR(enabled), "CHECKBOX",
    ["Enable HUD", "Draws the two readout slots on the game screen. Off leaves the screen exactly as it was; the map suite is unaffected either way."],
    ["1st Joint Multi-Functional Strike Battalion", "HUD"],
    true,
    false,
    {[QGVAR(enabled_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

// A HUD IS FOR WHEN YOU CANNOT OPEN THE MAP. With the map open the same readings
// are on the tacpad in more detail, and two copies of the squad list on one
// screen is one too many.
[
    QGVAR(hideOnMap), "CHECKBOX",
    ["Hide with the map", "Takes the HUD off screen while the map is open, where the tacpad shows the same readings in more detail. Off leaves it up, over the map."],
    ["1st Joint Multi-Functional Strike Battalion", "HUD"],
    true,
    false
] call CBA_fnc_addSetting;

// OFF BY DEFAULT IN TABLET MODE. The devices carry the same readouts as their
// own status row, so with the tacpad on a device the HUD is a second copy on
// the game screen. The player can have it back; the default is the device.
// Read alongside jmfsb_tacpad_displayMode in FUNC(open).
[
    QGVAR(showInTablet), "CHECKBOX",
    ["Show in tablet mode", "Keeps the HUD slots on the game screen when the tacpad display mode is TABLET. Off by default there: the device shows the same readouts."],
    ["1st Joint Multi-Functional Strike Battalion", "HUD"],
    false,
    false,
    {[QGVAR(enabled_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

[
    QGVAR(opacity), "SLIDER",
    ["HUD opacity", "How solid the slot backgrounds are over the world. The text stays fully opaque at any setting."],
    ["1st Joint Multi-Functional Strike Battalion", "HUD"],
    [0, 1, 0.55, 2, true],
    false,
    {[QGVAR(enabled_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;
