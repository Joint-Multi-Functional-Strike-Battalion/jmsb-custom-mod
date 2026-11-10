#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the LZs and DZs a transport's lift job has open now, published for
 * its thread to the issuer's side (EFUNC(support,zones); user, 2026-11-02: "in
 * AiTR lz and drop zones need to be highlighted"). Called with the WILCO, a
 * NEXT LIFT, a casevac's destination and when the job leaves its pickup
 * (FUNC(liftTick)); the job's end takes them all (FUNC(liftEnd), and the
 * thread's close in the support core).
 *
 *   `hlz`      the PICKUP until it lifts from it, the INSERT LZ until PAX OFF
 *   `extract`  the EXTRACT pickup until it lifts (no destination: home)
 *   `casevac`  the CASEVAC pickup until it is given its destination, then DEST
 *   `airdrop`  the PARA DZ until the thread closes - the receipt, asked once
 *              the stick is out, so the jumpers have it on the way down
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_liftZones
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if (count _job isEqualTo 0) exitWith {};

private _first = _job get "first";
private _lz = _job getOrDefault ["lz", []];
private _lifted = _job getOrDefault ["lifted", false];
private _zones = switch (_job get "kind") do {
    case ORDER_PICKUP;
    case ORDER_LIFT: {[[ZONE_PICKUP, [_first, []] select _lifted], [ZONE_INSERT, _lz]]};
    case ORDER_EXTRACT: {[[ZONE_EXTRACT, [_first, []] select _lifted]]};
    // Its destination is the job's first point once given (FUNC(liftReply)).
    case ORDER_CASEVAC: {[[[ZONE_CASEVAC, ZONE_DEST] select ((_job get "task") isEqualTo TASK_LAND), _first]]};
    case ORDER_DROP: {[[ZONE_PARA, _first]]};
    default {[]};
};

private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
_zones = (_zones select {(_x select 1) isNotEqualTo []}) apply {_x + [_callsign]};
[_job get "thread", _zones, side group (_job get "issuer")] call EFUNC(support,zones);
