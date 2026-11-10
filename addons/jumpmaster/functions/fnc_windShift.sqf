#include "script_component.hpp"
/*
 * Author: YonV
 * SHIFT FOR WIND, automatic (user, 2026-11-02: the app's SHIFT PATH FOR WIND
 * button is gone with the app): the red and green lights moved upwind by the
 * stick's drift (FUNC(drift)), so a stick released at the new green light
 * lands on the one the leader asked for. Under WIND_MIN_M of drift the lights
 * stay where they are. The server asks it once, at the WILCO, which says how
 * far it moved them.
 *
 * Arguments:
 * 0: Jump type <STRING>
 * 1: RED LIGHT point <ARRAY>
 * 2: GREEN LIGHT point <ARRAY>
 * 3: The run's altitude, m (FUNC(typeAlt)) <NUMBER>
 *
 * Return Value:
 * 0: RED LIGHT flown <ARRAY>
 * 1: GREEN LIGHT flown <ARRAY>
 * 2: How far they moved, m, 0 none <NUMBER>
 *
 * Example:
 * (["HALO", _red, _green, 6000] call jmfsb_jumpmaster_fnc_windShift) params ["_red", "_green", "_shift"]
 *
 * Public: No
 */

params [["_type", TYPE_HALO, [""]], ["_red", [], [[]]], ["_green", [], [[]]], ["_alt", ALT_FREEFALL_DEFAULT, [0]]];

([_type, _alt] call FUNC(drift)) params ["_dx", "_dy"];
private _drift = [_dx, _dy, 0];
private _len = vectorMagnitude _drift;
if (_len < WIND_MIN_M) exitWith {[_red, _green, 0]};

[_red vectorDiff _drift, _green vectorDiff _drift, round _len]
