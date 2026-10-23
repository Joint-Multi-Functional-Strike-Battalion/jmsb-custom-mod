#include "script_component.hpp"
/*
 * Author: JMSB
 * Shrinks a panel to the content it just drew.
 *
 * Panels used to be fixed-size boxes from their defaults, so a squad of one got
 * a half-screen rail and an empty reader was a wall of white over the map. A
 * panel now says how many rows it used and the frame closes up to fit.
 *
 * The placed WIDTH is kept - width is part of where a panel was put, height is
 * a consequence of the content.
 *
 * Arguments:
 * 0: Panel id <STRING>
 * 1: Rows used <NUMBER>
 * 2: Extra height beyond the rows, in safe-zone fractions <NUMBER> (optional, default 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["squad", 12] call jmfsb_tacpad_fnc_fit
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_rows", 0, [0]], ["_extra", 0, [0]]];

private _entry = GVAR(open) getOrDefault [_id, []];
if (_entry isEqualTo []) exitWith {};
_entry params ["_group", "_body"];
if (isNull _group || {isNull _body}) exitWith {};

private _panel = GVAR(panels) get _id;
if (isNil "_panel") exitWith {};
private _slot = _panel get "slot";

private _scale = GVAR(textScale) * GVAR(uiScale);
private _rowH = ROW_H * _scale * HOST_H;
private _bx = RULE_THICK * pixelW;
private _by = RULE_THICK * pixelH;

// A CHROMELESS PANEL RESERVES NEITHER. It has no title bar and no rule under
// one - see FUNC(build) - so counting them here would leave a strip a header
// taller than its own contents, with the gap at the bottom.
private _chrome = _panel getOrDefault ["chrome", true];
private _headerH = [0, HEADER_H * _scale * HOST_H] select _chrome;
private _ruleH = [0, RULE_THICK * pixelH] select _chrome;

private _gp = ctrlPosition _group;
_gp params ["_x", "_y", "_w"];

// A panel that supplies its own height needs no floor row; one that does not
// gets a single row, so an empty panel is still a labelled strip you can find
// rather than a sliver.
private _floor = parseNumber (_extra <= 0);
private _bodyH = ((_rows max _floor) * _rowH) + (_extra * HOST_H);
private _h = _bodyH + _headerH + _ruleH + 2 * _by;

// THE FLOOR A PANEL MAY GROW TO. The bottom of the safe zone, and - unless the
// player has switched the reserved areas off - the top of any of them this panel
// would grow down into.
//
// GROWING WAS NEVER CHECKED AGAINST THEM. FUNC(place) pushes a panel clear of
// the chat overlay when it is DROPPED, and then this function grew it straight
// back down over the chat: a sixteen-row roster starting at 0.20 ends at 0.87,
// and the chat overlay starts at 0.80. Covering a player's only text channel is
// exactly the failure the zones are declared for, so the clamp reads them too.
private _bottom = HOST_Y + HOST_H;

if (GVAR(respectZones) && HOST_NATIVE) then {
    private _left = _x;
    private _right = _x + _w;

    {
        _x params ["_zx", "_zy", "_zw", "_zh"];

        private _zLeft = HOST_X + _zx * HOST_W;
        private _zRight = _zLeft + _zw * HOST_W;
        private _zTop = HOST_Y + _zy * HOST_H;

        // Only a zone this panel is over, and only one it is above: a panel
        // already sitting inside a zone is the player's business - see
        // FUNC(place) - and shrinking it to nothing would not get it out.
        if (_left >= _zRight || _right <= _zLeft || _zTop <= _y) then {continue};

        _bottom = _bottom min _zTop;
    } forEach [ZONE_CHAT, ZONE_LEGEND];
};

private _maxH = _bottom - _y;
if (_h > _maxH) then {
    _h = _maxH;
    _bodyH = _h - _headerH - _ruleH - 2 * _by;
};

_group ctrlSetPosition [_x, _y, _w, _h];
_group ctrlCommit 0;

// The ground fills the group; the outline's four edges are re-laid around it.
// Both are addressed directly rather than by counting children - the frame is
// four controls now, and "the first two" was never a safe way to find anything.
private _fill = _group controlsGroupCtrl IDC_GROUND(_slot);
if (!isNull _fill) then {
    _fill ctrlSetPosition [0, 0, _w, _h];
    _fill ctrlCommit 0;
};

(_group getVariable [QGVAR(frame), []]) params [["_top", controlNull], ["_bottom", controlNull], ["_left", controlNull], ["_right", controlNull]];
{
    _x params ["_ctrl", "_edge"];
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetPosition _edge;
    _ctrl ctrlCommit 0;
} forEach [
    [_top, [0, 0, _w, _by]],
    [_bottom, [0, _h - _by, _w, _by]],
    [_left, [0, 0, _bx, _h]],
    [_right, [_w - _bx, 0, _bx, _h]]
];

_body ctrlSetPosition [_bx, _by + _headerH + _ruleH, _w - 2 * _bx, _bodyH];
_body ctrlCommit 0;
