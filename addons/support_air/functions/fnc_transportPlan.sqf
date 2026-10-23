#include "script_component.hpp"
/*
 * Author: JMSB
 * Turns a transport order into a flight: height, speed, what the door guns
 * may do, the lights, and the legs to where it is going - the VIA points in
 * order, then the final approach point when a bearing was picked, then the
 * point itself. What happens when it gets there is FUNC(transportArrive)'s.
 *
 * THE DOOR GUNS ARE THE REQUESTER'S CALL (the DOOR GUNS stepper). Return fire
 * and fire at will put the crew AWARE so the gunners engage; hold fire keeps
 * the whole crew CARELESS, which is also the pilot that does not break off a
 * landing to dodge.
 *
 * THE PLAN IS PUBLISHED on the module (QGVAR(plan), [[pos, label], ...]) so
 * TAC//SUPPORT draws the route as task markers on its map, the way Simplex
 * joins a transport's task icons with lines.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The helicopter <OBJECT>
 * 2: The watch's state <HASHMAP>
 * 3: The order [task, pos, requester, height, speed index, ROE index, wait, options] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _st, _order] call jmfsb_support_air_fnc_transportPlan
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]], ["_order", [], [[]]]];

_order params [
    ["_task", TASK_MOVE, [""]],
    ["_pos", [], [[]]],
    ["_requester", objNull, [objNull]],
    ["_height", HOME_HEIGHT, [0]],
    ["_speed", 0, [0]],
    ["_roe", 0, [0]],
    ["_wait", 0, [0]],
    ["_opts", createHashMap, [createHashMap]]
];

private _grp = group driver _veh;
private _combat = ROE_COMBAT param [_roe, "GREEN"];
_grp setCombatMode _combat;
_grp setBehaviour (["AWARE", "CARELESS"] select (_combat isEqualTo "BLUE"));

private _lights = _opts getOrDefault ["lights", true];
_veh setPilotLight _lights;
_veh setCollisionLight _lights;

_veh engineOn true;
_veh land "NONE";
_veh flyInHeight _height;

// THE LEGS. A final approach is a point APPROACH_LEG out on the picked
// bearing, flown last before the point - it is how the helicopter comes in.
private _legs = +(_opts getOrDefault ["via", []]);
private _bearing = _opts getOrDefault ["approach", -1];
if (_bearing >= 0 && _task isNotEqualTo TASK_HOME) then {
    _legs pushBack (_pos getPos [APPROACH_LEG, _bearing]);
};
private _speedWord = SPEED_WORDS param [_speed, "NORMAL"];
[_veh, _legs param [0, _pos], _speedWord] call FUNC(moveTo);

_st set ["task", _task];
_st set ["target", _pos];
_st set ["requester", _requester];
_st set ["wait", _wait];
_st set ["height", _height];
_st set ["speed", _speedWord];
_st set ["legs", _legs];
_st set ["lz", _opts getOrDefault ["lz", []]];
_st set ["signal", _opts getOrDefault ["signal", SIGNAL_NONE]];
_st set ["radius", _opts getOrDefault ["radius", RADIUS_MIN]];
_st set ["opts", _opts];
_st set ["signalLooked", false];
_st set ["phase", "transit"];

private _plan = (_opts getOrDefault ["via", []]) apply {[_x, "VIA"]};
if (_bearing >= 0 && _task isNotEqualTo TASK_HOME) then {_plan pushBack [_legs select -1, "APPROACH"]};
_plan pushBack [_pos, [_task, PLAN_BASE] select (_task isEqualTo TASK_HOME)];
if ((_st get "lz") isNotEqualTo []) then {_plan pushBack [_st get "lz", ["LZ", "SET DOWN"] select (_task isEqualTo TASK_SLING)]};
_logic setVariable [QGVAR(plan), _plan, true];

private _word = switch (_task) do {
    case TASK_HOME: {"rtb"};
    case TASK_PICKUP;
    case TASK_LIFT: {"to pickup"};
    case TASK_EXTRACT: {"to extract"};
    case TASK_MOVE: {"moving"};
    case TASK_ORBIT: {"to orbit"};
    case TASK_PARADROP: {"to drop zone"};
    case TASK_SLING: {"to load"};
    default {"to LZ"};
};
_logic setVariable [QGVAR(status), _word, true];
