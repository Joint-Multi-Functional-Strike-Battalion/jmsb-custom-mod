#include "script_component.hpp"
/*
 * Author: JMSB
 * One missile or munition of a launch is gone - on target, shot down,
 * self-destructed or never launched. The last one ends the mission.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The mission's token <NUMBER>
 * 2: What the asset says about this one, "" for nothing <STRING> (optional, default "")
 *
 * Return Value: None
 *
 * Example:
 * [_logic, 3, "missile lost"] call jmfsb_support_fires_fnc_sortieDone
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_token", -1, [0]], ["_said", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
if (_token isNotEqualTo (_logic getVariable [QGVAR(token), -1])) exitWith {};

if (_said isNotEqualTo "") then {
    [QGVAR(say), [_logic, _said, "normal"]] call CBA_fnc_globalEvent;
};

private _left = (_logic getVariable [QGVAR(inFlight), 1]) - 1;
_logic setVariable [QGVAR(inFlight), _left];

if (_left <= 0) then {
    [_logic, _token, "mission complete"] call FUNC(finish);
};
