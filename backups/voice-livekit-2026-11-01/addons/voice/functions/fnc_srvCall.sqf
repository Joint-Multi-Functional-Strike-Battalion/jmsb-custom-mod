#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a dial. CALL NEEDS REACH ON DATA: a callee the caller cannot reach
 * on DATA is refused (no route), one in another call is busy; the caller is
 * told about both, with CALL BACK offered. The rest ring, in a free slot.
 * With every slot taken, a FLASH call from an RTO, HQ or admin bumps the
 * oldest ROUTINE call: that call hears the priority warning for the bump
 * warning time, then ends, and this dial is made again (fnc_srvCallTick).
 * Otherwise the slots are busy.
 *
 * Reached by remoteExec from FUNC(call): the caller must be the sender
 * (jmfsb_common_fnc_senderIs). The server's own re-dial (FUNC(srvCallTick))
 * passes. Refusals go back by remoteExec to FUNC(callFailed).
 *
 * Arguments:
 * 0: Call id <STRING>
 * 1: Caller <OBJECT>
 * 2: Callees <ARRAY of OBJECTs>
 * 3: Priority "ROUTINE" | "FLASH" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["123_1", player, [_unit], "ROUTINE"] remoteExecCall ["jmfsb_voice_fnc_srvCall", 2]
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_caller", objNull, [objNull]], ["_units", [], [[]]], ["_priority", PRIO_ROUTINE, [""]]];

if (!isServer || {!([_caller] call EFUNC(common,senderIs))}) exitWith {};
if (isNull _caller || _callId isEqualTo "") exitWith {};
if (_callId in GVAR(calls)) exitWith {};
if (([_caller] call FUNC(inCall)) isNotEqualTo "") exitWith {
    [_callId, REASON_REFUSED, [_caller]] remoteExecCall [QFUNC(callFailed), _caller];
};

_units = (_units select {!isNull _x && alive _x && isPlayer _x}) - [_caller];
_units = _units arrayIntersect _units;
if (count _units > CALL_MAX_MEMBERS - 1) then {_units resize (CALL_MAX_MEMBERS - 1)};

private _noRoute = _units select {!([_caller, _x] call FUNC(dataReach))};
private _busy = (_units - _noRoute) select {([_x] call FUNC(inCall)) isNotEqualTo ""};
private _ok = _units - _noRoute - _busy;
if (_noRoute isNotEqualTo []) then {
    [_callId, REASON_NO_ROUTE, _noRoute] remoteExecCall [QFUNC(callFailed), _caller];
};
if (_busy isNotEqualTo []) then {
    [_callId, REASON_BUSY, _busy] remoteExecCall [QFUNC(callFailed), _caller];
};
if (_ok isEqualTo []) exitWith {};

private _slot = GVAR(slots) find "";
if (_slot >= 0) exitWith {
    [_callId, _caller, [_caller], _ok, _priority, _slot] call FUNC(srvStart);
    [] call FUNC(srvPublish);
};

// every slot taken
private _routine = [];
if (_priority isEqualTo PRIO_FLASH && {[_caller] call FUNC(canFlash)}) then {
    _routine = ((values GVAR(calls)) select {(_x get "priority") isEqualTo PRIO_ROUTINE && (_x get "bumpAt") < 0}) apply {
        [_x get "startedAt", _x get "id"]
    };
    _routine sort true;
};
if (_routine isEqualTo []) exitWith {
    [_callId, REASON_BUSY, _ok] remoteExecCall [QFUNC(callFailed), _caller];
};

private _victim = GVAR(calls) get ((_routine select 0) select 1);
_victim set ["bumpAt", CBA_missionTime + GVAR(bumpWarning)];
_victim set ["bumpFor", [_callId, _caller, _ok, _priority]];
INFO_2("FLASH %1 bumps %2",_callId,_victim get "id");
[] call FUNC(srvPublish);
