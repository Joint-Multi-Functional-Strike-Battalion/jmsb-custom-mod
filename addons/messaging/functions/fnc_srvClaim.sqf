#include "script_component.hpp"
/*
 * Author: YonV
 * Claims a task thread. First come, first served and never taken back by
 * somebody else - two medics both answering the same CASEVAC is the failure
 * this exists to stop, and a claim that anyone can steal does not stop it.
 *
 * The claimant may release their own claim by claiming again.
 *
 * A client asks by remoteExecCall to the server. The player named must be the
 * sending machine's own (review S7): otherwise anyone could claim, or release,
 * a thread in another man's name.
 *
 * Arguments:
 * 0: Player - the sender's own <OBJECT>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "T0007"] remoteExecCall ["jmfsb_messaging_fnc_srvClaim", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_threadId", "", [""]]];

if (!isServer) exitWith {};
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_3("srvClaim: refused - machine %1 tried to claim %2 as %3",remoteExecutedOwner,_threadId,_unit);
};
if (isNull _unit || {!isPlayer _unit}) exitWith {};

private _thread = GVAR(threads) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap) exitWith {};
if (_thread get "closed") exitWith {};

private _uid = getPlayerUID _unit;
private _visible = [_unit] call FUNC(srvBoxesFor);

if !(_uid in (_thread get "participants") || {(_thread get "boxes") findIf {_x in _visible} >= 0}) exitWith {};

private _held = _thread get "claimedBy";
if (_held != "" && _held != _uid) exitWith {
    ["CLAIM", "somebody already has that one"] remoteExecCall [QFUNC(cltReject), _unit];
};

private _now = ["", _uid] select (_held == "");
_thread set ["claimedBy", _now];
_thread set ["lastActivity", CBA_missionTime];
(_thread get "participants") pushBackUnique _uid;

// Everyone who can see it needs the row again - the claim is the single most
// useful thing in an index and a stale one is worse than none. The server's
// own push, not a request (FUNC(srvRequestIndex) takes only the sender's own).
private _boxes = _thread get "boxes";
{
    private _player = _x;
    private _visibleTo = [_player] call FUNC(srvBoxesFor);
    if (_boxes findIf {_x in _visibleTo} >= 0) then {
        [_player] call FUNC(srvIndexPush);
    };
} forEach allPlayers;
