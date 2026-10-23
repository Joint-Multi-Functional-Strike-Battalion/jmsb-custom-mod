#include "script_component.hpp"
/*
 * Author: JMSB
 * Ends a mission: the asset reads idle again, its cooldown starts now, the
 * target marker comes off the map, and the token moves on so anything still
 * queued for this mission does nothing.
 *
 * THE COOLDOWN IS SIMPLEX'S: the module's cooldown plus its cooldown per round
 * for every round (or missile) the mission actually fired. When it runs out
 * the asset says it is ready again - if it has anything left to fire.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The mission's token <NUMBER>
 * 2: What the asset says, "" for nothing <STRING> (optional, default "")
 *
 * Return Value: None
 *
 * Example:
 * [_logic, 3, "rounds complete"] call jmfsb_support_fires_fnc_finish
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_token", -1, [0]], ["_said", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
if (_token isNotEqualTo (_logic getVariable [QGVAR(token), -1])) exitWith {};

private _cooldown = (_logic getVariable [QGVAR(cooldown), 0])
    + (_logic getVariable [QGVAR(fired), 0]) * (_logic getVariable [QGVAR(roundCooldown), 0]);

_logic setVariable [QGVAR(token), _token + 1];
_logic setVariable [QGVAR(status), STATUS_IDLE, true];
_logic setVariable [QGVAR(abort), false, true];
_logic setVariable [QGVAR(claimed), []];
_logic setVariable [QGVAR(fired), 0];
_logic setVariable [QGVAR(readyAt), CBA_missionTime + _cooldown, true];

[_logic] call FUNC(unmark);

if (_said isNotEqualTo "") then {
    [QGVAR(say), [_logic, _said, "normal"]] call CBA_fnc_globalEvent;
};

if (_cooldown > 0 && {([_logic] call FUNC(ordnance)) isNotEqualTo []}) then {
    [_logic, _token + 1, "rearmed, ready for tasking", "normal", _cooldown] call FUNC(sayLater);
};

// Hoisted: a comma inside a macro argument reads as an argument separator.
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
INFO_3("%1 mission %2 finished, cooldown %3 s",_callsign,_token,round _cooldown);
