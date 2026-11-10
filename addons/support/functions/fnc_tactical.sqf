#include "script_component.hpp"
/*
 * Author: YonV
 * Server: puts a support aircraft on the tactical lights watch, from now until
 * it is deleted or lost (user, 2026-11-01: "with support aircraft all actions
 * need to be tactical lights only over the airfield that start at in the
 * fiels no lights stealth as much as possiable"). Every provider calls it
 * once for every aircraft it flies; calling it again for the same aircraft
 * replaces its airfield.
 *
 * THE AIRFIELD IS WHERE IT STARTED - its module, base or stand on the ground.
 * An aircraft that is made in the air at a distance has none and is dark from
 * the start. Inside AIRFIELD_LIGHTS_RADIUS of it the AI keeps its normal
 * lights; everywhere else FUNC(tacticalLights) holds them off.
 *
 * ONE WATCH FOR EVERY PROVIDER (FUNC(tacticalTick)), started by the first
 * aircraft registered, every TACTICAL_TICK seconds - not a loop per aircraft
 * and not a check per frame. The core knows no asset kind: it is handed a
 * vehicle and a point.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Its airfield, [x, y] or [x, y, z]; [] for none <ARRAY>
 *
 * Return Value:
 * Registered <BOOL>
 *
 * Example:
 * [_veh, getPosATL _logic] call jmfsb_support_fnc_tactical
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_airfield", [], [[]]]];

if (!isServer || {!alive _veh}) exitWith {false};

private _field = if (count _airfield < 2) then {[]} else {[_airfield select 0, _airfield select 1]};

if (isNil QGVAR(tactical)) then {
    GVAR(tactical) = [];
    [FUNC(tacticalTick), TACTICAL_TICK] call CBA_fnc_addPerFrameHandler;
};

private _i = GVAR(tactical) findIf {(_x select 0) isEqualTo _veh};
if (_i < 0) then {
    GVAR(tactical) pushBack [_veh, _field];
} else {
    GVAR(tactical) set [_i, [_veh, _field]];
};

// At once, not on the next tick: an aircraft made in the field is never seen
// lit.
[_veh, _field] call FUNC(tacticalLights);

true
