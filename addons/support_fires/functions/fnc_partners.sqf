#include "script_component.hpp"
/*
 * Author: JMSB
 * The batteries that can join a coordinated fire mission - Simplex's
 * coordination: other batteries near the one tasked, carrying the same round,
 * free, and in range of the target.
 *
 * A partner is another artillery asset of the same side whose battery stands
 * within the tasked battery's Coordination Distance, that has a Coordination
 * Distance of its own (0 keeps a battery out of every coordinated mission),
 * reads idle (FUNC(available)), still carries the same shell class, and
 * reaches the target (FUNC(inRange)).
 *
 * Given no target, the range and availability tests are skipped: the support
 * page asks only whether a COORDINATE stepper is worth offering.
 *
 * Arguments:
 * 0: The tasked battery's module logic <OBJECT>
 * 1: Shell class, "" for any <STRING>
 * 2: Target position, [] for none <ARRAY>
 *
 * Return Value:
 * Partner module logics, nearest first <ARRAY>
 *
 * Example:
 * [_logic, "Sh_155mm_AMOS", _target] call jmfsb_support_fires_fnc_partners
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_cls", "", [""]], ["_target", [], [[]]]];

private _reach = _logic getVariable [QGVAR(coordination), 0];
if (isNull _logic || _reach <= 0) exitWith {[]};

private _origin = _logic getVariable [QGVAR(origin), getPosATL _logic];
private _side = _logic getVariable [QGVAR(side), sideUnknown];

private _found = GVAR(entities) select {
    !isNull _x
    && _x isNotEqualTo _logic
    && {(_x getVariable [QGVAR(type), ""]) isEqualTo TYPE_ARTY}
    && {(_x getVariable [QGVAR(side), sideUnknown]) isEqualTo _side}
    && {(_x getVariable [QGVAR(coordination), 0]) > 0}
    && {((_x getVariable [QGVAR(origin), getPosATL _x]) distance2D _origin) <= _reach}
    && {_cls isEqualTo "" || {((_x getVariable [QGVAR(stock), []]) findIf {(_x select 2) == _cls && {(_x select 1) isNotEqualTo 0}}) > -1}}
    && {_target isEqualTo [] || {([_x] call FUNC(available)) select 0 && {([_x, _target] call FUNC(inRange)) isEqualTo ""}}}
};

// Sorted on [distance, index]: an object is not sortable, and two batteries
// at the same spot would compare their second elements.
private _byDistance = [];
{
    _byDistance pushBack [(_x getVariable [QGVAR(origin), getPosATL _x]) distance2D _origin, _forEachIndex];
} forEach _found;
_byDistance sort true;
_byDistance apply {_found select (_x select 1)}
