#include "script_component.hpp"
/*
 * Author: JMSB
 * The local player's active net: the one the game push-to-talk sends on.
 * Under TFAR / ACRE: the net of that radio's active set (hook "current").
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Net id, "" when none <STRING>
 *
 * Example:
 * [] call jmfsb_voice_fnc_activeNet
 *
 * Public: Yes
 */

if (!GVAR(active)) exitWith {[] call HOOK("current")};
GVAR(activeNetId)
