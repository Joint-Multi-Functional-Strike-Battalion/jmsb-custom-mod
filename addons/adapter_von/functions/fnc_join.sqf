#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "join", server: puts a unit on the custom channel of a net
 * (radioChannelAdd). TEAM is VON's Group channel, which follows the Arma
 * group by itself; VEH and DIRECT need nothing.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "A2G"] call jmfsb_adapter_von_fnc_join
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]]];

if (!isServer || isNull _unit) exitWith {};
private _key = [_net] call FUNC(channelKey);
if (_key isEqualTo "") exitWith {};

private _id = [_key] call FUNC(ensureChannel);
if (_id <= CUSTOM_NONE) exitWith {};
_id radioChannelAdd [_unit];
TRACE_3("joined",_unit,_net,_id);
