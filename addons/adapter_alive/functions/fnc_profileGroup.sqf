#include "script_component.hpp"
/*
 * Author: YonV
 * Hands a live group to ALiVE's profile system - the Jman path, and rule 3:
 * every jmfsb spawn is profiled.
 *
 * Clearing profileID first is what createProfilesFromUnitsRuntime keys on: it
 * skips units that already carry one (sys_profile
 * fnc_createProfilesFromUnitsRuntime.sqf:70, and the same clear-then-profile
 * order in sup_group_manager fnc_groupHandler.sqf:325-334).
 *
 * PROFILING VIRTUALISES: the live units are deleted and replaced by a profile
 * that walks the map and materialises near players. Callers must not hold
 * object references across this.
 *
 * Returns the profile ENTITY rather than an id, because that is what
 * ALIVE_fnc_profileEntity takes - the runtime function returns
 * [groupProfiles, vehicleProfiles] (fnc_createProfilesFromUnitsRuntime.sqf:417).
 *
 * Arguments:
 * 0: Group <GROUP>
 *
 * Return Value:
 * The group's profile entity, [] when profiling failed <ARRAY>
 *
 * Example:
 * private _p = [_grp] call jmfsb_adapter_alive_fnc_profileGroup;
 */

params [["_grp", grpNull, [grpNull]]];

if (!GVAR(ready) || {isNull _grp} || {(units _grp) isEqualTo []}) exitWith {[]};

{
    _x setVariable ["profileID", ""];
} forEach (units _grp);

private _made = [false, [_grp], []] call ALIVE_fnc_createProfilesFromUnitsRuntime;

(_made param [0, []]) param [0, []]
