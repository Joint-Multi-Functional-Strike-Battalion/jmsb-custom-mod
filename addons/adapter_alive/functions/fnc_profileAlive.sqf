#include "script_component.hpp"
/*
 * Author: YonV
 * Does ALiVE still know this profile id? The seam the uas patrol prune
 * needed: its keep-predicate for profiled patrols had decayed into a bare
 * function-existence check - a constant - so dead profiled patrols counted
 * against the ceiling forever. The adapter is the only addon allowed to
 * know ALiVE's names, so the actual lookup lives here.
 *
 * Answers TRUE when it cannot ask - an adapter that is not ready is no
 * reason to cull somebody's patrol.
 *
 * Arguments:
 * 0: Profile id <STRING>
 *
 * Return Value:
 * The profile still exists <BOOL>
 *
 * Public: No
 */

params [["_id", "", [""]]];

if (_id isEqualTo "") exitWith {false};
if (!GVAR(ready) || {isNil "ALIVE_profileHandler"}) exitWith {true};

private _p = [ALIVE_profileHandler, "getProfile", _id] call ALIVE_fnc_profileHandler;
!isNil "_p"
