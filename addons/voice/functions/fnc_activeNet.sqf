#include "script_component.hpp"
/*
 * Author: JMSB
 * The local player's active net: the one the game push-to-talk sends on.
 * "" while no game-voice system runs (system "none").
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

if (!GVAR(active)) exitWith {""};
GVAR(activeNetId)
