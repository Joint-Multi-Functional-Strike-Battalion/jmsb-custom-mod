#include "script_component.hpp"
/*
 * Author: JMSB
 * What the picked air asset draws on the support board's map - the "overlay"
 * code of provider "air" (support core README), in ink under the request.
 * Read only from what the server published on the module.
 *
 * ALWAYS its base: the module, or the stand a synced aircraft flies from and
 * is parked back on.
 *
 * WHILE A SORTIE IS OUT, round the plan (row field 8) - which the board
 * already draws itself, as markers joined from the airframe, so this adds
 * only what that does not show:
 *   - the leg out from base while there is no airframe yet (launching)
 *   - the leg home from the plan's last point, until it is being flown
 *   - CAS: the INGRESS and EGRESS legs from the task point, and round it the
 *     module's Friendly Range - the ring a release is held inside unless
 *     DANGER CLOSE was asked - when that range is above 0
 *
 * A CLASS CAS aircraft never flies from or to the module: it appears on its
 * ingress bearing and leaves by its exit (FUNC(casLaunch)), so it gets no leg
 * out or home.
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: The asset's row <ARRAY>
 *
 * Return Value:
 * Shapes, ["ring", centre, radius, label] / ["line", from, to, label] /
 * ["point", at, label] <ARRAY>
 *
 * Example:
 * ["air:0", _row] call jmfsb_support_air_fnc_overlay
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_row", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[]};

private _kind = _logic getVariable [QGVAR(kind), ""];
private _stand = _logic getVariable [QGVAR(hadSynced), false];
private _home = _logic getVariable [QGVAR(home), getPosATL _logic];

private _shapes = [["point", _home, format ["%1 %2", _logic getVariable [QGVAR(callsign), _row param [2, "AIR"]], ["BASE", "STAND"] select _stand]]];

private _plan = (_logic getVariable [QGVAR(plan), []]) select {((_x param [0, []]) param [0, ""]) isEqualType 0};
if (_plan isEqualTo []) exitWith {_shapes};

private _viaBase = _stand || _kind isNotEqualTo KIND_CAS;
if (_viaBase && !alive (_logic getVariable [QGVAR(vehicle), objNull])) then {
    _shapes pushBack ["line", _home, (_plan select 0) select 0, ""];
};
private _last = _plan select -1;
if (_viaBase && !((_last param [1, ""]) in [PLAN_BASE, PLAN_EGRESS])) then {
    _shapes pushBack ["line", _last select 0, _home, ""];
};

if (_kind isNotEqualTo KIND_CAS) exitWith {_shapes};

private _at = _plan findIf {!((_x param [1, ""]) in [PLAN_IN, PLAN_OUT, PLAN_BASE, PLAN_EGRESS])};
if (_at < 0) exitWith {_shapes};
(_plan select _at) params ["_pos", "_what"];

{
    _x params ["_label", "_name"];
    private _leg = _plan findIf {(_x param [1, ""]) isEqualTo _label};
    if (_leg > -1) then {_shapes pushBack ["line", _pos, (_plan select _leg) select 0, _name]};
} forEach [[PLAN_IN, "INGRESS"], [PLAN_OUT, "EGRESS"]];

// A LOITER is weapons tight: nothing is released, nothing is held.
private _range = _logic getVariable [QGVAR(friendlyRange), 0];
if (_range > 0 && _what isNotEqualTo TASK_LOITER) then {
    _shapes pushBack ["ring", _pos, _range, format ["FRIENDLY RANGE %1 M", round _range]];
};

_shapes
