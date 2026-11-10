#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the tactical lights watch, every TACTICAL_TICK seconds - one pass
 * over every registered support aircraft (FUNC(tactical)). A deleted or lost
 * aircraft drops off the list here.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle (unused) <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(tacticalTick), TACTICAL_TICK] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

GVAR(tactical) = GVAR(tactical) select {alive (_x select 0)};

{
    _x call FUNC(tacticalLights);
} forEach GVAR(tactical);
