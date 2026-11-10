#include "script_component.hpp"
/*
 * Author: YonV
 * Server: nobody answered MEN STILL ABOARD - HOLDING OVER THE DZ for 5 min
 * (D9, user 2026-11-01; the support core's prompt calls this, 2026-11-02).
 * The aircraft cannot hold for ever: the men still aboard go out over the DZ
 * (FUNC(srvGo), "NO RESPONSE - 2 OUT OVER THE DZ"), then it leaves.
 *
 * Arguments:
 * 0: Asset id, "jump:<n>" or "jump:<side>" <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["jump:west", "T0042"] call jmfsb_jumpmaster_fnc_srvTimeout
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvTimeout: refused - remote call from machine %1",remoteExecutedOwner);
};

private _at = GVAR(runs) findIf {(_x get "thread") isEqualTo _threadId};
if (_at < 0) exitWith {};

[GVAR(runs) select _at, SAID_NO_RESPONSE] call FUNC(srvGo);
