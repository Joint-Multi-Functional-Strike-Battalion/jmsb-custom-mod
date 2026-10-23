#include "script_component.hpp"
/*
 * Author: JMSB
 * Sets the ear a net's beeps and static play from (VON cannot pan voice).
 * Under TFAR / ACRE: the radio's own stereo side for that net (hook
 * "setEar"), where the radio has one.
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Ear "L", "B" or "R" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["C2", "L"] call jmfsb_voice_fnc_setEar
 *
 * Public: Yes
 */

params [["_net", "", [""]], ["_ear", EAR_BOTH, [""]]];

_ear = toUpper _ear;
if !(_ear in EARS) exitWith {};
if (!GVAR(active)) exitWith {
    if ([_net, _ear] call HOOK("setEar")) then {[QGVAR(netsChanged), []] call CBA_fnc_localEvent};
};
GVAR(ears) set [_net, _ear];
[QGVAR(netsChanged), []] call CBA_fnc_localEvent;
