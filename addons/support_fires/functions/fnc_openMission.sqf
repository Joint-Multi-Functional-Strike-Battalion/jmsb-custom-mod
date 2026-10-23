#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens a new mission on an asset, on the server: a new token, the recall
 * flag down, nothing claimed, no rounds counted yet.
 *
 * THE MISSION TOKEN. Every order bumps the logic's token and every delayed
 * piece of a mission - a scheduled round, a splash call, the finish - carries
 * the token it was made under. A recall or a finish moves the token on, and
 * whatever was still queued for the old mission sees it and does nothing.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The mission's token <NUMBER>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_openMission
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {-1};

private _token = (_logic getVariable [QGVAR(token), 0]) + 1;
_logic setVariable [QGVAR(token), _token];
_logic setVariable [QGVAR(abort), false, true];
_logic setVariable [QGVAR(claimed), []];
_logic setVariable [QGVAR(fired), 0];
_logic setVariable [QGVAR(partners), []];

_token
