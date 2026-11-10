#include "script_component.hpp"
/*
 * Author: YonV
 * The voice nets a unit is on, in device order: TEAM, C2-kind, A2G-kind (the
 * radio nets his RF fill holds, from the server's roster), every CALL he is
 * live or ringing in, VEH while he is crew, DIRECT. voiceChannel is the
 * adapter's channel for the net (VON: 3 Group, 4 Vehicle, 5 Direct, 6-15
 * custom), -1 when it has none (yet). None while no game-voice system runs
 * (system "none").
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [[netId, name, kind ("team"|"c2"|"a2g"|"veh"|"call"|"direct"), voiceChannel], ...] <ARRAY>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_nets
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || !GVAR(active)) exitWith {[]};
private _fill = (GVAR(rosterIndex) getOrDefault [getPlayerUID _unit, [objNull, "", [], 0]]) select 2;

private _out = [];
private _team = [_unit] call FUNC(teamNet);
if (_team in _fill) then {_out pushBack _team};
private _c2 = [_unit] call FUNC(c2Net);
if (_c2 in _fill) then {_out pushBack _c2};
private _a2g = [_unit] call FUNC(a2gNet);
if (_a2g in _fill) then {_out pushBack _a2g};
// the RTO nets he is on, after the plan's and before the calls
{
    if (_x in _fill) then {_out pushBack _x};
} forEach ([_unit] call FUNC(customNets));
{
    _x params ["", "_slot", "", "_members", "_ringing"];
    if (_unit in _members || _unit in _ringing) then {_out pushBack format [CALL_FORMAT, _slot]};
} forEach GVAR(callTable);
if (!isNull ([_unit] call FUNC(crewOf))) then {_out pushBack NET_VEH};
_out pushBack NET_DIRECT;

_out apply {[_x, [_x] call FUNC(netName), [_x] call FUNC(netKind), [_x] call HOOK("channel")]}
