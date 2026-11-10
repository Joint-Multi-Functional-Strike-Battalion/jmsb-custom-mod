#include "script_component.hpp"
/*
 * Author: YonV
 * Link quality from a speaker to the local player on a net, as he hears it:
 * RF's best path, held at its last value for the grace time after the route
 * drops. Mute is not applied. DIRECT 1; VEH 1 between crew of one vehicle.
 * 0 while no game-voice system runs (system "none").
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * Quality 0..1 <NUMBER>
 *
 * Example:
 * [_unit, "C2"] call jmfsb_voice_fnc_quality
 *
 * Public: Yes
 */

params [["_speaker", objNull, [objNull]], ["_net", "", [""]]];

if (isNull _speaker) exitWith {0};
if (_speaker isEqualTo player) exitWith {1};
if (!GVAR(active)) exitWith {0};
if !(([_net] call FUNC(netKind)) in MESH_KINDS) exitWith {[_speaker, _net] call FUNC(linkQuality)};

private _eff = GVAR(eff) get ((getPlayerUID _speaker) + "|" + _net);
if (isNil "_eff") exitWith {[_speaker, _net] call FUNC(linkQuality)};
_eff
