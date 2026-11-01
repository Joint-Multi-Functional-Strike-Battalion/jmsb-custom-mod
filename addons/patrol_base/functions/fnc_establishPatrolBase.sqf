#include "script_component.hpp"
/*
 * Author: JMSB
 * Runs on the building player's machine (from the Establish Patrol Base action).
 * Any player may build. Validates, prompts for a base name, then asks the server
 * to build it.
 *
 * Arguments: None
 * Return Value: None
 *
 * Example:
 * call jmfsb_patrol_base_fnc_establishPatrolBase
 *
 * Public: No
 */

private _builder = player;

if !(isNull objectParent _builder) exitWith {
    ["Patrol Base", "You must be on foot.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

private _req = missionNamespace getVariable [QGVAR(kitCount), 4];
private _max = missionNamespace getVariable [QGVAR(maxCount), 3];

private _have = [getPosATL _builder] call FUNC(countKits);
if (_have < _req) exitWith {
    ["Patrol Base", format ["Drop %1 Patrol Base Kits within range (found %2).", _req, _have], [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

if (count (missionNamespace getVariable [QGVAR(bases), []]) >= _max) exitWith {
    ["Patrol Base", format ["Patrol base limit reached (%1). Unbuild one first.", _max], [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

// Ask the player to name it, then hand off to the server.
[{
    params ["_name"];
    if (_name isEqualTo "") exitWith {
        ["Patrol Base", "Cancelled - no name given.", [1, 0.8, 0.3, 1]] call EFUNC(notify,notify);
    };
    // Only the name travels: the server takes the builder, his position and
    // his side from the sending machine (review S7, FUNC(serverBuild)).
    [_name] remoteExecCall [QFUNC(serverBuild), SERVER_OWNER];
}] call FUNC(promptName);
