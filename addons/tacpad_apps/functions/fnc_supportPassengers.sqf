#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT's PASSENGERS group for a transport: who is riding, one row
 * per group, with the seats that group fills.
 *
 * THE HANDOFF LISTS ASSIGNED FIRETEAMS, AND NOTHING IN THE MOD ASSIGNS ONE.
 * There is no manifest - no adapter field, no variable, no module - that says
 * "ALPHA rides RAPS ONE". So this shows what is true instead: the airframe's
 * cargo seats and who is sitting in them now, grouped by their group, and the
 * group label says so in as many words. When an assignment exists, it is the
 * rows that change, not the screen.
 *
 * Arguments:
 * 0: Parent controls group <CONTROL>
 * 1: Top edge <NUMBER>
 * 2: Width <NUMBER>
 * 3: The transport <OBJECT>
 * 4: Most rows that fit <NUMBER>
 *
 * Return Value:
 * Bottom edge of the group <NUMBER>
 *
 * Example:
 * _y = [_body, _y, _fw, _veh, 6] call jmfsb_tacpad_apps_fnc_supportPassengers
 *
 * Public: No
 */

// Names run long and the seat count is two digits at most.
#define PASSENGER_SPLIT 0.88

params [
    ["_parent", controlNull, [controlNull]],
    ["_y", 0, [0]],
    ["_w", 0, [0]],
    ["_veh", objNull, [objNull]],
    ["_maxRows", 1, [0]]
];

if (isNull _parent) exitWith {_y};

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * SUP_UNIT_H;

if (isNull _veh) exitWith {
    _y = [_parent, _y, _w, "PASSENGERS", "This provider does not say which airframe it is"] call FUNC(supportGroup);
    [_parent, [0, _y, _w, _rowH], "NO SEAT DATA", "", "off"] call FUNC(supportCell);
    _y + _rowH
};

private _seats = fullCrew [_veh, "cargo", true];
private _aboard = (_seats apply {_x select 0}) select {!isNull _x};

// One row per group, in the order they boarded.
private _teams = [];
{
    private _grp = group _x;
    private _i = _teams findIf {(_x select 0) isEqualTo _grp};
    if (_i < 0) then {
        _teams pushBack [_grp, [_x]];
    } else {
        ((_teams select _i) select 1) pushBack _x;
    };
} forEach _aboard;

_y = [
    _parent, _y, _w, "PASSENGERS",
    format ["%1 of %2 cargo seats filled - aboard now, no team assignment", count _aboard, count _seats]
] call FUNC(supportGroup);

if (_teams isEqualTo []) exitWith {
    [_parent, [0, _y, _w, _rowH], "NO ONE ABOARD", "", "off"] call FUNC(supportCell);
    _y + _rowH
};

private _fit = (floor _maxRows) max 1;
private _shown = _teams select [0, [_fit, _fit - 1] select (count _teams > _fit)];

{
    _x params ["_grp", "_men"];
    [
        _parent, [0, _y, _w, _rowH],
        format ["%1 · %2 — %3", _forEachIndex + 1, toUpper groupId _grp, (_men apply {name _x}) joinString ", "],
        str count _men, "rest", {}, [], PASSENGER_SPLIT
    ] call FUNC(supportCell);
    _y = _y + _rowH;
} forEach _shown;

if (count _shown < count _teams) then {
    private _rest = _teams select [count _shown];
    private _men = 0;
    {_men = _men + count (_x select 1)} forEach _rest;
    [_parent, [0, _y, _w, _rowH], format ["+%1 MORE GROUPS", count _rest], str _men, "rest", {}, [], PASSENGER_SPLIT] call FUNC(supportCell);
    _y = _y + _rowH;
};

_y
