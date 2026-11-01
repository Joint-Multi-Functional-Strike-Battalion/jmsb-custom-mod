#include "script_component.hpp"
/*
 * Author: JMSB
 * Sets the ear a net's beeps and static play from (VON cannot pan voice).
 * Nothing while no game-voice system runs (system "none").
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
if (!(_ear in EARS) || !GVAR(active)) exitWith {};
GVAR(ears) set [_net, _ear];
[QGVAR(netsChanged), []] call CBA_fnc_localEvent;
