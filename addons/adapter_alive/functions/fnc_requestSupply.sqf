#include "script_component.hpp"
/*
 * Author: YonV
 * Asks the side's LOGCOM to send something to a place - the "enemy rebuilds"
 * half of every jmfsb site. A cache that is hit gets a section to guard the
 * next one; a battery that is hit gets its defenders back.
 *
 * LOGCOM_REQUEST is what ALiVE's own ATO raises when it loses an airframe
 * (mil_ato fnc_ATO.sqf:4890): [position, faction, sideText, forceMakeup,
 * "STANDARD"]. forceMakeup is six counts - infantry, motorised, mechanised,
 * armour, plane, helicopter. What arrives is a convoy the players can
 * interdict, and now can find: LOCATE LOGISTICS points at where it starts.
 *
 * Arguments:
 * 0: Side <SIDE>
 * 1: Destination <ARRAY>
 * 2: Force makeup <ARRAY> - [inf, motorised, mechanised, armour, plane, heli]
 *    (optional, default one infantry group)
 *
 * Return Value:
 * Requested <BOOL>
 *
 * Example:
 * [east, _pos, [1,0,0,0,0,0]] call jmfsb_adapter_alive_fnc_requestSupply
 *
 * Public: No
 */

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_pos", [], [[]]],
    ["_makeup", [1, 0, 0, 0, 0, 0], [[]]]
];

if (!GVAR(ready) || {isNil "ALIVE_eventLog"} || {_side isEqualTo sideUnknown} || {_pos isEqualTo []}) exitWith {false};

private _faction = "";
{
    _x params ["_cside", "", "_cf"];
    if (_cside isEqualTo _side) exitWith { _faction = _cf };
} forEach (call FUNC(commanders));
if (_faction isEqualTo "") exitWith {false};

private _event = ["LOGCOM_REQUEST", [+_pos, _faction, toUpper str _side, _makeup, "STANDARD"], "JMFSB"] call ALIVE_fnc_event;
[ALIVE_eventLog, "addEvent", _event] call ALIVE_fnc_eventLog;
INFO_3("LOGCOM_REQUEST for %1 to %2: %3",_side,mapGridPosition _pos,_makeup);
true
