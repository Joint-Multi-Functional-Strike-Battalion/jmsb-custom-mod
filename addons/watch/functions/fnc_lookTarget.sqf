#include "script_component.hpp"
/*
 * Author: YonV
 * What the player is looking at for the watch: the object under the crosshair
 * (cursorObject, else cursorTarget), within ACTION_REACH, never himself.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Target, objNull for none <OBJECT>
 *
 * Example:
 * [] call jmfsb_watch_fnc_lookTarget
 *
 * Public: No
 */

private _target = cursorObject;
if (isNull _target) then {_target = cursorTarget};
if (isNull _target || {_target isEqualTo player} || {(player distance _target) > ACTION_REACH}) exitWith {objNull};
_target
