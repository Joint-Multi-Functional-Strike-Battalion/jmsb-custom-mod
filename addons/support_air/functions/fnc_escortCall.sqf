#include "script_component.hpp"
/*
 * Author: YonV
 * Server: ESCORT pressed in a transport's thread (user, 2026-11-09: "make sure
 * there is a way to call in escorts to all transports no mater the phase or
 * tasking"). Shared by every provider that flies a transport - this addon's
 * Transport and QRF lifts, support_logistics' aircraft, the jumpmaster's -
 * from its "reply" hook on the word "escort" (the support core's ESCORT
 * card), whatever the job is doing:
 *
 *   the aircraft is up   its drone escorts launch now (FUNC(escortLaunch),
 *                        called for: a helicopter's whatever its LZ security)
 *                        - ESCORTS LAUNCHING; escorts already with it -
 *                        ESCORTS ALREADY UP
 *   not made yet         (virtual until tasked, or between sorties) the next
 *                        launch takes them (GVAR(escortWanted)) - ESCORTS
 *                        WILL LAUNCH WITH THE AIRCRAFT
 *   no escort class      a helicopter whose module names no rotary escort
 *                        class - UNABLE - NO ESCORT CLASS SET ON THE MODULE
 *
 * Said in the thread as the asset (EFUNC(support,threadEvent)).
 *
 * Arguments:
 * 0: The module logic - its escortPlane / escortHeli attributes <OBJECT>
 * 1: The aircraft, objNull when not made <OBJECT>
 * 2: The task point, [] for none <ARRAY>
 * 3: Asset id <STRING>
 * 4: The players' side <SIDE>
 * 5: Thread id <STRING>
 * 6: Call sign <STRING>
 *
 * Return Value:
 * Escorts up or due <BOOL>
 *
 * Example:
 * [_logic, _veh, _lz, "air:1", west, "T0042", "RAVEN"] call jmfsb_support_air_fnc_escortCall
 *
 * Public: Yes
 */

params [
    ["_logic", objNull, [objNull]],
    ["_lead", objNull, [objNull]],
    ["_point", [], [[]]],
    ["_assetId", "", [""]],
    ["_side", west, [west]],
    ["_threadId", "", [""]],
    ["_callsign", "", [""]]
];

if (!isServer || {isNull _logic}) exitWith {false};
if (isRemoteExecuted) exitWith {
    WARNING_1("escortCall: refused - remote call from machine %1",remoteExecutedOwner);
    false
};

private _fnc_say = {
    params ["_line"];
    if (_threadId isEqualTo "") exitWith {};
    [_assetId, _threadId, _line, false, _callsign] call EFUNC(support,threadEvent);
};

if (!alive _lead) exitWith {
    _logic setVariable [QGVAR(escortWanted), true];
    INFO_1("%1: escort called before the aircraft is up - it launches with it",_assetId);
    [ESCORT_SAID_LATER] call _fnc_say;
    true
};

if (((_lead getVariable [QEGVAR(support,escorts), []]) select {alive _x}) isNotEqualTo []) exitWith {
    [ESCORT_SAID_ALREADY] call _fnc_say;
    true
};

private _up = [_logic, _lead, _point, _assetId, _side, true] call FUNC(escortLaunch);
INFO_2("%1: escort called - %2",_assetId,[ARR_2("no escort class","launching")] select _up);
[[ESCORT_SAID_NONE, ESCORT_SAID_UP] select _up] call _fnc_say;
_up
