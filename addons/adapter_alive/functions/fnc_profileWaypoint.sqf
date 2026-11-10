#include "script_component.hpp"
/*
 * Author: YonV
 * Sends a profiled group somewhere, virtually: the profile walks the map
 * without its units existing and materialises near players.
 *
 * The call is "addWaypoint" on ALIVE_fnc_profileEntity - NOT ALIVE_fnc_profile,
 * which has no such operation and would accept the call and do nothing. The
 * pattern is ALiVE's own (mil_c2istar/tasks/fnc_taskCheckpointPartnership.sqf
 * :126-128).
 *
 * Waypoint argument order is createProfileWaypoint's own
 * (sys_profile/fnc_createProfileWaypoint.sqf:44-58) - note the SECOND
 * argument is the random PLACEMENT radius, and the completion radius is the
 * fifth. Passing a completion radius in slot two is the easy mistake and
 * scatters the destination instead of tightening it.
 *
 * Arguments:
 * 0: Profile entity, as FUNC(profileGroup) returns <ARRAY>
 * 1: Destination <ARRAY>
 * 2: Completion radius (m) <NUMBER> (optional, default 50)
 * 3: Waypoint type <STRING> (optional, default "MOVE")
 *
 * Return Value:
 * Waypoint handed over <BOOL>
 *
 * Example:
 * [_profile, getPosATL player, 100] call jmfsb_adapter_alive_fnc_profileWaypoint
 */

params [
    ["_profile", [], [[], ""]],
    ["_pos", [], [[]]],
    ["_radius", 50, [0]],
    ["_type", "MOVE", [""]]
];

if (!GVAR(ready) || {_pos isEqualTo []}) exitWith {false};

// ALiVE hands profiles around as hashes AND as bare id strings - resolve the
// string shape here rather than erroring on it.
if (_profile isEqualType "") then {
    _profile = if (_profile isEqualTo "") then {[]} else {
        private _p = [ALIVE_profileHandler, "getProfile", _profile] call ALIVE_fnc_profileHandler;
        if (isNil "_p") then {[]} else {_p}
    };
};
if (_profile isEqualTo []) exitWith {false};

private _wp = [_pos, 0, _type, "UNCHANGED", _radius] call ALIVE_fnc_createProfileWaypoint;
[_profile, "addWaypoint", _wp] call ALIVE_fnc_profileEntity;

true
