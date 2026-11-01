#include "script_component.hpp"
/*
 * Author: JMSB
 * Registers code to run on this machine when a message arrives for this
 * player (FUNC(cltReceive)). For screens that react to traffic - the reader
 * redraws, TAC//MSG puts a FLASH banner up.
 *
 * Not a CBA event (review S7): any client can raise any CBA event on every
 * machine, so a `received` event was a fake FLASH banner anyone could put on
 * every screen. The hooks live in localNamespace, which is not networked, and
 * run only from FUNC(cltReceive), which takes its call only from the server.
 * Local calls only: a remote-executed call is dropped.
 *
 * Arguments:
 * 0: Code, run with [message <HASHMAP>, index entry <HASHMAP>] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_message", "_entry"]; systemChat (_entry get "subject")}] call jmfsb_messaging_fnc_onReceive
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

if (isRemoteExecuted) exitWith {};
if (_code isEqualTo {}) exitWith {};

private _hooks = localNamespace getVariable [QGVAR(receiveHooks), []];
_hooks pushBack _code;
localNamespace setVariable [QGVAR(receiveHooks), _hooks];
