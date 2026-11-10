#include "script_component.hpp"
/*
 * Author: YonV
 * Asks a side's artillery commander for fire, on ALiVE's own event bus.
 *
 * Raises ARTY_REQUEST with the payload mil_artillery actually reads
 * (fnc_ARTILLERY.sqf:590 registers the listener, :599 handles it):
 *   [targetID, targetPos, contacts, sideObject, faction, asymFlag]
 *
 * WHETHER ANYTHING FIRES IS mil_artillery's DECISION - range, ammo, friendly
 * safety, and its queue cap of 12. This schedules; it never guarantees.
 *
 * Arguments:
 * 0: Side whose guns should answer <SIDE>
 * 1: Target position <ARRAY>
 * 2: Contact count backing the request <NUMBER> (optional, default 1)
 *
 * Return Value:
 * Request placed on the bus <BOOL>
 *
 * Example:
 * [east, _pos] call jmfsb_adapter_alive_fnc_requestFire
 */

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_pos", [], [[]]],
    ["_contacts", 1, [0]]
];

if (!GVAR(ready) || {_side isEqualTo sideUnknown} || {_pos isEqualTo []}) exitWith {false};
if (isNil "ALIVE_eventLog") exitWith {false};

private _faction = "";
{
    _x params ["_cside", "", "_cf"];
    if (_cside isEqualTo _side) exitWith { _faction = _cf };
} forEach (call FUNC(commanders));

GVAR(fireSeq) = GVAR(fireSeq) + 1;
private _id = format ["JMFSB_FIRE_%1", GVAR(fireSeq)];

private _event = ["ARTY_REQUEST",
    [_id, +_pos, _contacts, _side, _faction, false],
    "JMFSB"] call ALIVE_fnc_event;
[ALIVE_eventLog, "addEvent", _event] call ALIVE_fnc_eventLog;

INFO_3("ARTY_REQUEST %1 raised for %2 at grid %3",_id,_side,mapGridPosition _pos);
true
