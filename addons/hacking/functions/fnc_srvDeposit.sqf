#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a man banks his intel at a drop (FUNC(depositIntel), by
 * remoteExec). THE ONLY PLACE THE COUNTER MOVES. Nothing in the request is
 * believed (review S7): the man is the sender's own unit, the drop must be a
 * real intel drop within reach of him, and the count is what the server sees
 * in his inventory. His machine is then told to take those items out
 * (FUNC(depositTake)); a second deposit from him waits DEPOSIT_LOCK seconds,
 * so the same items cannot be banked twice while the removal travels.
 *
 * Every kind of intel counts, and all of it goes in one deposit - a player
 * who has to make three trips because he picked up three different objects
 * is being punished for what the bodies happened to carry.
 *
 * Arguments:
 * 0: The drop <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_drop] remoteExecCall ["jmfsb_hacking_fnc_srvDeposit", 2]
 *
 * Public: No
 */

params [["_drop", objNull, [objNull]]];

if (!isServer) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_by", "_uid"];

if (isNull _by || {!alive _by} || {isNull _drop} || {!(_drop isKindOf QGVAR(drop))}) exitWith {
    WARNING_2("srvDeposit: refused %1 at %2 - no man or no intel drop",_by,_drop);
};
if ((_by distance _drop) > DEPOSIT_RANGE) exitWith {
    WARNING_2("srvDeposit: refused %1 - %2 m from the drop",name _by,round (_by distance _drop));
};

private _locks = localNamespace getVariable [QGVAR(srvDepositAt), createHashMap];
if ((CBA_missionTime - (_locks getOrDefault [_uid, -DEPOSIT_LOCK])) < DEPOSIT_LOCK) exitWith {};

private _carried = (items _by) select {_x in INTEL_ITEMS};
private _n = count _carried;
if (_n <= 0) exitWith {};

_locks set [_uid, CBA_missionTime];
localNamespace setVariable [QGVAR(srvDepositAt), _locks];
[_by, _carried] remoteExecCall [QFUNC(depositTake), _owner];

// THE COUNTER IS THE SERVER'S, in localNamespace (review S7): a client can
// publicVariable the missionNamespace copy, which is for screens only.
private _banked = (localNamespace getVariable [QGVAR(banked), 0]) + _n;
// Whoever is banking is who the hints are drawn for.
private _side = side group _by;

["Intel Drop", format ["%1 item(s) banked - %2 of %3.",
    _n, _banked, GVAR(perHint)]] call EFUNC(notify,broadcast);

// A batch at a time, so banking twenty at once pays out twice. The deposit's
// own position rides along - the hint points at the nearest piece of the
// network, so where you bank decides what you learn about.
private _at = getPosATL _by;
while {_banked >= GVAR(perHint)} do {
    _banked = _banked - GVAR(perHint);
    if !([_at, _side] call FUNC(intelHint)) exitWith {
        // Nothing to point at: keep the deposits rather than burning them on
        // a hint that never drew.
        _banked = _banked + GVAR(perHint);
    };
};
localNamespace setVariable [QGVAR(banked), _banked];
missionNamespace setVariable [QGVAR(banked), _banked, true];
// Not kept with ALiVE loaded but no commanders, once the adapter has given up
// (user, 2026-11-02: "same as not loaded") - nothing reads it back then.
if (!isNil QEFUNC(adapter_alive,setData) && {[] call EFUNC(common,aliveLoaded)}) then {
    [QGVAR(banked), _banked] call EFUNC(adapter_alive,setData);
};
