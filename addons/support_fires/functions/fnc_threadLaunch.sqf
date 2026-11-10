#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a cruise missile or loitering munition launcher tasked by a call for
 * fire launches (2026-11-01) - the first time from FUNC(threadStrike) or at
 * the observer's CONFIRM, again at his REPEAT (FUNC(threadReply), through
 * FUNC(threadFire)). The board's own launch code does it (FUNC(launchCruise),
 * FUNC(launchLoiter)) on the mission FUNC(threadStrike) opened.
 *
 * Laid (nothing launched yet): on the wait FUNC(threadStrike) worked out - its
 * TIME ON TARGET, an immediate suppression, AT MY COMMAND's least response
 * time. Held after a launch: at the launcher's quickest. The count is the
 * card's, up to what is left; nothing left, or the point out of reach now,
 * stands it down (FUNC(threadEnd)).
 *
 * SHOT as each launch leaves, SPLASH SPLASH_LEAD s before a missile lands
 * (FUNC(flyCruise), FUNC(loiterOne)); once the last one is gone, the BDA
 * prompt (FUNC(sortieDone)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Who called it, objNull for the issuer <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _observer] call jmfsb_support_fires_fnc_threadLaunch
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_who", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};

private _order = _logic getVariable [QGVAR(threadOrder), createHashMap];
if (count _order isEqualTo 0) exitWith {};
private _target = _order getOrDefault ["target", []];
if (_target isEqualTo []) exitWith {};
if (isNull _who) then {_who = _order getOrDefault ["issuer", objNull]};

private _laid = (_logic getVariable [QGVAR(status), ""]) isEqualTo STATUS_LAID;
private _cannot = [format ["%1 - %2", WHY_NO_STORES, SAID_EOM], SAID_CANNOT_FIRE] select _laid;

private _count = (_order getOrDefault ["count", 1]) min (_logic getVariable [QGVAR(left), 0]);
if (_count < 1) exitWith {[_logic, _cannot] call FUNC(threadEnd)};
if (([_logic, _target] call FUNC(inRange)) isNotEqualTo "") exitWith {[_logic, SAID_CANNOT_FIRE] call FUNC(threadEnd)};

(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0]];
private _wait = [_respMin, _order getOrDefault ["wait", _respMin]] select _laid;

private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
private _token = _logic getVariable [QGVAR(token), -1];

if ((_logic getVariable [QGVAR(type), ""]) isEqualTo TYPE_CRUISE) exitWith {
    [_logic, _target, [_count, 0], _who, _token, _assetId, _wait] call FUNC(launchCruise);
};
[_logic, _target, [_count, _order getOrDefault ["radius", SEARCH_MIN]], _who, _token, _assetId] call FUNC(launchLoiter);
