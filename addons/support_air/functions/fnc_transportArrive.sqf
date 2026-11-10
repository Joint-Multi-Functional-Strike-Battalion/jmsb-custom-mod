#include "script_component.hpp"
/*
 * Author: YonV
 * A transport has reached its point: start what the task does there. The
 * phases it hands on are FUNC(transportStep)'s.
 *
 *   HOVER        holds a hover over the point                    -> "hold"
 *   LOITER       orbits it at the requested radius               -> "hold"
 *   EXTRACT      a low hover over the pickup, EXTRACT_HOVER m, never
 *                down (user, 2026-11-08)                        -> "landing"
 *   PICKUP, PICKUP > LZ, LAND, LAND ENG OFF, home
 *                lands (FUNC(landAt)): GET IN for PICKUP, GET OUT for
 *                LAND, LAND (shut down) for the rest - PICKUP > LZ too
 *                (2026-11-08: "pick up with the helo lands turns off"; it
 *                starts up for the insertion on its next order)  -> "landing"
 *   FASTROPE     comes down to the rope hover                    -> "ropeIn"
 *   RAPPEL       comes down to the rappel hover (2026-11-08)     -> "rappelIn"
 *                (a lift request's rope insertion: the control's cap
 *                INSERT_APPROACH_SPEED - in fast)
 *   HELOCAST     comes down to the water                         -> "castIn"
 *   PARADROP     green light short of the drop zone, straight on -> "jumping"
 *   SLINGLOAD    finds the nearest load it can lift, comes down to it
 *                                                                -> "hook"
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The helicopter <OBJECT>
 * 2: The watch's state <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _st] call jmfsb_support_air_fnc_transportArrive
 *
 * Public: No
 */

// How far past the drop zone a paradrop carries on straight before it turns
// for home (m).
#define PARADROP_RUN_OUT 1000

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]]];

private _task = _st getOrDefault ["task", TASK_HOME];
private _target = _st getOrDefault ["target", getPosATL _veh];
private _requester = _st getOrDefault ["requester", objNull];

private _fnc_hold = {
    params ["_status", "_line"];
    _st set ["phase", "hold"];
    _logic setVariable [QGVAR(status), _status, true];
    [_logic, _line, "normal", _requester] call FUNC(say);
};
// THE LOW HOVERS ARE THE FLIGHT CONTROL'S (2026-11-05, FUNC(heliTake)): the
// rope, the cast and the hook heights over the point, held until the task is
// done there and the AI gets the airframe back on the next order.
// A LIFT REQUEST'S ROPE INSERTION COMES IN FAST (user, 2026-11-08): the
// control's cap is INSERT_APPROACH_SPEED for it.
private _insertion = count (_logic getVariable [QGVAR(liftJob), createHashMap]) > 0;
private _fnc_lowHover = {
    params ["_height", "_why", ["_ignore", objNull]];
    private _cap = [HELI_APPROACH_SPEED, INSERT_APPROACH_SPEED] select (_insertion && {_task in [TASK_FASTROPE, TASK_RAPPEL]});
    [_veh, _target, _height, false, true, _cap, _why, _ignore] call FUNC(heliTake);
    _st set ["since", CBA_missionTime];
};

