#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT: a point picked - off the map or off a placed marker - into
 * the row that was armed. A row that takes ONE point is set; a row that
 * takes several (a transport's VIA legs, the declaration's "many") gets the
 * point added to its list, and once the list is full the last one is moved
 * instead. CLR on the row empties it (FUNC(appSupport)).
 *
 * Arguments:
 * 0: Row key - SUP_SLOT_TARGET, or a declared point's key <NUMBER>
 * 1: The point, [x, y, 0] <ARRAY>
 * 2: The marker it was taken from, "" for a map click <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [44, [1200, 3400, 0], ""] call jmfsb_tacpad_apps_fnc_supportPointSet
 *
 * Public: No
 */

params [["_key", SUP_SLOT_TARGET, [0]], ["_pos", [], [[]]], ["_name", "", [""]]];

if (_pos isEqualTo []) exitWith {};

([_key] call FUNC(supportPointVars)) params ["_pv", "_nv"];
private _many = (uiNamespace getVariable [QGVAR(supportMany), createHashMap]) getOrDefault [_key, 1];

if (_many <= 1) exitWith {
    missionNamespace setVariable [_pv, _pos];
    missionNamespace setVariable [_nv, _name];
};

private _list = missionNamespace getVariable [_pv, []];
if (_list isNotEqualTo [] && {!((_list select 0) isEqualType [])}) then {_list = []};
_list = +_list;
if (count _list >= _many) then {
    _list set [count _list - 1, _pos];
} else {
    _list pushBack _pos;
};
missionNamespace setVariable [_pv, _list];
missionNamespace setVariable [_nv, ""];
