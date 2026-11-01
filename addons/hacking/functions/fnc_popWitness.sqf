#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a hack started on an internet pop, checked for witnesses. A pop is
 * public furniture in a settlement: any civilian close enough with eyes on
 * the hacker remembers it, and the settlement's hostility toward the
 * hacker's side goes up - through the adapter's own ledger, never a rebuilt
 * one. Real comms towers carry no such audience; only tagged pops call this.
 *
 * Run by FUNC(srvHackStart) for the checked sender (review S7): the witness
 * check, the side and the position are the server's, and one pop is
 * counted at most once per POP_SEEN_LOCK. The "popSeen" CBA event, which
 * let any client raise any settlement's hostility toward any side, is gone.
 * Without the adapter nobody is keeping score, so the hack is logged as
 * witnessed and goes otherwise unremarked.
 *
 * Arguments:
 * 0: The hacker <OBJECT>
 * 1: The pop <OBJECT>
 * 2: The hacker's machine, told "You were seen." <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, _pop, _owner] call jmfsb_hacking_fnc_popWitness
 *
 * Public: No
 */

params [["_player", objNull, [objNull]], ["_pop", objNull, [objNull]], ["_owner", -1, [0]]];

if (!isServer || {isNull _player} || {isNull _pop}) exitWith {};

private _locks = localNamespace getVariable [QGVAR(srvPopSeenAt), createHashMap];
private _key = _pop call BIS_fnc_netId;
if ((CBA_missionTime - (_locks getOrDefault [_key, -POP_SEEN_LOCK])) < POP_SEEN_LOCK) exitWith {};

private _witnesses = (_player nearEntities [["CAManBase"], POP_WITNESS_RANGE]) select {
    side _x isEqualTo civilian && {alive _x}
    && {([objNull, "VIEW"] checkVisibility [eyePos _x, eyePos _player]) > POP_WITNESS_SIGHT}
};
if (_witnesses isEqualTo []) exitWith {};

private _sideStr = str side group _player;
if !(_sideStr in ["WEST", "EAST", "GUER"]) exitWith {};

_locks set [_key, CBA_missionTime];
localNamespace setVariable [QGVAR(srvPopSeenAt), _locks];

if (_owner > 0) then {
    ["Hack", "You were seen.", HACK_SEEN_COLOR] remoteExecCall [QEFUNC(notify,notify), _owner];
};

private _pos = getPosATL _pop;
if (isNil QEFUNC(adapter_alive,bumpHostility)) exitWith {
    INFO_2("pop hack witnessed at %1 by a civilian hostile to %2",mapGridPosition _pos,_sideStr);
};

private _now = [_pos, _sideStr, POP_HOSTILITY_BUMP] call EFUNC(adapter_alive,bumpHostility);
if (_now < 0) exitWith {};

INFO_2("pop hack witnessed - settlement hostility toward %1 now %2",_sideStr,_now);
