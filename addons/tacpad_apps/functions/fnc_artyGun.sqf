#include "script_component.hpp"
/*
 * Author: YonV
 * The gun the ARTY calculator solves for: the artillery piece the player is
 * in, else the nearest one within the player's ARTY gun range setting (the
 * crew standing at a mortar with the tablet out). An artillery piece is any
 * with the engine's artillery computer (artilleryScanner) - vanilla and most
 * modded artillery alike.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The gun, objNull for none <OBJECT>
 *
 * Example:
 * private _gun = [] call jmfsb_tacpad_apps_fnc_artyGun
 *
 * Public: No
 */

private _me = call CBA_fnc_currentUnit;
if (isNull _me) exitWith {objNull};

private _fnc_isArty = {getNumber (configOf _this >> "artilleryScanner") > 0};

private _in = objectParent _me;
if (!isNull _in && {_in call _fnc_isArty}) exitWith {_in};

private _near = (_me nearEntities [["LandVehicle"], GVAR(artyGunRange)]) select {alive _x && {_x call _fnc_isArty}};
if (_near isEqualTo []) exitWith {objNull};
_near = _near apply {[_me distance _x, _x]};
_near sort true;
(_near # 0) # 1
