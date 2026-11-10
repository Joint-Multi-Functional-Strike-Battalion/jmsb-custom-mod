#include "script_component.hpp"
/*
 * Author: YonV
 * The aiming error a battery's next salvo carries (user, 2026-11-02, from the
 * Tun Firesupport review: "aiming error removed by adjusting"). A mission's
 * first salvo has the module's whole Aiming Error; every correction the
 * observer has called on it (an ADJUST - QGVAR(aimSteps), counted by
 * FUNC(adjustNext)) and the FIRE FOR EFFECT after them (QGVAR(aimFfe))
 * multiply it by AIM_DECAY. Once it is under the gun's own Dispersion it is
 * gone: only the dispersion is left. The counts are the server's, reset by
 * FUNC(openMission); a client reads none, so its preview (FUNC(cardPreview))
 * gets the first salvo's error, as a new card would.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The error along the line of fire (m); across it is DISP_DEFLECTION_SHARE of
 * that <NUMBER>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_aimError
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {0};

private _steps = (_logic getVariable [QGVAR(aimSteps), 0]) + ([0, 1] select (_logic getVariable [QGVAR(aimFfe), false]));
private _error = (_logic getVariable [QGVAR(aimError), 0]) * (AIM_DECAY ^ _steps);

[_error, 0] select (_error < (_logic getVariable [QGVAR(dispersion), 0]))
