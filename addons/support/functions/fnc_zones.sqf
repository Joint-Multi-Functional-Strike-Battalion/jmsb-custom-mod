#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the LZs and DZs a support thread has open on the ground right now
 * (user, 2026-11-02: "in AiTR lz and drop zones need to be highlighted"). The
 * provider that flies the thread sets them at its natural points - all of them
 * with its WILCO, fewer as each leg is done (the pickup once the troop load
 * lifts), none at the end - and every player of the side sees them in his AiTR
 * (jmfsb_ecoti).
 *
 * ONE LIST PER THREAD, REPLACED WHOLE. A call gives what is open now; [] is
 * nothing. The server's copy is localNamespace (clients cannot write it); each
 * change goes to the side by FUNC(zonesPublish).
 *
 * THE THREAD'S END TAKES THEM (FUNC(srvReply), argument 3): a thread CLOSED,
 * DECLINED or ABORTED loses its zones whether or not its provider said so - but
 * not ones held past the close for a stick still in the air (FUNC(zonesHold)).
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: Its zones, [] for none - [kind (ZONE_KINDS), centre, asset call sign, radius (m, optional - 0 the kind's own)]... <ARRAY> (optional, default [])
 * 2: The side they are for - the issuer's, from his unit; sideUnknown keeps the side it has <SIDE> (optional, default sideUnknown)
 * 3: The thread is over - only zones not held go <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_threadId, [["pickup", _pickup, "RAVEN"], ["insert", _lz, "RAVEN"]], side group _issuer] call jmfsb_support_fnc_zones
 *
 * Public: Yes
 */

params [
    ["_threadId", "", [""]],
    ["_zones", [], [[]]],
    ["_side", sideUnknown, [sideUnknown]],
    ["_over", false, [false]]
];

if (!isServer || _threadId isEqualTo "") exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("zones: refused - remote call from machine %1",remoteExecutedOwner);
};

private _all = localNamespace getVariable [QGVAR(zoneThreads), createHashMap];
private _was = _all getOrDefault [_threadId, []];
_was params [["_wasSide", sideUnknown], ["_wasRows", []], ["_held", false]];
if (_over && (_was isEqualTo [] || _held)) exitWith {};
if (_side isEqualTo sideUnknown) then {_side = _wasSide};

// Each as the clients take it: [kind, centre on the ground, radius, call sign, thread].
private _rows = [];
{
    _x params [["_kind", "", [""]], ["_pos", [], [[]]], ["_callsign", "", [""]], ["_radius", 0, [0]]];
    private _known = ZONE_KINDS findIf {(_x select 0) isEqualTo _kind};
    if (_known < 0 || count _pos < 2) then {
        WARNING_2("zones: thread %1 - '%2' is not a zone kind, or has no point",_threadId,_kind);
        continue;
    };
    if (_radius <= 0) then {_radius = (ZONE_KINDS select _known) select 1};
    _rows pushBack [_kind, [_pos select 0, _pos select 1, 0], _radius min ZONE_RADIUS_MAX, (toUpper _callsign) select [0, CALLSIGN_MAX], _threadId];
} forEach _zones;
if (_rows isNotEqualTo [] && _side isEqualTo sideUnknown) exitWith {
    WARNING_1("zones: thread %1 - no side to publish its zones to",_threadId);
};

if (_rows isEqualTo []) then {
    _all deleteAt _threadId;
} else {
    _all set [_threadId, [_side, _rows, false]];
};
localNamespace setVariable [QGVAR(zoneThreads), _all];

// Sent only when it changed (review R7).
if (_rows isEqualTo _wasRows && _side isEqualTo _wasSide) exitWith {};
[[_side, _wasSide] select {_x isNotEqualTo sideUnknown}] call FUNC(zonesPublish);
