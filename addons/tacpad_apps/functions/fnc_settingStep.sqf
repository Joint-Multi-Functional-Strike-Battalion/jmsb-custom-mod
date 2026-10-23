#include "script_component.hpp"
/*
 * Author: JMSB
 * Steps a numeric CBA setting by one press - the settings app's minus / plus
 * pair, and anything else that nudges a slider - clamped to the slider's range
 * and rounded to the places it stores, so stepping down and back up lands on
 * the number it started at rather than near it.
 *
 * Arguments:
 * 0: Setting name, the full jmfsb_..._name string <STRING>
 * 1: Step, signed <NUMBER>
 * 2: Lowest value <NUMBER>
 * 3: Highest value <NUMBER>
 * 4: Decimal places the setting stores <NUMBER>
 * 5: Rebuild the suite and reopen the settings screen <BOOL> (optional, default true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [QEGVAR(devices,phoneZoom), 0.005, 0.005, 0.1, 3] call jmfsb_tacpad_apps_fnc_settingStep
 *
 * Public: No
 */

params [["_name", "", [""]], ["_step", 0, [0]], ["_min", 0, [0]], ["_max", 1, [0]], ["_decimals", 2, [0]], ["_apply", true, [false]]];

private _scale = 10 ^ _decimals;
private _now = missionNamespace getVariable [_name, _min];
private _next = _min max (_max min (round ((_now + _step) * _scale) / _scale));

if (_next isEqualTo _now) exitWith {};

[_name, _next, _apply] call FUNC(setSetting);
