#include "script_component.hpp"
/*
 * Author: YonV
 * Hook "keyed": a remote speaker pushed or released his key on a net (the
 * voice core's jmfsb_voice_keyed event, sent to the net's audience). He is
 * counted as talking on that net until his key-up (FUNC(talking)), and his
 * gain is set at once (FUNC(speaker)): the net's quality while keyed, local
 * by distance otherwise.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 * 2: Keyed <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, "C2", true] call jmfsb_adapter_livekit_fnc_keyed
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]], ["_on", false, [false]]];

if (isNull _unit) exitWith {};
private _uid = getPlayerUID _unit;
if (_on) then {
    GVAR(keyed) set [_uid, [_unit, _net]];
} else {
    GVAR(keyed) deleteAt _uid;
};
[_unit] call FUNC(speaker);
