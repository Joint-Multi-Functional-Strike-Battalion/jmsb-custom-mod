#include "script_component.hpp"
/*
 * Author: YonV
 * Autofill source "wind" (report-card review, user 2026-11-02, D27): the
 * wind as the game has it, for an HLZ's WIND line - where it blows FROM, in
 * three figures, and how hard. The engine's wind is a velocity (where the air
 * goes), so the bearing is turned round.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * "FROM 270 - 5 M/S", or "CALM" <STRING>
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_autoWind
 *
 * Public: No
 */

wind params ["_wx", "_wy"];
private _speed = vectorMagnitude [_wx, _wy, 0];
if (_speed < AUTO_WIND_CALM) exitWith {AUTO_WIND_CALM_TEXT};

private _from = (round ((_wx atan2 _wy) + AUTO_HALF_TURN + AUTO_FULL_TURN)) mod AUTO_FULL_TURN;

format [AUTO_WIND_TEXT, [_from, AUTO_BEARING_DIGITS] call CBA_fnc_formatNumber, round _speed]
