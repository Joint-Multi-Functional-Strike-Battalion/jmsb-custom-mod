#include "script_component.hpp"
/*
 * Author: JMSB
 * Mutes or unmutes a net for the local player: its speakers are set to
 * volume 0 for him while they talk on it (VON has no per-channel volume).
 * Under TFAR / ACRE: the radio's own volume for that net (hook "setMute"),
 * where the radio has one.
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Muted <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["A2G", true] call jmfsb_voice_fnc_setMute
 *
 * Public: Yes
 */

params [["_net", "", [""]], ["_muted", true, [true]]];

if (!GVAR(active)) exitWith {
    if ([_net, _muted] call HOOK("setMute")) then {[QGVAR(netsChanged), []] call CBA_fnc_localEvent};
};
GVAR(muted) set [_net, _muted];
[] call FUNC(updateQuality);
[QGVAR(netsChanged), []] call CBA_fnc_localEvent;
