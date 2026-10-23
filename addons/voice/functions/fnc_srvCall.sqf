#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a dial. CALL NEEDS REACH ON DATA: a callee the caller cannot reach
 * on DATA is refused (no route), one in another call is busy; the caller is
 * told about both, with CALL BACK offered. The rest ring, in a free slot.
 * With every slot taken, a FLASH call from an RTO, HQ or admin bumps the
 * oldest ROUTINE call: that call hears the priority warning for the bump
 * warning time, then ends, and this dial is made again (fnc_srvCallTick).
 * Otherwise the slots are busy.
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
 * ["123_1", player, [_unit], "ROUTINE"] call jmfsb_voice_fnc_srvCall
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_caller", objNull, [objNull]], ["_units", [], [[]]], ["_priority", PRIO_ROUTINE, [""]]];

if (!isServer || isNull _caller || _callId isEqualTo "") exitWith {};
if (_callId in GVAR(calls)) exitWith {};
if (([_caller] call FUNC(inCall)) isNotEqualTo "") exitWith {
    [QGVAR(callFailed), [_callId, REASON_REFUSED, [_caller]], _caller] call CBA_fnc_targetEvent;
};

_units = (_units select {!isNull _x && alive _x && isPlayer _x}) - [_caller];
_units = _units arrayIntersect _units;
if (count _units > CALL_MAX_MEMBERS - 1) then {_units resize (CALL_MAX_MEMBERS - 1)};

private _noRoute = _units select {!([_caller, _x] call FUNC(dataReach))};
private _busy = (_units - _noRoute) select {([_x] call FUNC(inCall)) isNotEqualTo ""};
private _ok = _units - _noRoute - _busy;
if (_noRoute isNotEqualTo []) then {
    [QGVAR(callFailed), [_callId, REASON_NO_ROUTE, _noRoute], _caller] call CBA_fnc_targetEvent;
};
if (_busy isNotEqualTo []) then {
    [QGVAR(callFailed), [_callId, REASON_BUSY, _busy], _caller] call CBA_fnc_targetEvent;
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
    [QGVAR(callFailed), [_callId, REASON_BUSY, _ok], _caller] call CBA_fnc_targetEvent;
};

private _victim = GVAR(calls) get ((_routine select 0) select 1);
_victim set ["bumpAt", CBA_missionTime + GVAR(bumpWarning)];
_victim set ["bumpFor", [_callId, _caller, _ok, _priority]];
INFO_2("FLASH %1 bumps %2",_callId,_victim get "id");
[] call FUNC(srvPublish);
