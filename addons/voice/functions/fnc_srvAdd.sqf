#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the call's OWNER - who started it - adds people. They ring until
 * they accept. Anyone else is refused with REASON_NOT_OWNER (user,
 * 2026-10-20: the channel owner invites, not the RTO).
 * People he cannot reach on DATA, or who are in another call, are skipped
 * and he is told; the adds stop at CALL_MAX_MEMBERS in the call.
 *
 * Arguments:
 * 0: Call id <STRING>
 * 1: Units <ARRAY of OBJECTs>
 * 2: Who adds them <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["123_1", [_unit], player] call jmfsb_voice_fnc_srvAdd
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_units", [], [[]]], ["_by", objNull, [objNull]]];

private _call = GVAR(calls) getOrDefault [_callId, createHashMap];
if (count _call == 0 || isNull _by) exitWith {};
private _members = _call get "members";
private _ringing = _call get "ringing";
if !(_by in _members) exitWith {
    [QGVAR(callFailed), [_callId, REASON_REFUSED, [_by]], _by] call CBA_fnc_targetEvent;
};
if (_by isNotEqualTo (_call getOrDefault ["owner", _call get "from"])) exitWith {
    [QGVAR(callFailed), [_callId, REASON_NOT_OWNER, [_by]], _by] call CBA_fnc_targetEvent;
};

_units = (_units select {!isNull _x && alive _x && isPlayer _x}) - _members;
_units = (_units arrayIntersect _units) select {
    private _unit = _x;
    (_ringing findIf {(_x select 0) isEqualTo _unit}) < 0
};

private _noRoute = _units select {!([_by, _x] call FUNC(dataReach))};
private _busy = (_units - _noRoute) select {([_x] call FUNC(inCall)) isNotEqualTo ""};
private _ok = _units - _noRoute - _busy;
private _room = (CALL_MAX_MEMBERS - count _members - count _ringing) max 0;
if (count _ok > _room) then {_ok resize _room};

if (_noRoute isNotEqualTo []) then {
    [QGVAR(callFailed), [_callId, REASON_NO_ROUTE, _noRoute], _by] call CBA_fnc_targetEvent;
};
if (_busy isNotEqualTo []) then {
    [QGVAR(callFailed), [_callId, REASON_BUSY, _busy], _by] call CBA_fnc_targetEvent;
};

private _now = CBA_missionTime;
{
    _ringing pushBack [_x, _now];
} forEach _ok;
[] call FUNC(srvPublish);
