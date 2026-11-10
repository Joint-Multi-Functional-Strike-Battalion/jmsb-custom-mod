#include "script_component.hpp"
/*
 * Author: YonV
 * The id of a profile entity.
 *
 * Exists so no feature addon has to name an ALiVE function to ask a profile
 * what it is called - the seam is the point, and a one-line read is exactly
 * the kind of thing that quietly breaks it.
 *
 * Arguments:
 * 0: Profile entity <ARRAY>
 *
 * Return Value:
 * Profile id, "" if it has none <STRING>
 *
 * Example:
 * [_profile] call jmfsb_adapter_alive_fnc_profileIdOf
 */

// A bare id string is already the answer - ALiVE hands both shapes around,
// and a reader should not error on the one that needs no reading.
params [["_profile", [], [[], ""]]];

if (_profile isEqualType "") exitWith {_profile};
if (_profile isEqualTo []) exitWith {""};

[_profile, "profileID"] call ALIVE_fnc_profileEntity
