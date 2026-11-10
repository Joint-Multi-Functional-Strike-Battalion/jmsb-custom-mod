#include "script_component.hpp"
/*
 * Author: YonV
 * Marks a vehicle or a group - and everything inside it - as ALiVE's to leave
 * alone.
 *
 * THE VARIABLE IS ALiVE'S AND SO THIS IS THE ONLY PLACE IT MAY BE NAMED. Every
 * jmfsb system that spawns something and means to keep it was setting
 * ALIVE_profileIgnore by hand: air defence in three files, the patrol drones in
 * one, twelve references in all. That is a foreign symbol copied through four
 * addons and four places to fix when ALiVE renames it, and it is what
 * check_invariants.py had been failing on. They all come here now.
 *
 * WHAT IT BUYS: ALiVE's runtime profiler replaces objects with records that
 * walk the map, and it does that by DELETING what it was handed - see the note
 * in the drone top-up, which traced a fleet of vanishing airframes to exactly
 * that. An aircraft mid-strike, a battery mid-engagement or a MANPAD team on a
 * ridge must not be virtualised out from under the system that placed it. This
 * is ALiVE's own documented opt-out, honoured by the same function that does
 * the deleting.
 *
 * THE WHOLE SET, NOT THE HANDLE. The profiler tests a GROUP and spares it only
 * when every unit in it is exempt, so marking the vehicle alone leaves the crew
 * to fail the test and take the vehicle with them. Hardware, crew, and the
 * group the crew is in - all three, every time.
 *
 * OBJECT OR GROUP, because the callers have both: a drone is an airframe, a
 * security element is a group, and a battery is a list of guns whose gunners
 * live in a group of their own. Asking each caller to know which shape to
 * unpack is how the twelve copies happened.
 *
 * Arguments:
 * 0: The object or group <OBJECT|GROUP>
 *
 * Return Value: None
 *
 * Example:
 * [_veh] call jmfsb_adapter_alive_fnc_profileIgnore
 * [_grp] call jmfsb_adapter_alive_fnc_profileIgnore
 *
 * Public: Yes
 */

params ["_what"];

if (isNil "_what") exitWith {};

private _fnc_mark = {
    if (isNull _this) exitWith {};
    _this setVariable ["ALIVE_profileIgnore", true, true];
    // BOTH FLAGS, BECAUSE ALiVE READS A DIFFERENT ONE PER PASS. The runtime
    // profiler honours ALIVE_profileIgnore; the INITIAL editor sweep
    // (sys_profile fnc_createProfilesFromUnits) never reads it - the only
    // per-object variable that sweep checks before profiling a vehicle is
    // ALIVE_CombatSupport, ALiVE's own marker for hardware the profiler must
    // not take. Without it, every UAV-crewed static the sweep finds is
    // processed as an EMPTY vehicle - its B_UAV_AI crew group is skipped by
    // ALiVE's unit blacklist - and the profile round-trip hands back the
    // hull with the seat empty: the AA-with-no-AI bug. Groups also get the
    // variable; nothing reads it on a group, and one marker is simpler than
    // two shapes of marker.
    _this setVariable ["ALIVE_CombatSupport", true, true];
};

// A GROUP: itself, its men, and anything they are riding in - a security
// element in a truck is a group whose vehicle would otherwise be profiled out
// from under it.
if (_what isEqualType grpNull) exitWith {
    _what call _fnc_mark;
    {
        _x call _fnc_mark;
        private _veh = objectParent _x;
        if (!isNull _veh) then {_veh call _fnc_mark};
    } forEach (units _what);
};

if !(_what isEqualType objNull) exitWith {};
if (isNull _what) exitWith {};

_what call _fnc_mark;

// The crew and the group each of them is in. A vehicle's occupants are not
// always one group - a gunner seated from a different element is the case that
// makes reading `group _what` alone wrong.
{
    _x call _fnc_mark;
    (group _x) call _fnc_mark;
} forEach (crew _what);

(group _what) call _fnc_mark;
