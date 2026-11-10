#include "script_component.hpp"
/*
 * Author: YonV
 * The server side of an accepted order, reached by remoteExec from
 * FUNC(task). It takes the requester from the sending machine
 * (FUNC(requester)) and runs FUNC(check) again for him - side, availability
 * (a second caller may have got there first), target, range - building the
 * options from the parameter array here rather than taking the client's
 * (review S6). Then it opens a new mission (FUNC(openMission)) and hands it
 * to the asset's own fire code, which acknowledges it to the requester. The
 * next call on an adjust mission the battery holds for the requester goes on
 * that mission instead (FUNC(adjustFor), FUNC(adjustNext)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: The support page's parameter array <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [1000, 2000, 0], []] remoteExecCall ["jmfsb_support_fires_fnc_request", 2]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_target", [], [[]]], ["_prm", [], [[]]]];

if (!isServer || {isNull _logic}) exitWith {};

private _requester = [_logic] call FUNC(requester);
if (isNull _requester) exitWith {};

private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];

([_logic, "", _target, _prm, _requester] call FUNC(check)) params ["_ok", "_why", "_at", "_opts"];
if (!_ok) exitWith {
    INFO_2("request: refused for %1 - %2",_requester,_why);
    [_assetId, false, _why, _requester] call EFUNC(support,ack);
};

// ADJUST FIRE (2026-11-01): the observer's next call on the mission the
// battery holds for him goes on that mission, not a new one.
([_logic, _requester, _prm] call FUNC(adjustFor)) params ["_held", "", "_call"];
if (_held isEqualTo ADJ_STATE_HELD) exitWith {
    [_logic, _at, _opts, _call, _requester, _assetId] call FUNC(adjustNext);
};

private _token = [_logic] call FUNC(openMission);

private _fire = switch (_logic getVariable [QGVAR(type), ""]) do {
    case TYPE_ARTY: {FUNC(fireMission)};
    case TYPE_CRUISE: {FUNC(launchCruise)};
    case TYPE_LOITER: {FUNC(launchLoiter)};
    default {{}};
};

[_logic, _at, _opts, _requester, _token, _assetId] call _fire;
