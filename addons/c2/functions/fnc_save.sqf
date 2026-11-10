#include "script_component.hpp"
/*
 * Author: YonV
 * Saves a C2 measure (design c2_app flow: pick type -> draw on map -> name ->
 * save). Server only, raised by the leader's tablet. A line needs two points,
 * an area three, a point one (the last drawn); the name is required. The
 * measure is the side's, published to every client (FUNC(publish)).
 *
 *     measure: [id, type, name, points, creator uid, creator name, group id, side, created]
 *
 * Arguments:
 * 0: Type id <STRING>
 * 1: Name <STRING>
 * 2: Points [[x, y, z], ...] <ARRAY>
 * 3: The leader <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["phase_line", "BLUE", _points, player] call jmfsb_c2_fnc_save
 *
 * Public: No
 */

params [["_type", "", [""]], ["_name", "", [""]], ["_points", [], [[]]], ["_who", objNull, [objNull]]];

if (!isServer || {!([_who] call FUNC(canEdit))}) exitWith {};
([_type] call FUNC(typeOf)) params [["_id", ""], "", ["_kind", ""]];
if (_id isEqualTo "" || {(_name trim [" ", 0]) isEqualTo ""}) exitWith {};
private _need = createHashMapFromArray [["line", 2], ["area", 3], ["point", 1]];
if (count _points < (_need getOrDefault [_kind, 1])) exitWith {};
if (_kind isEqualTo "point") then {_points = [_points select -1]};

GVAR(serial) = GVAR(serial) + 1;
private _mid = format ["M%1", GVAR(serial)];
GVAR(measures) set [_mid, [_mid, _type, toUpper (_name trim [" ", 0]), _points apply {[_x # 0, _x # 1, 0]},
    getPlayerUID _who, name _who, groupId group _who, side group _who, serverTime]];
[] call FUNC(publish);
INFO_3("c2: %1 saved %2 %3",name _who,_type,_name);
