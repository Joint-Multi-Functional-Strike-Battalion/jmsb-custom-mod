#include "script_component.hpp"
/*
 * Author: Ampersand
 * Clear inventory of every backpack in given container, with global commands
 * (FUNC(clearAllCargo); review R1 - no longer a CBA event).
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * NONE
 *
 * Example:
 * [_container] call bocr_main_fnc_clearCargoBackpacks;
 *
 * Public: No
 */

params ["_container"];

{
    [_x] call FUNC(clearAllCargo);
} forEach everyBackpack _container;
