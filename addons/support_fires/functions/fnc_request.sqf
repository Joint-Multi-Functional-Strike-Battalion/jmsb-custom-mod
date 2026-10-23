#include "script_component.hpp"
/*
 * Author: JMSB
 * The server side of an accepted order: re-checks the asset (a second caller
 * may have got there first), opens a new mission (FUNC(openMission)) and
 * hands it to the asset's own fire code, which acknowledges it to the
 * requester.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: Options, as FUNC(task) built them for the type <ARRAY>
 * 3: Requester <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, [1000, 2000, 0], ["he", 2, 50, 0, "HE", 0, 0, 0, 0, 0], player] call jmfsb_support_fires_fnc_request
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_target", [], [[]]], ["_opts", [], [[]]], ["_requester", objNull, [objNull]]];

if (!isServer || {isNull _logic} || {_target isEqualTo []}) exitWith {};

private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {
    [_assetId, false, _why, _requester] call EFUNC(support,ack);
};

private _token = [_logic] call FUNC(openMission);

private _fire = switch (_logic getVariable [QGVAR(type), ""]) do {
    case TYPE_ARTY: {FUNC(fireMission)};
    case TYPE_CRUISE: {FUNC(launchCruise)};
    case TYPE_LOITER: {FUNC(launchLoiter)};
    default {{}};
};

[_logic, _target, _opts, _requester, _token, _assetId] call _fire;
