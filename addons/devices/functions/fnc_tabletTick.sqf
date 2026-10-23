#include "script_component.hpp"
/*
 * Author: JMSB
 * Keeps the tablet's rows current: the device bar, the notification line, the
 * net row and the who-is-talking chip whenever what they say has changed, the
 * live tiles on their own period when theirs has, every ground recoloured when
 * the scheme changes, and the right-hand column stacked from the panels' real
 * bottoms (FUNC(tabletStack)).
 *
 * DRAWN ON CHANGE, NOT ON THE TICK. A row with a button on it that is
 * redrawn every half second is a row whose button loses a press now and then
 * - a control deleted between the press and the release never raises the
 * click. Each row says what it would draw as a key; only a new key redraws it.
 *
 * THE VEHICLE TABLET IS THE VEHICLE'S. Out of the seat, it closes.
 *
 * Arguments:
 * 0: The tablet dialog <DISPLAY>
 * 1: Per-frame handler id, -1 for a direct call <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, -1] call jmfsb_devices_fnc_tabletTick
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_handle", -1, [0]]];

if (isNull _display) exitWith {
    if (_handle isNotEqualTo -1) then {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
    GVAR(tabletPFH) = -1;
};

if (GVAR(device) isEqualTo VEHICLE_DEVICE && {isNull GVAR(vehicle) || {!((call CBA_fnc_currentUnit) in crew GVAR(vehicle))}}) exitWith {
    [] call FUNC(close);
};

private _bodies = _display getVariable [QGVAR(rowBodies), createHashMap];
private _keys = _display getVariable [QGVAR(rowKeys), createHashMap];

// A NEW SCHEME OR TYPE SIZE REDRAWS EVERYTHING. The theme's whole set is its
// own key; the grounds are recoloured in place and every row forgets what it
// last drew.
private _themeKey = str [[] call EFUNC(tacpad,theme), EGVAR(tacpad,textScale), EGVAR(tacpad,uiScale)];
if (_themeKey isNotEqualTo (_keys getOrDefault ["theme", ""])) then {
    _keys set ["theme", _themeKey];
    {
        _x params ["_fill", "_token"];
        private _colour = +([_token] call EFUNC(tacpad,theme));
        _colour set [3, 1];
        _fill ctrlSetBackgroundColor _colour;
    } forEach (_display getVariable [QGVAR(rowFills), []]);
    {
        _keys deleteAt _x;
    } forEach ["bar", "notify", "nets", "talk", "tiles", "tilesDue"];
};

// RF's summary, rebuilt only after RF said a link changed - the same summary
// the walking view reads (FUNC(overlayRf)); the walking view is down while
// this dialog is up, so nothing else is keeping it.
if (GVAR(overlayRfDirty)) then {
    GVAR(overlayRfDirty) = false;
    GVAR(overlayRf) = [] call FUNC(overlayRf);
};

[_bodies getOrDefault ["bar", controlNull], _keys] call FUNC(tabletBar);
[_bodies getOrDefault ["notify", controlNull], _keys] call FUNC(tabletNotify);
[_bodies getOrDefault ["nets", controlNull], _keys] call FUNC(tabletNets);
[_bodies getOrDefault ["talk", controlNull], _keys] call FUNC(tabletTalk);

// The tiles are the shell's own band, drawn one row wide into the tile row,
// asked on the period they keep on the vanilla map - and, like every other
// row, redrawn only when what they say has changed: each redraw deletes and
// recreates every tile's button, and the row stays up while an app is open.
if (diag_tickTime >= (_keys getOrDefault ["tilesDue", 0])) then {
    _keys set ["tilesDue", diag_tickTime + TABLET_TILE_PERIOD];
    private _tilesKey = str ([] call EFUNC(tacpad_apps,tileData));
    if (_tilesKey isNotEqualTo (_keys getOrDefault ["tiles", ""])) then {
        _keys set ["tiles", _tilesKey];
        [_bodies getOrDefault ["tiles", controlNull], "", true] call EFUNC(tacpad_apps,panelTiles);
    };
};

[] call FUNC(tabletStack);
