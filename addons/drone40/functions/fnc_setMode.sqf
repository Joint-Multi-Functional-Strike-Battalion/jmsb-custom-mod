#include "script_component.hpp"
/*
 * Author: JMSB
 * Switches a Drone40 variant between relay, decoy, jammer and off - whatever
 * round it came from. Server-authoritative: anywhere else the call is sent to
 * the server (remoteExecCall, see below) and answers true for "sent". There the
 * drone's node is taken down (FUNC(remove): its RF node, or a jammer's EW
 * emitter), its mode is set public on the drone (GVAR(mode)), and unless the
 * mode is off it is registered again exactly as a fresh launch is
 * (FUNC(deploy)), with the launcher it was launched by.
 *
 * WHO MAY SWITCH IT IS CHECKED ON THE SERVER TOO (2026-10-20). A client's call
 * arrives by remoteExecCall carrying the caller; the server refuses it unless
 * the caller is the machine that sent it (remoteExecutedOwner) and passes the
 * same test as CONNECT (jmfsb_devices_fnc_uavCan, without the DATA link,
 * which only the client can measure). A call made on the server itself - the
 * mod's own code - is trusted.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Mode - "relay", "decoy", "jammer" or "off" <STRING>
 * 2: Caller, set by the client side of this function <OBJECT> (optional, default objNull)
 *
 * Return Value:
 * Switched (sent, off the server) <BOOL>
 *
 * Example:
 * [_drone, "jammer"] call jmfsb_drone40_fnc_setMode
 *
 * Public: Yes
 */

params [["_drone", objNull, [objNull]], ["_mode", "", [""]], ["_caller", objNull, [objNull]]];

if (!alive _drone || !(_mode in MODES)) exitWith {false};

private _cfgRole = getText (configOf _drone >> QGVAR(role));
if !(_cfgRole in ROLES) exitWith {false};

if (!isServer) exitWith {
    [_drone, _mode, player] remoteExecCall [QFUNC(setMode), 2];
    true
};

if (isRemoteExecuted) then {
    private _may = !isNull _caller && {remoteExecutedOwner isEqualTo owner _caller}
        && {isNil QEFUNC(devices,uavCan) || {([_drone, _caller, false] call EFUNC(devices,uavCan)) select 0}};
    if (!_may) exitWith {
        WARNING_3("refused a mode switch of %1 to %2 from %3",_drone,_mode,_caller);
        _mode = "";
    };
};
if (_mode isEqualTo "") exitWith {false};

private _id = _drone getVariable [QGVAR(id), ""];
private _now = _drone getVariable [QGVAR(mode), _cfgRole];
if (_now isEqualTo _mode && (_id isNotEqualTo "") isEqualTo (_mode isNotEqualTo MODE_OFF)) exitWith {true};

if (_id isNotEqualTo "") then {
    [_id] call FUNC(remove);
    _drone setVariable [QGVAR(id), nil];
};

_drone setVariable [QGVAR(mode), _mode, true];
if (_mode isNotEqualTo MODE_OFF) then {
    [_drone, _drone getVariable [QGVAR(launcher), objNull]] call FUNC(deploy);
};
TRACE_3("mode set",_drone,_now,_mode);
true
