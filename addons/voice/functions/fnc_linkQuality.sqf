#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: the raw RF link quality from a speaker to the local player on a
 * voice net, from the local slice - the best link between any of the
 * player's nodes and any of the speaker's, on the RF net that carries the
 * voice net. No grace time, no mute. DIRECT is always 1; VEH is 1 between
 * two crew of the same vehicle and 0 otherwise.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * Quality 0..1 <NUMBER>
 *
 * Example:
 * [_unit, "C2"] call jmfsb_voice_fnc_linkQuality
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]]];

if (_unit isEqualTo player) exitWith {1};
private _kind = [_net] call FUNC(netKind);
if (_kind isEqualTo KIND_DIRECT) exitWith {1};
if (_kind isEqualTo KIND_VEH) exitWith {
    private _vehicle = [player] call FUNC(crewOf);
    parseNumber (!isNull _vehicle && {_vehicle isEqualTo ([_unit] call FUNC(crewOf))})
};

private _rfNet = [_net] call FUNC(rfNet);
if (_net isEqualTo NET_DATA) then {_rfNet = NET_DATA};
if (_rfNet isEqualTo "") exitWith {0};

private _his = [_unit] call FUNC(nodeIds);
private _best = 0;
{
    private _mine = _x;
    {
        _best = _best max (([_mine, _x, _rfNet] call EFUNC(rf,link)) select 0);
    } forEach _his;
} forEach GVAR(myNodes);
_best
