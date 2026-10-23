#include "script_component.hpp"
/*
 * Author: JMSB
 * Pending callbacks the local player is part of, either end - both people
 * see them. "held" = waiting out EMCON 3.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[from unit, to unit, requested at, state "waiting"|"held"], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_callbacks
 *
 * Public: Yes
 */

if (!GVAR(active)) exitWith {[]};
if (isNull player) exitWith {[]};
GVAR(callbackTable) select {player in [_x select 0, _x select 1]}
