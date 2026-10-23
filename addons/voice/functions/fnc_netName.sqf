#include "script_component.hpp"
/*
 * Author: JMSB
 * The name a voice net is shown by: a TEAM net by its group's callsign, every
 * other net by its id.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Name <STRING>
 *
 * Example:
 * ["TEAM WEST Alpha 1-1"] call jmfsb_voice_fnc_netName
 *
 * Public: No
 */

params [["_net", "", [""]]];

if ((_net find TEAM_PREFIX) != 0) exitWith {_net};

// "TEAM <side> <callsign>": the callsign is everything after the side
private _rest = _net select [count TEAM_PREFIX];
private _space = _rest find " ";
if (_space < 0) exitWith {_rest};
_rest select [_space + 1]
