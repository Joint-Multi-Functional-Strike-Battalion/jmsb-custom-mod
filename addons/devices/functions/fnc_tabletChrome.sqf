#include "script_component.hpp"
/*
 * Author: JMSB
 * Builds the tablet screen's own rows round the map area - the device bar, the
 * notification line, the live tiles and the rule under them, the net row - and
 * the border round the map area, the recess round the whole screen (dark,
 * with a light rim - fixed colours, not the scheme's: it is part of the
 * device, like the frame), the who-is-talking chip over the map area, and
 * starts the tick that keeps them current (FUNC(tabletTick)).
 *
 * THE RECESS IS EIGHT THIN GROUPS, the four bands and their rims, never one
 * group over the screen, for the reason below.
 *
 * ONE CONTROLS GROUP PER ROW, never one over the whole screen: a group takes
 * the mouse over all of its rectangle, and one the size of the screen would
 * sit on the map and every panel under it. Each row is a ground, solid in the
 * scheme's token, and a body the row's drawing goes into; a redraw empties
 * the body and leaves the ground.
 *
 * Arguments:
 * 0: The tablet dialog <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_devices_fnc_tabletChrome
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {};

private _rows = _display getVariable [QGVAR(rows), createHashMap];
if (count _rows == 0) exitWith {};

private _bodies = createHashMap;
private _fills = [];
{
    _x params ["_row", "_token", "_drawn"];
    (_rows get _row) params ["_rx", "_ry", "_rw", "_rh"];

    private _group = _display ctrlCreate [QEGVAR(tacpad,panel), -1];
    _group ctrlSetPosition [_rx, _ry, _rw, _rh];
    _group ctrlCommit 0;

    private _colour = +([_token] call EFUNC(tacpad,theme));
    _colour set [3, 1];
    private _fill = [_group, [0, 0, _rw, _rh], _colour] call EFUNC(tacpad,drawFill);
    _fills pushBack [_fill, _token];

    if (_drawn) then {
        private _body = _display ctrlCreate [QEGVAR(tacpad,bodyPlain), -1, _group];
        _body ctrlSetPosition [0, 0, _rw, _rh];
        _body ctrlCommit 0;
        _bodies set [_row, _body];
    };
} forEach [
    ["bar", "ink", true],
    ["notify", "surface", true],
    ["tiles", "ground", true],
    ["rule", "ink", false],
    ["nets", "ink", true],
    ["borderL", "ink", false],
    ["borderR", "ink", false],
    ["borderB", "ink", false]
];

// THE RECESS round the screen: dark bands, no light rim (user, 2026-10-21:
// "there is a light line around the screen that needs to go away").
{
    _x params ["_row", "_colour"];
    (_rows get _row) params ["_rx", "_ry", "_rw", "_rh"];
    private _group = _display ctrlCreate [QEGVAR(tacpad,panel), -1];
    _group ctrlSetPosition [_rx, _ry, _rw, _rh];
    _group ctrlCommit 0;
    [_group, [0, 0, _rw, _rh], _colour] call EFUNC(tacpad,drawFill);
} forEach [
    ["recessT", COLOUR_RECESS],
    ["recessB", COLOUR_RECESS],
    ["recessL", COLOUR_RECESS],
    ["recessR", COLOUR_RECESS]
];
// ...and its corners, slightly round (user, 2026-10-23): a quarter-round
// piece each, dark inside the arc and clear outside it, where the frame's own
// fillet shows (tools/gen_devices.py, SCREEN_CORNER_R and the corner textures).
{
    _x params ["_row", "_texture"];
    (_rows get _row) params ["_rx", "_ry", "_rw", "_rh"];
    if (_rw <= 0 || _rh <= 0) then {continue};
    private _piece = _display ctrlCreate ["RscPicture", -1];
    _piece ctrlSetPosition [_rx, _ry, _rw, _rh];
    _piece ctrlSetText _texture;
    _piece ctrlSetTextColor COLOUR_RECESS;
    _piece ctrlCommit 0;
} forEach CORNER_PIECES;

// THE TALKING CHIP, at its fixed place in the map area - created before the
// shell builds its panels, so none of them is ever under it. Dark in every
// scheme, as the walking view's chip is: its text carries its own colours.
// Hidden until somebody talks (FUNC(tabletTalk)).
(_rows get "map") params ["_mx", "_my", "_mw", "_mh"];
TABLET_TALK params ["_cx", "_cy", "_cw", "_ch"];
private _talkRect = [_mx + _cx * _mw, _my + _cy * _mh, _cw * _mw, _ch * _mh];
private _talk = _display ctrlCreate [QEGVAR(tacpad,panel), -1];
_talk ctrlSetPosition _talkRect;
_talk ctrlCommit 0;
[_talk, [0, 0, _talkRect select 2, _talkRect select 3], COLOUR_BAR] call EFUNC(tacpad,drawFill);
private _talkBody = _display ctrlCreate [QEGVAR(tacpad,bodyPlain), -1, _talk];
_talkBody ctrlSetPosition [0, 0, _talkRect select 2, _talkRect select 3];
_talkBody ctrlCommit 0;
_talk ctrlShow false;
_bodies set ["talk", _talkBody];

_display setVariable [QGVAR(rowBodies), _bodies];
_display setVariable [QGVAR(rowFills), _fills];
_display setVariable [QGVAR(rowKeys), createHashMap];

if (GVAR(tabletPFH) isNotEqualTo -1) then {
    [GVAR(tabletPFH)] call CBA_fnc_removePerFrameHandler;
};
[_display, -1] call FUNC(tabletTick);
GVAR(tabletPFH) = [{
    params ["_display", "_handle"];
    [_display, _handle] call FUNC(tabletTick);
}, TABLET_TICK, _display] call CBA_fnc_addPerFrameHandler;
