#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a run begins (by remoteExec, from FUNC(launch)). The aircraft
 * appears RUN_IN short of the red light at the type's altitude, every man of
 * the stick is put aboard where he is local (FUNC(board), by remoteExec), and
 * the run's watch starts (FUNC(srvTick)): red light, green light, the passes,
 * the hold and the leaving are its.
 *
 * Review S7: it was a CBA event, so any client could name any leader and any
 * men and have them put aboard. Now the leader must be the sender's own unit
 * and the stick is cut to living men of the leader's own group. The squad
 * leader test itself (FUNC(isJumpmaster)) stays on the client: the role words
 * it reads are the client's.
 *
 * Arguments:
 * 0: The leader <OBJECT>
 * 1: Jump type <STRING>
 * 2: RED LIGHT point <ARRAY>
 * 3: GREEN LIGHT point <ARRAY>
 * 4: Passes <NUMBER>
 * 5: Exit - EXIT_AUTO or EXIT_MANUAL <STRING>
 * 6: The stick, in order <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "HALO", _red, _green, 2, "auto", units group player] call jmfsb_jumpmaster_fnc_srvLaunch
 *
 * Public: No
 */

params [
    ["_leader", objNull, [objNull]],
    ["_type", TYPE_HALO, [""]],
    ["_red", [], [[]]],
    ["_green", [], [[]]],
    ["_passes", 1, [0]],
    ["_exit", EXIT_AUTO, [""]],
    ["_jumpers", [], [[]]]
];

if (!isServer || {isNull _leader} || {count _red < 2} || {count _green < 2}) exitWith {};
if (!alive _leader || {!([_leader] call EFUNC(common,senderIs))}) exitWith {
    WARNING_1("srvLaunch: refused - machine %1 named a leader not its own",remoteExecutedOwner);
};
if !(_type in TYPES) then {_type = TYPE_HALO};
if !(_exit in EXITS) then {_exit = EXIT_AUTO};

private _fnc_tell = {
    params ["_text"];
    [_text, "high"] remoteExecCall [QFUNC(say), _leader];
};

if ((GVAR(runs) findIf {(_x get "leader") isEqualTo _leader}) >= 0) exitWith {
    ["A jump is already running for your squad."] call _fnc_tell;
};
// His own squad only, never men named from elsewhere (review S7).
private _squad = units group _leader;
_jumpers = _jumpers select {_x isEqualType objNull && {alive _x} && {_x in _squad}};
if (_jumpers isEqualTo []) exitWith {["Nobody to jump."] call _fnc_tell};

private _alt = [_type] call FUNC(typeAlt);
private _dir = _red getDir _green;
private _start = _red getPos [RUN_IN, _dir + 180];
private _veh = [_leader, _start, _dir, _alt] call FUNC(spawnAircraft);
if (isNull _veh) exitWith {["The aircraft could not be put in the air - check the Jump aircraft setting."] call _fnc_tell};

private _st = createHashMapFromArray [
    ["leader", _leader],
    ["type", _type],
    ["red", _red],
    ["green", _green],
    ["dir", _dir],
    ["alt", _alt],
    ["passes", _passes max PASSES_MIN min PASSES_MAX],
    ["exit", _exit],
    ["jumpers", _jumpers],
    ["stick", [_jumpers, _passes] call FUNC(stick)],
    ["veh", _veh],
    ["phase", PHASE_IN],
    ["pass", 0],
    ["lastOut", 0],
    ["started", CBA_missionTime]
];
GVAR(runs) pushBack _st;

{
    [_x, _veh, GVAR(bay), _forEachIndex, _type] remoteExecCall [QFUNC(board), _x];
} forEach _jumpers;
[_veh, _green getPos [RUN_OUT, _dir], "NORMAL"] call EFUNC(support_air,moveTo);
[_st, format ["Aboard at %1 m, %2 km out from the red light.", _alt, round (RUN_IN / 1000)], false] call FUNC(srvLight);

[FUNC(srvTick), RUN_TICK, [_st]] call CBA_fnc_addPerFrameHandler;
