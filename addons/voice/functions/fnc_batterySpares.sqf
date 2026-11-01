#include "script_component.hpp"
/*
 * Author: JMSB
 * The spare radio batteries the player carries: every item in his kit whose
 * class the Spare batteries setting names.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Item classes, one per spare <ARRAY>
 *
 * Example:
 * count ([] call jmfsb_voice_fnc_batterySpares)
 *
 * Public: Yes
 */

if (isNull player) exitWith {[]};

private _classes = (GVAR(batteryClasses) splitString ",") apply {toLower trim _x};
(items player) select {(toLower _x) in _classes}
