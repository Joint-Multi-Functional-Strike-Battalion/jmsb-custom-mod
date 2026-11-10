#include "script_component.hpp"
/*
 * Author: YonV
 * Server: registers code to run after a message has been filed and delivered
 * (FUNC(srvSubmit)). For server-side systems that answer traffic without this
 * addon knowing them - the support core replies to a thread filed to an
 * asset's box as that asset (user, 2026-11-01: messaging must not know about
 * support, so support registers here, never the reverse).
 *
 * THE FRAME AFTER, ONE HOOK AT A TIME. Each hook is queued with
 * CBA_fnc_execNextFrame by FUNC(srvSubmit) once the message is in the store,
 * in its boxes and pushed to its readers, so:
 *   - a hook that errors cannot undo or stop the filing, nor the next hook;
 *   - a hook runs outside the sender's remoteExecCall, so a hook that files a
 *     reply of its own through FUNC(srvSubmit) passes as the server and not as
 *     the client whose message woke it (EFUNC(common,senderIs) and
 *     EFUNC(common,senderIsAdmin) read the call now running).
 * A hook is told about every message, its own replies included; it decides
 * what is worth answering.
 *
 * Not a CBA event: the hooks live in localNamespace, which is not networked,
 * and only the server's own srvSubmit runs them. Server only, local calls only:
 * a remote-executed call is dropped.
 *
 * Arguments:
 * 0: Code, run with [thread <HASHMAP>, message <HASHMAP>, box ids <ARRAY of STRINGs>] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_thread", "_message", "_boxIds"]; diag_log (_thread get "id")}] call jmfsb_messaging_fnc_onFiled
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

if (!isServer || isRemoteExecuted) exitWith {};
if (_code isEqualTo {}) exitWith {};

private _hooks = localNamespace getVariable [QGVAR(filedHooks), []];
_hooks pushBack _code;
localNamespace setVariable [QGVAR(filedHooks), _hooks];
