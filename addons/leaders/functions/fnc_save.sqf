#include "script_component.hpp"
/*
 * Author: YonV
 * Persists which leaders are spent, so a restart resumes the campaign rather
 * than undoing it. The dead stay dead (rule 5: finite, no regeneration).
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

// Not kept when ALiVE is loaded with no commanders either (user, 2026-11-02:
// "same as not loaded") - FUNC(start) does not read it back then.
if (isNil QEFUNC(adapter_alive,setData) || {!([] call EFUNC(common,aliveLoaded))}) exitWith {};

private _spent = [];
{
    if ((_x select 2) isNotEqualTo "up") then { _spent pushBack _forEachIndex };
} forEach GVAR(leaders);

[QGVAR(spent), _spent] call EFUNC(adapter_alive,setData);
