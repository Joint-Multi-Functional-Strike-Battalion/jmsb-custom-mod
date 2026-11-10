#include "script_component.hpp"
/*
 * Author: YonV
 * Marks every message in a thread read by this player. Nothing is broadcast:
 * an unread count is the reader's own business and telling twenty clients that
 * somebody opened a thread is twenty messages for no gain.
 *
 * A client sends it by remoteExecCall to the server. The player named must be
 * the sending machine's own (review S7), so nobody marks another man's
 * traffic read.
 *
 * Arguments:
 * 0: Player - the sender's own <OBJECT>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "T0007"] remoteExecCall ["jmfsb_messaging_fnc_srvMarkRead", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_threadId", "", [""]]];

if (!isServer) exitWith {};
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_3("srvMarkRead: refused - machine %1 tried to mark %2 read as %3",remoteExecutedOwner,_threadId,_unit);
};
if (isNull _unit || {!isPlayer _unit}) exitWith {};

private _thread = GVAR(threads) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap) exitWith {};

private _uid = getPlayerUID _unit;
private _visible = [_unit] call FUNC(srvBoxesFor);

if !(_uid in (_thread get "participants") || {(_thread get "boxes") findIf {_x in _visible} >= 0}) exitWith {};

{
    private _message = GVAR(messages) getOrDefault [_x, createHashMap];
    if (_message isNotEqualTo createHashMap) then {
        (_message get "readBy") pushBackUnique _uid;
    };
} forEach (_thread get "messages");
