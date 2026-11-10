#include "script_component.hpp"
/*
 * Author: YonV
 * Profiles spawned hardware and its crews - rule 3, every jmfsb spawn is
 * profiled, extended to vehicles as well as men.
 *
 * Same clear-then-profile order as FUNC(profileGroup): the runtime function
 * skips anything already carrying a profileID.
 *
 * PROFILING VIRTUALISES. The objects handed in are deleted and replaced by
 * profiles that ALiVE spawns again near players. Callers must not hold the
 * references afterwards - find the hardware by position instead.
 *
 * Arguments:
 * 0: Vehicles <ARRAY of OBJECT>
 * 1: Groups (their crews) <ARRAY of GROUP> (optional, default their own)
 *
 * Return Value:
 * [groupProfiles, vehicleProfiles] <ARRAY>
 *
 * Example:
 * [[_radar, _launcher]] call jmfsb_adapter_alive_fnc_profileObjects
 */

params [["_vehicles", [], [[]]], ["_groups", [], [[]]]];

if (!GVAR(ready)) exitWith {[[], []]};

_vehicles = _vehicles select {!isNull _x};
if (_vehicles isEqualTo [] && {_groups isEqualTo []}) exitWith {[[], []]};

if (_groups isEqualTo []) then {
    {
        private _g = group ((crew _x) param [0, objNull]);
        if (!isNull _g) then { _groups pushBackUnique _g };
    } forEach _vehicles;
};

{
    { _x setVariable ["profileID", ""] } forEach (units _x);
} forEach _groups;
{ _x setVariable ["profileID", ""] } forEach _vehicles;

// NORMALISED ON THE WAY OUT, AND TRUSTING NOTHING ABOUT THE SHAPE.
//
// ALiVE's runtime profiler is documented to return [groupProfiles,
// vehicleProfiles], and mostly does - but it has been seen handing back a
// bare STRING in a slot, and my first normaliser assumed two arrays and
// error-spammed the RPT on the one run where that was false. A seam that
// crashes on unexpected input is not a seam. Every shape is accepted here:
// a non-array return, a slot that is one profile rather than a list of
// them, a bare id string, nil. Consumers see two arrays of profile hashes
// or nothing, always.
private _raw = [false, _groups, _vehicles] call ALIVE_fnc_createProfilesFromUnitsRuntime;

private _fnc_norm = {
    params ["_slot"];

    // one profile, or one id, handed over bare rather than in a list
    private _list = if (_slot isEqualType []) then {_slot} else {
        // Said ONCE - this runs from per-frame handlers, and the point is to
        // learn the real shape, not to fill the RPT with it again.
        if (!GVAR(shapeLogged)) then {
            GVAR(shapeLogged) = true;
            WARNING_1("ALiVE's profiler returned a bare %1 in a profile slot - normalising it",typeName _slot);
        };
        [_slot]
    };

    private _out = [];
    {
        private _p = _x;
        if (_p isEqualType "") then {
            if (_p isEqualTo "") then {continue};
            _p = [ALIVE_profileHandler, "getProfile", _p] call ALIVE_fnc_profileHandler;
        };
        if (!isNil "_p" && {_p isEqualType []} && {_p isNotEqualTo []}) then {
            _out pushBack _p;
        };
    } forEach _list;
    _out
};

if (isNil "_raw" || {!(_raw isEqualType [])}) exitWith {
    WARNING_1("ALiVE's runtime profiler returned %1 - nothing profiled this pass",_raw);
    [[], []]
};

[[_raw param [0, []]] call _fnc_norm, [_raw param [1, []]] call _fnc_norm]
