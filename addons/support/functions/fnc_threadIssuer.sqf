#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the Steam id of the man an asset takes orders from in a thread
 * (2026-11-09): the thread's issuer, or - in a TIC, SALUTE or MIST thread a
 * support request pulled the asset into (FUNC(srvFiled)) - that request's
 * sender, who may not be the report's. Every place the core files as the
 * asset or checks who may answer reads it here.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 *
 * Return Value:
 * Steam id, "" none <STRING>
 *
 * Example:
 * private _uid = [_thread] call jmfsb_support_fnc_threadIssuer
 *
 * Public: No
 */

params [["_thread", createHashMap, [createHashMap]]];

(localNamespace getVariable [QGVAR(threadIssuers), createHashMap]) getOrDefault [
    _thread getOrDefault ["id", ""],
    _thread getOrDefault ["issuerUid", ""]
]
