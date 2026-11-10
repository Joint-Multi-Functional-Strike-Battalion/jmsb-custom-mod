#include "script_component.hpp"
/*
 * Author: YonV
 * What the picked logistics asset draws on the support board's map - the
 * "overlay" code of provider "logi" (support core README), in ink under the
 * request. Read only from what the server published on the module.
 *
 * ALWAYS its base - the module, where its aircraft are made when tasked and
 * removed when home (user, 2026-11-02: virtual until tasked). WHILE A
 * DELIVERY IS LAUNCHING, before any aircraft is on the map, the leg in from
 * the module; once one is flying the board draws the plan from the airframe
 * itself (row field 8).
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 * 1: The asset's row <ARRAY>
 *
 * Return Value:
 * Shapes, ["line", from, to, label] / ["point", at, label] <ARRAY>
 *
 * Example:
 * ["logi:0", _row] call jmfsb_support_logistics_fnc_overlay
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_row", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[]};

private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _shapes = [["point", _home, format ["%1 BASE", _logic getVariable [QGVAR(callsign), _row param [2, DEF_CALLSIGN]]]]];

private _plan = _logic getVariable [QGVAR(plan), []];
if (_plan isEqualTo [] || alive (_logic getVariable [QGVAR(vehicle), objNull])) exitWith {_shapes};

(_plan select 0) params [["_pos", [], [[]]]];
if (count _pos < 2) exitWith {_shapes};
_shapes pushBack ["line", _home, _pos, "IN"];

_shapes
