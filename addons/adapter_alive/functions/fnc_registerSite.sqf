#include "script_component.hpp"
/*
 * Author: YonV
 * Makes a jmfsb site an OPCOM objective, so the commander defends it, sends
 * TACOM orders around it and counts it when he weighs the war.
 *
 * JMSB stands up coastal batteries and drone caches that ALiVE knows nothing
 * about, and a thing the commander does not know he owns is a thing he never
 * garrisons. addObjective is ALiVE's public door for this (mil_opcom
 * fnc_OPCOM.sqf:2869); the objective is a MIL one at the given priority.
 *
 * CONVENTIONAL COMMANDERS ONLY. An asymmetric OPCOM builds installations on
 * whatever objectives it holds; handing it a battery would turn the battery
 * into an IED factory. Its rear is the safe house chain, jmfsb's own.
 *
 * Arguments:
 * 0: Side <SIDE>
 * 1: Id <STRING> - unique, stable
 * 2: Position <ARRAY>
 * 3: Size <NUMBER> - objective radius
 * 4: Priority <NUMBER> (optional, default 60; lower is higher)
 *
 * Return Value:
 * Registered <BOOL>
 *
 * Example:
 * [east, "as_123456", _pos, 150] call jmfsb_adapter_alive_fnc_registerSite
 *
 * Public: No
 */

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_id", "", [""]],
    ["_pos", [], [[]]],
    ["_size", 150, [0]],
    ["_priority", 60, [0]]
];

if (!GVAR(ready) || {_side isEqualTo sideUnknown} || _id isEqualTo "" || {_pos isEqualTo []}) exitWith {false};

private _inst = [];
{
    _x params ["_cside", "_ctype", "", "", "_ci"];
    if (_cside isEqualTo _side && {_ctype in ["invasion", "occupation"]}) exitWith { _inst = _ci };
} forEach (call FUNC(commanders));
if (_inst isEqualTo []) exitWith {false};

// Registered once. The objective list is the commander's memory, and a site
// re-announcing itself every start would fill it with copies of itself.
//
// THROUGH THE INDEX, NOT THE LIST. This walked `objectives` with an ALiVE
// hashGet per entry - fine for the handful of sites this was written for,
// and O(n) per registration against a list that grows as you register. OPCOM
// keeps `objectivesByID` as a real hashmap (mil_opcom fnc_OPCOM.sqf:330) and
// addObjective writes to it on the same path that appends to the list
// (:3160), so for an id we ourselves registered the index is authoritative
// and the lookup is one hash hit.
private _byId = [_inst, "objectivesByID", createHashMap] call ALiVE_fnc_hashGet;
if (!isNil {_byId get _id}) exitWith {true};

[_inst, "addObjective", [_id, [_pos select 0, _pos select 1], _size, "MIL", _priority]] call ALiVE_fnc_OPCOM;
INFO_3("site %1 registered as an objective for %2 at %3",_id,_side,mapGridPosition _pos);
true
