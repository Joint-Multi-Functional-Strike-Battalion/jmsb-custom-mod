#include "script_component.hpp"
/*
 * Author: JMSB
 * SHIFT PATH FOR WIND: moves the red and green light points upwind by the
 * stick's drift (FUNC(drift)), so a stick released at the new green light
 * lands where the old one was - the drop zone the leader picked. One shift
 * for the wind as it blows now; a second press shifts again, which is not
 * what anyone wants, so the page says so when the drift is under WIND_MIN_M.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The path moved <BOOL>
 *
 * Example:
 * [] call jmfsb_jumpmaster_fnc_windShift
 *
 * Public: No
 */

if (GVAR(red) isEqualTo [] || {GVAR(green) isEqualTo []}) exitWith {
    ["No flight path to shift: PICK PATH ON MAP first.", "high"] call FUNC(say);
    false
};

([GVAR(type)] call FUNC(drift)) params ["_dx", "_dy"];
private _drift = [_dx, _dy, 0];
private _len = vectorMagnitude _drift;
if (_len < WIND_MIN_M) exitWith {
    ["Not enough wind to shift for.", "high"] call FUNC(say);
    false
};

GVAR(red) = GVAR(red) vectorDiff _drift;
GVAR(green) = GVAR(green) vectorDiff _drift;
[format ["Path shifted %1 m upwind: the stick lands on the old green light.", round _len]] call FUNC(say);

true