switch (_task) do {
    case TASK_MOVE: {
        ["holding", format ["holding over %1", mapGridPosition _target]] call _fnc_hold;
    };
    case TASK_ORBIT: {
        [_veh, _target, "LIMITED", "LOITER", _st getOrDefault ["radius", RADIUS_MIN]] call FUNC(moveTo);
        ["loitering", format ["orbiting %1 at %2 m", mapGridPosition _target, _st getOrDefault ["radius", RADIUS_MIN]]] call _fnc_hold;
    };
    case TASK_FASTROPE: {
        if !([typeOf _veh] call FUNC(canRope)) exitWith {
            ["holding", "cannot rope - holding a hover"] call _fnc_hold;
        };
        // 2 is "FRIES fitted on request"; 1 is built in.
        if (getNumber (configOf _veh >> "ace_fastroping_enabled") isEqualTo 2 && {!isNil "ace_fastroping_fnc_equipFRIES"}) then {
            [_veh] call ace_fastroping_fnc_equipFRIES;
        };
        // The rope item, topped up for this drop - the players aboard deploy
        // ropes with it if they go after the AI's are cut (FUNC(stockRopes)).
        [_logic, _veh] call FUNC(stockRopes);
        [FASTROPE_HOVER, "the rope hover"] call _fnc_lowHover;
        _st set ["phase", "ropeIn"];
        _logic setVariable [QGVAR(status), "fast-roping", true];
    };
    // THE RAPPEL (user, 2026-11-08: "a simplex like repel"): any airframe, its
    // own ropes - out once it holds the hover (FUNC(transportStep)).
    case TASK_RAPPEL: {
        [RAPPEL_HOVER, "the rappel hover"] call _fnc_lowHover;
        _st set ["phase", "rappelIn"];
        _logic setVariable [QGVAR(status), "rappelling", true];
    };
    case TASK_HELOCAST: {
        [HELOCAST_HEIGHT, "the cast hover"] call _fnc_lowHover;
        _st set ["phase", "castIn"];
        _logic setVariable [QGVAR(status), "helocast", true];
    };
    case TASK_PARADROP: {
        // Straight on through the drop zone while the stick goes.
        [_veh, _target getPos [PARADROP_RUN_OUT, _veh getDir _target], _st getOrDefault ["speed", "NORMAL"]] call FUNC(moveTo);
        _st set ["phase", "jumping"];
        _logic setVariable [QGVAR(status), "jumping", true];
        [_logic, format ["green light over %1", mapGridPosition _veh], "high", _requester] call FUNC(say);
    };
    case TASK_SLING: {
        private _load = ((nearestObjects [_target, SLING_LOAD_KINDS, SLING_SEARCH]) select {
            _x isNotEqualTo _veh && {alive _x} && {!(_x isKindOf "CAManBase")} && {_veh canSlingLoad _x}
        }) param [0, objNull];
        if (isNull _load) exitWith {
            ["holding", format ["nothing it can lift within %1 m of %2 - holding", SLING_SEARCH, mapGridPosition _target]] call _fnc_hold;
        };
        _st set ["load", _load];
        _st set ["target", getPosATL _load];
        _target = getPosATL _load;
        // The load is what it hovers over, not a surface under it.
        [SLING_HOOK_HEIGHT, "the hook", _load] call _fnc_lowHover;
        _st set ["phase", "hook"];
        _logic setVariable [QGVAR(status), "hooking", true];
        [_logic, format ["over the load at %1, hooking %2", mapGridPosition _load, getText (configOf _load >> "displayName")], "normal", _requester] call FUNC(say);
    };
    // THE EXTRACTION NEVER TOUCHES DOWN (user, 2026-11-08: "a low hover never
    // touching"): the flight control holds it over the pickup while the group
    // climbs in; FUNC(transportStep) loads it there as if landed.
    case TASK_EXTRACT: {
        [EXTRACT_HOVER, "the extraction hover"] call _fnc_lowHover;
        _st set ["phase", "landing"];
        _logic setVariable [QGVAR(status), "landing", true];
    };
    default {
        private _mode = switch (_task) do {
            case TASK_PICKUP: {"GET IN"};
            case TASK_LAND: {"GET OUT"};
            default {"LAND"};
        };
        // The pad is moved clear of anything in the rotor's way (2026-11-02,
        // FUNC(clearSpot)) - home too, when the stand is on the ground.
        private _homeASL = _logic getVariable [QGVAR(homeASL), AGLToASL _target];
        private _clear = _task isNotEqualTo TASK_HOME || (_homeASL select 2) - getTerrainHeightASL _homeASL < ROTOR_DISC_LOW;
        [_veh, _target, _mode, _clear] call FUNC(landAt);
        _st set ["mode", _mode];
        _st set ["clearPad", _clear];
        _st set ["phase", "landing"];
        _st set ["since", CBA_missionTime];
        _logic setVariable [QGVAR(status), "landing", true];
    };
};
