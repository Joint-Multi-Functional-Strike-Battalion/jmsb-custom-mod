#include "script_component.hpp"
/*
 * Author: JMSB
 * The watch on one supply drop, every AIR_TICK seconds.
 *
 *   PARACHUTE  "in": the crate leaves the aircraft over the grid - released a
 *              couple of seconds' flying short of it, so the chute drifts onto
 *              it rather than past (FUNC(releaseCrate)) - then home
 *   SLING      "in": over the grid the helicopter comes down to set-down
 *              height; "lower": low and over the point (or out of patience)
 *              the hook is cut, the crate is marked, then home
 *
 * Arguments:
 * 0: [logic, aircraft, state] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(dropTick), 1, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

// Seconds of flight short of the grid a parachute crate is released.
#define CHUTE_LEAD_TIME 2
// And this much more, m, so the release is never late.
#define CHUTE_LEAD_EXTRA 80
// Where a sling helicopter starts coming down, m from the grid.
#define SLING_APPROACH 200
// Clearance over the set-down height that counts as low enough to cut.
#define SLING_CUT_SLACK 8

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_logic", "_veh", "_st"];

if (isNull _logic) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_veh] call FUNC(sweep);
};

if (!alive _veh) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_logic] call FUNC(finish);
};

private _phase = _st get "phase";
if (_phase in ["home", "homing", "parking"]) exitWith {
    if ([_logic, _veh, _st] call FUNC(homeTick)) then {[_handle] call CBA_fnc_removePerFrameHandler};
};

private _requester = _st get "requester";
private _crate = _st get "crate";

if ((_logic getVariable [QGVAR(abort), false]) || {CBA_missionTime > (_st get "until")}) exitWith {
    _logic setVariable [QGVAR(abort), false, true];
    if (!isNull _crate) then {
        _veh setSlingLoad objNull;
        deleteVehicle _crate;
    };
    [_logic, "aborting the drop, returning to base", "normal", _requester] call FUNC(say);
    _st set ["phase", "home"];
};

private _pos = _st get "pos";
private _d = _veh distance2D _pos;

if (!(_st get "sling")) exitWith {
    if (_d > CHUTE_LEAD_TIME * (speed _veh / 3.6) + CHUTE_LEAD_EXTRA) exitWith {};
    private _box = [_logic, _veh, _st getOrDefault ["load", ""], _st getOrDefault ["signal", ""]] call FUNC(releaseCrate);
    [_logic, format ["crate away over %1", mapGridPosition _box], "high", _requester] call FUNC(say);
    _st set ["phase", "home"];
};

switch (_phase) do {
    case "in": {
        if (_d > SLING_APPROACH) exitWith {};
        _veh flyInHeight SLING_SET_DOWN;
        [_veh, _pos, "LIMITED"] call FUNC(moveTo);
        _st set ["phase", "lower"];
        _st set ["since", CBA_missionTime];
        _logic setVariable [QGVAR(status), "setting down", true];
    };
    case "lower": {
        private _low = _d < SLING_RING && {((getPos _veh) select 2) < SLING_SET_DOWN + SLING_CUT_SLACK};
        if (!_low && {CBA_missionTime - (_st get "since") < SLING_PATIENCE}) exitWith {};
        _veh setSlingLoad objNull;
        if (!isNull _crate) then {[_crate, _st getOrDefault ["signal", ""]] call FUNC(markCrate)};
        [_logic, format ["load set down at %1", mapGridPosition _veh], "high", _requester] call FUNC(say);
        _veh flyInHeight SLING_CRUISE;
        _st set ["phase", "home"];
    };
};
