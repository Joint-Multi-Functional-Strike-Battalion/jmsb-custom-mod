#include "script_component.hpp"
/*
 * Author: JMSB
 * What this asset is doing, as one token - the ONLY place that question is
 * answered. The row's status, the core's "available" ask and FUNC(task)'s
 * refusal all read it, so a row that reads IDLE is never an order refused.
 *
 * EXPENDED IS A STATE, NOT A DISAPPEARANCE. An asset out of rounds stays on
 * the page saying so.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * 0: Can be tasked right now <BOOL>
 * 1: Status token <STRING>
 * 2: Why not, "" when it can <STRING>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_available
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[false, "gone", "that asset is gone"]};

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
private _status = _logic getVariable [QGVAR(status), STATUS_IDLE];

if (_status isNotEqualTo STATUS_IDLE) exitWith {
    [false, _status, format ["%1 is already on a mission", _callsign]]
};

if (([_logic] call FUNC(ordnance)) isEqualTo []) exitWith {
    [false, STATUS_EXPENDED, format ["%1 has nothing left to fire", _callsign]]
};

private _readyAt = _logic getVariable [QGVAR(readyAt), 0];
if (CBA_missionTime < _readyAt) exitWith {
    [false, STATUS_COOLDOWN, format ["%1 is rearming - %2s", _callsign, ceil (_readyAt - CBA_missionTime)]]
};

[true, STATUS_IDLE, ""]
