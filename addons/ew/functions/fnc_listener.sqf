#include "script_component.hpp"
/*
 * Author: JMSB
 * RF's transmission listener (jmfsb_rf_fnc_addListener), server, once per RF
 * tick: keeps the latest list of emitting nodes for the DF tick, and the
 * last time each one carried traffic - the "decoy?" rule and the beacon
 * duty both read it. Cheap on purpose: the DF work is FUNC(tick)'s, at its
 * own rate.
 *
 * Arguments:
 * 0: Emitters [[id, object, position ASL, profile id, bands, TX dBm, side,
 *    tx, emcon, net ids, data], ...] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_emitters] call jmfsb_ew_fnc_listener
 *
 * Public: No
 */

params [["_emitters", [], [[]]]];

GVAR(rfEmitters) = _emitters;

private _now = CBA_missionTime;
{
    _x params ["_id", "", "", "", "", "", "", "_tx"];
    if !(_id in GVAR(firstSeen)) then {GVAR(firstSeen) set [_id, _now]};
    if (_tx) then {GVAR(lastTx) set [_id, _now]};
} forEach _emitters;
