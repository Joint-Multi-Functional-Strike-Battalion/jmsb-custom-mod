#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: runs code once the adapter is ready (FUNC(ready)) - now, when it
 * already is. Every system that needs ALiVE's registries starts here.
 *
 * Not a CBA event (review R1): the old "jmfsb_adapter_alive_ready" event could
 * be raised again by any client, restarting air defence, leaders, QRF and
 * UAS. The hooks live in localNamespace, which is not networked, and run once.
 * Local calls only.
 *
 * Arguments:
 * 0: Code, run with the arguments as _this <CODE>
 * 1: Arguments <ANY> (optional, default [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [{[] call jmfsb_qrf_fnc_start}] call jmfsb_adapter_alive_fnc_whenReady
 *
 * Public: Yes
 */

params [["_code", {}, [{}]], ["_args", []]];

if (!isServer || isRemoteExecuted) exitWith {};
if (_code isEqualTo {}) exitWith {};

if (localNamespace getVariable [QGVAR(ready), false]) exitWith {
    _args call _code;
};

private _hooks = localNamespace getVariable [QGVAR(readyHooks), []];
_hooks pushBack [_code, _args];
localNamespace setVariable [QGVAR(readyHooks), _hooks];
