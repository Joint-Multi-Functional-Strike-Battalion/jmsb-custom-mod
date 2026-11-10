#include "script_component.hpp"
/*
 * Author: YonV
 * Server tick: every vehicle in the world the system has not looked at yet
 * is fitted (or found to carry nothing) - the ones placed in the editor on
 * the first tick, everything ALiVE spawns after that within APS_SWEEP.
 *
 * Arguments: None (per-frame handler)
 *
 * Return Value: None
 *
 * Public: No
 */

GVAR(registered) = GVAR(registered) select { alive _x };

{
    if !(_x in GVAR(registered)) then {
        GVAR(registered) pushBack _x;
        if ((_x isKindOf "LandVehicle" || {_x isKindOf "Air"}) && {!(_x isKindOf "StaticWeapon")}
                && {getNumber (configOf _x >> "isUav") == 0}) then {
            [_x] call FUNC(register);
        };
    };
} forEach vehicles;
