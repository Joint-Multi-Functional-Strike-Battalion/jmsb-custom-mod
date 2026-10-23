#include "script_component.hpp"
/*
 * Author: JMSB
 * What the picked CAS drone draws on the support board's map - the "overlay"
 * code of provider "cas" (support core README), in ink under the request.
 *
 * A DRONE HAS NO HOME. It appears on its ingress bearing at the module's
 * spawn distance from the target and leaves off the map edge (FUNC(request),
 * FUNC(egress)), so an idle drone draws nothing; the request's own INGRESS
 * and EGRESS rows are drawn by the board.
 *
 * WHILE A RUN IS OUT, from the plan the server published (row field 8, which
 * the board already draws as markers joined from the airframe):
 *   - the INGRESS and EGRESS legs, from the task point to the IN and OUT
 *     points, when the run was given them
 *   - round the task point, the search radius a strike looks for a laser or
 *     smoke in (FUNC(acquire)), or the orbit a loiter holds
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 * 1: The asset's row <ARRAY>
 *
 * Return Value:
 * Shapes, ["ring", centre, radius, label] / ["line", from, to, label] <ARRAY>
 *
 * Example:
 * ["cas:0", _row] call jmfsb_cas_fnc_overlay
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_row", [], [[]]]];

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {[]};

private _plan = _logic getVariable [QGVAR(plan), []];
private _at = _plan findIf {!((_x param [1, ""]) in [PLAN_IN, PLAN_OUT])};
if (_at < 0) exitWith {[]};
(_plan select _at) params ["_pos", "_what"];

private _shapes = [];
{
    _x params ["_p", "_label"];
    if ((_p param [0, ""]) isEqualType 0) then {_shapes pushBack ["line", _pos, _p, _label]};
} forEach [
    [(_plan select {(_x param [1, ""]) isEqualTo PLAN_IN}) param [0, []] param [0, []], "INGRESS"],
    [(_plan select {(_x param [1, ""]) isEqualTo PLAN_OUT}) param [0, []] param [0, []], "EGRESS"]
];

if (_what isEqualTo "LOITER") then {
    _shapes pushBack ["ring", _pos, CAS_LOITER_RADIUS, format ["ORBIT %1 M", CAS_LOITER_RADIUS]];
} else {
    private _search = _logic getVariable [QGVAR(searchRadius), 300];
    if (_search > 0) then {_shapes pushBack ["ring", _pos, _search, format ["SEARCH %1 M", round _search]]};
};

_shapes
