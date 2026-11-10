#include "script_component.hpp"
/*
 * Author: YonV
 * Server: runs code once the adapter is ready (FUNC(ready)) - now, when it
 * already is. Every system that needs ALiVE's registries starts here.
 *
 * Not a CBA event (review R1): the old "jmfsb_adapter_alive_ready" event could
 * be raised again by any client, restarting air defence, leaders, QRF and
 * UAS. The hooks live in localNamespace, which is not networked, and run once.
 * Local calls only.
 *
 * THE FALLBACK (user, 2026-11-02: "same as not loaded"). When FUNC(ready)
 * gives up - ALiVE loaded, no commander after READY_GIVE_UP - the fallback
 * runs instead of the code, and at once when it has already given up. A
 * caller hands in the same branch it runs when the adapter is not loaded at
 * all, so a feature has one path without ALiVE, not two.
 *
 * Arguments:
 * 0: Code, run with the arguments as _this <CODE>
 * 1: Arguments <ANY> (optional, default [])
 * 2: Fallback, run with the arguments as _this when ALiVE is declared absent
 *    <CODE> (optional, default {})
 *
 * Return Value:
 * None
 *
 * Example:
 * [{[] call jmfsb_qrf_fnc_start}, [], {diag_log "QRF: markers only"}] call jmfsb_adapter_alive_fnc_whenReady
 *
 * Public: Yes
 */

params [["_code", {}, [{}]], ["_args", []], ["_fallback", {}, [{}]]];

if (!isServer || isRemoteExecuted) exitWith {};

if (localNamespace getVariable [QGVAR(absent), false]) exitWith {
    _args call _fallback;
};

if (_code isEqualTo {}) exitWith {};

if (localNamespace getVariable [QGVAR(ready), false]) exitWith {
    _args call _code;
};

private _hooks = localNamespace getVariable [QGVAR(readyHooks), []];
_hooks pushBack [_code, _args, _fallback];
localNamespace setVariable [QGVAR(readyHooks), _hooks];
