#include "script_component.hpp"
/*
 * Author: Ampersand
 * Clears all the cargo of given container.
 *
 * Global commands, run by the machine doing the move (review R1). This was a
 * CBA global event so every machine could clear it with local commands, and
 * any client could raise that event to empty any container on the map - a
 * vehicle, a supply crate, another man's pack. Four global commands cost more
 * than one event, but only on a pack move, and nobody else can ask for them.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_backpack] call bocr_main_fnc_clearAllCargo
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {};

clearItemCargoGlobal _container;
clearWeaponCargoGlobal _container;
clearMagazineCargoGlobal _container;
clearBackpackCargoGlobal _container;
