#include "script_component.hpp"
/*
 * Author: YonV
 * Sends one thread's bodies to a player who is entitled to them. A player who
 * is not gets an empty answer rather than an error: refusing loudly would
 * confirm the thread exists, which is itself worth knowing.
 *
 * A client asks by remoteExecCall to the server. The player named must be the
 * sending machine's own (review S7), so a client can only ever ask for what it
 * may read itself, and the answer goes back to that player alone.
 *
 * Arguments:
 * 0: Player - the sender's own <OBJECT>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "T0007"] remoteExecCall ["jmfsb_messaging_fnc_srvRequestThread", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_threadId", "", [""]]];

if (!isServer) exitWith {};
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_3("srvRequestThread: refused - machine %1 asked for %2 as %3",remoteExecutedOwner,_threadId,_unit);
};
if (isNull _unit || {!isPlayer _unit}) exitWith {};

private _fnc_deny = {
    [[], []] remoteExecCall [QFUNC(cltThread), _unit];
};

private _thread = GVAR(threads) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap) exitWith {call _fnc_deny};

private _uid = getPlayerUID _unit;
private _visible = [_unit] call FUNC(srvBoxesFor);

if !(_uid in (_thread get "participants") || {(_thread get "boxes") findIf {_x in _visible} >= 0}) exitWith {
    call _fnc_deny
};

private _messages = [];
{
    private _message = GVAR(messages) getOrDefault [_x, createHashMap];
    if (_message isNotEqualTo createHashMap) then {
        _messages pushBack (_message toArray false);
    };
} forEach (_thread get "messages");

// Pairs, not [keys, values] - see FUNC(srvDeliver). By remoteExecCall, which
// the client takes only from the server (review S7).
[_thread toArray false, _messages] remoteExecCall [QFUNC(cltThread), _unit];
