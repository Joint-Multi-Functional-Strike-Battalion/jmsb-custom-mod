#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: how loud the local player hears a speaker on a net - the quality
 * after the grace time (jmfsb_voice_fnc_quality), 0 when he muted the net.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * 0..1 <NUMBER>
 *
 * Example:
 * [_unit, "C2"] call jmfsb_voice_fnc_heard
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]]];

if (GVAR(muted) getOrDefault [_net, false]) exitWith {0};
[_unit, _net] call FUNC(quality)
