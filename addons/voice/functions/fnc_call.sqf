#include "script_component.hpp"
/*
 * Author: JMSB
 * Dials a call. CALL NEEDS REACH ON DATA: with nobody reachable it is refused
 * here ("" and a notify, CALL BACK offered); the server re-checks each callee
 * and tells the caller who had no route or was busy. The rest ring. FLASH
 * from an RTO, HQ or admin bumps the oldest ROUTINE call when all slots are
 * full. Watch jmfsb_voice_callState for what happens next.
 *
 * Arguments:
 * 0: Units <ARRAY of OBJECTs>
 * 1: Priority "ROUTINE" or "FLASH" <STRING> (default: "ROUTINE")
 *
 * Return Value:
 * Call id, "" when refused (the reason is notified) <STRING>
 *
 * Example:
 * [[_unit], "ROUTINE"] call jmfsb_voice_fnc_call
 *
 * Public: Yes
 */

params [["_units", [], [[]]], ["_priority", PRIO_ROUTINE, [""]]];

if (!GVAR(active)) exitWith {""};
if (!hasInterface || isNull player) exitWith {""};
_priority = toUpper _priority;
if !(_priority in [PRIO_ROUTINE, PRIO_FLASH]) then {_priority = PRIO_ROUTINE};
_units = _units select {!isNull _x && _x isNotEqualTo player};
_units = _units arrayIntersect _units;
if (_units isEqualTo []) exitWith {""};

if (([player] call FUNC(inCall)) isNotEqualTo "") exitWith {
    ["CALL", "Already in a call: ADD people to it instead."] call EFUNC(notify,notify);
    ["busy", ""] call FUNC(playCue);
    ""
};
if ((_units findIf {([_x, NET_DATA] call FUNC(linkQuality)) > 0}) < 0) exitWith {
    ["", REASON_NO_ROUTE, _units] call FUNC(callFailed);
    ""
};

GVAR(callSeq) = GVAR(callSeq) + 1;
private _id = format ["%1_%2", getPlayerUID player, GVAR(callSeq)];
[QGVAR(srvCall), [_id, player, _units, _priority]] call CBA_fnc_serverEvent;
["dialTone", ""] call FUNC(playCue);
_id
