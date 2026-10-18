#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Sets one air defence vehicle's targeting mode - Off, Random, Closest threat
 * or Highest threat (ADS_MODES; FUNC(assign) says what each picks) - public, so
 * the server's assignment reads it. A blank mode steps to the next one, for
 * the scroll action.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Mode, or "" for the next one <STRING>
 *
 * Return Value: None
 *
 * Example:
 * [cursorObject, "highest"] call jmfsb_adsite_fnc_setMode
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_mode", "", [""]]];

if (isNull _veh) exitWith {};
private _modes = ADS_MODES;
if !(_mode in _modes) then {
    private _now = _modes find (_veh getVariable [QGVAR(mode), ADS_MODE_DEFAULT]);
    _mode = _modes select ((_now + 1) mod (count _modes));
};
_veh setVariable [QGVAR(mode), _mode, true];

if (hasInterface) then {
    [format ["Air defence - %1: %2", getText (configOf _veh >> "displayName"), ADS_MODE_NAMES select (_modes find _mode)]] call CBA_fnc_notify;
};
