#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "keyed", client: a remote speaker pushed his own key-down or
 * key-up on a net (jmfsb_voice_keyed). setPlayerVoNVolume is the listener's
 * own, so his volume here is set at once from the quality the voice core
 * gave for him on that net (fnc_applyVolume; muted when this listener is not
 * on the net), and he counts as talking on the net's channel until his
 * key-up (fnc_talking), whatever getPlayerChannel says of him.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 * 2: Key down <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, "C2", true] call jmfsb_adapter_von_fnc_keyed
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]], ["_on", false, [false]]];

if (isNull _unit) exitWith {};
private _uid = getPlayerUID _unit;
if (count GVAR(test) > 0) then {GVAR(test) set ["keyed", (GVAR(test) getOrDefault ["keyed", 0]) + 1]};

private _ch = [CH_NONE, [_net] call FUNC(channel)] select _on;
if (_ch > CH_NONE) then {
    GVAR(keyed) set [_uid, [_unit, _ch, _net]];
} else {
    GVAR(keyed) deleteAt _uid;
};
GVAR(talkCh) set [_uid, _ch];
[_unit, _ch, _net] call FUNC(applyVolume);
