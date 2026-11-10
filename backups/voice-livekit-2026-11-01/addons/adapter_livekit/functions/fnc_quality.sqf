#include "script_component.hpp"
/*
 * Author: YonV
 * Hook "quality": how loud the local player hears a speaker on a net, from
 * the voice core (RF link quality with its grace time, 0 when the net is
 * muted). Kept per speaker and net; applied at once (FUNC(speaker)).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 * 2: Quality 0..1 <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, "C2", 0.8] call jmfsb_adapter_livekit_fnc_quality
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]], ["_q", 0, [0]]];

if (isNull _unit) exitWith {};
GVAR(q) set [(getPlayerUID _unit) + "|" + _net, _q];
[_unit] call FUNC(speaker);
