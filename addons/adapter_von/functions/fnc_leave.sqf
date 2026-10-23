#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "leave", server: takes a unit off the custom channel of a net
 * (radioChannelRemove). Built-in channels need nothing (a TEAM net is left
 * by leaving the group).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "A2G"] call jmfsb_adapter_von_fnc_leave
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]]];

if (!isServer || isNull _unit) exitWith {};
private _key = [_net] call FUNC(channelKey);
private _id = GVAR(customs) getOrDefault [_key, CUSTOM_NONE];
if (_id <= CUSTOM_NONE) exitWith {};
_id radioChannelRemove [_unit];
TRACE_3("left",_unit,_net,_id);
