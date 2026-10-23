#include "script_component.hpp"
/*
 * Author: JMSB
 * The watch on one QRF insertion, every JUMP_INTERVAL seconds - which is also
 * the spacing between jumpers. Phases:
 *
 *   "in"        inbound. A static-line stick starts a couple of seconds'
 *               flying short of the grid, and half the stick's length more,
 *               so it is centred on the grid. An AIR ASSAULT, near the grid,
 *               fast-ropes if it can (ACE fast-roping loaded and the airframe
 *               has FRIES) and lands if it cannot
 *   "jumping"   one man out per tick (FUNC(jump)) until the cabin is empty,
 *               then home; the squad gets its task when the last one is down
 *   "ropeIn"    hovering in over the grid; settled, ACE puts the squad on
 *               the ropes
 *   "landing"   coming down; settled, the squad gets out
 *   "dismount"  waiting for the squad to be on the ground, then it gets its
 *               task (FUNC(qrfLanded)) and the helicopter lifts for home
 *   home legs   FUNC(homeTick)
 *
 * RTB before anyone is out brings the squad home with the aircraft. Once the
 * first man is out the insertion is finished first.
 *
 * Arguments:
 * 0: [logic, aircraft, state] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(qrfTick), 0.7, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

// Seconds of flight short of the grid the first man goes.
#define JUMP_LEAD_TIME 2
// And this much more, m, so the first man is never late.
#define JUMP_LEAD_EXTRA 80
// An air assault starts its approach this far from the grid, m.
#define ASSAULT_APPROACH 500
// Over the rope point: this close (m) and this slow (km/h).
#define ROPE_RING 40
#define ROPE_SPEED 10
// A man this close to the ground counts as down.
#define DOWN_HEIGHT 2

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_logic", "_veh", "_st"];

if (isNull _logic) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_veh] call FUNC(sweep);
};

if (!alive _veh) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    // Whoever is already out still gets a job: the squad's task is otherwise
    // only handed over at the end of the stick or the dismount. Down means
    // landed or near the ground, so a dismount - or a crash at the grid while
    // roping in or landing - is tasked at once and a stick once its chutes are
    // in; qrfLanded's tasked guard makes a repeat harmless.
    if ((_st get "phase") in ["jumping", "ropeIn", "landing", "dismount"]) then {
        [
            {(units (_this select 1)) findIf {alive _x && {!(_x getVariable [QGVAR(landed), false])} && {((getPos _x) select 2) > DOWN_HEIGHT}} < 0},
            {_this call FUNC(qrfLanded)},
            [_logic, _st get "group", _st get "pos", _st get "requester"],
            DESCENT_PATIENCE,
            {_this call FUNC(qrfLanded)}
        ] call CBA_fnc_waitUntilAndExecute;
    };
    [_logic] call FUNC(finish);
};

private _phase = _st get "phase";
if (_phase in ["home", "homing", "parking"]) exitWith {
    if ([_logic, _veh, _st] call FUNC(homeTick)) then {[_handle] call CBA_fnc_removePerFrameHandler};
};

private _task = _st get "task";
private _pos = _st get "pos";
private _grp = _st get "group";
private _requester = _st get "requester";

if (_phase in ["in", "ropeIn", "landing"] && {(_logic getVariable [QGVAR(abort), false]) || {CBA_missionTime > (_st get "until")}}) exitWith {
    _logic setVariable [QGVAR(abort), false, true];
    [_logic, "aborting the insertion, squad returning to base", "normal", _requester] call FUNC(say);
    _st set ["phase", "home"];
};

private _fnc_squadDown = {
    [_logic, _grp, _pos, _requester] call FUNC(qrfLanded);
    _veh land "NONE";
    _veh flyInHeight ASSAULT_CRUISE;
    if (!isNil "ace_fastroping_fnc_cutRopes" && {(_veh getVariable ["ace_fastroping_deployedRopes", []]) isNotEqualTo []}) then {
        [_veh] call ace_fastroping_fnc_cutRopes;
    };
    _st set ["phase", "home"];
};

switch (_phase) do {
    case "in": {
        if (_task isEqualTo TASK_ASSAULT) exitWith {
            if (_veh distance2D _pos > ASSAULT_APPROACH) exitWith {};
            private _cfg = configOf _veh;
            private _rope = EGVAR(common,aceFastroping) && {!isNil "ace_fastroping_fnc_deployAI"} && {getNumber (_cfg >> "ace_fastroping_enabled") > 0};
            if (_rope) then {
                // 2 is "FRIES fitted on request"; 1 is built in.
                if (getNumber (_cfg >> "ace_fastroping_enabled") isEqualTo 2 && {!isNil "ace_fastroping_fnc_equipFRIES"}) then {
                    [_veh] call ace_fastroping_fnc_equipFRIES;
                };
                _veh flyInHeight FASTROPE_HOVER;
                [_veh, _pos, "LIMITED"] call FUNC(moveTo);
                _st set ["phase", "ropeIn"];
            } else {
                [_veh, _pos, "GET OUT"] call FUNC(landAt);
                _st set ["phase", "landing"];
            };
            _st set ["since", CBA_missionTime];
            _logic setVariable [QGVAR(status), ["landing", "fast-roping"] select _rope, true];
        };

        private _ms = speed _veh / 3.6;
        private _lead = JUMP_LEAD_TIME * _ms + JUMP_LEAD_EXTRA + count (_st get "jumpers") * JUMP_INTERVAL * _ms / 2;
        if (_veh distance2D _pos > _lead) exitWith {};
        _st set ["phase", "jumping"];
        _logic setVariable [QGVAR(status), "jumping", true];
        [_logic, format ["green light over %1", mapGridPosition _veh], "high", _requester] call FUNC(say);
    };
    case "jumping": {
        private _jumpers = _st get "jumpers";
        private _next = objNull;
        while {isNull _next && {_jumpers isNotEqualTo []}} do {
            private _u = _jumpers deleteAt 0;
            if (alive _u && {vehicle _u isEqualTo _veh}) then {_next = _u};
        };
        if (!isNull _next) then {
            [_next, _veh] call FUNC(jump);
        };
        if (_jumpers isNotEqualTo []) exitWith {};

        _st set ["phase", "home"];
        [_logic, "stick is out, returning to base", "normal", _requester] call FUNC(say);
        [
            {(units (_this select 1)) findIf {alive _x && {!(_x getVariable [QGVAR(landed), false])}} < 0},
            {_this call FUNC(qrfLanded)},
            [_logic, _grp, _pos, _requester],
            DESCENT_PATIENCE,
            {_this call FUNC(qrfLanded)}
        ] call CBA_fnc_waitUntilAndExecute;
    };
    case "ropeIn": {
        private _over = _veh distance2D _pos < ROPE_RING && {speed _veh < ROPE_SPEED};
        if (!_over && {CBA_missionTime - (_st get "since") < LANDING_PATIENCE}) exitWith {};
        [_veh, false, false] call ace_fastroping_fnc_deployAI;
        _st set ["phase", "dismount"];
        _st set ["since", CBA_missionTime];
    };
    case "landing": {
        if !(isTouchingGround _veh && {speed _veh < SETTLED_SPEED}) exitWith {
            if (CBA_missionTime - (_st get "since") > LANDING_PATIENCE) then {
                [_veh, _pos, "GET OUT"] call FUNC(landAt);
                _st set ["since", CBA_missionTime];
            };
        };
        {
            unassignVehicle _x;
            moveOut _x;
        } forEach ((units _grp) select {vehicle _x isEqualTo _veh});
        _st set ["phase", "dismount"];
        _st set ["since", CBA_missionTime];
    };
    case "dismount": {
        private _out = (units _grp) findIf {alive _x && {vehicle _x isEqualTo _veh || {((getPos _x) select 2) > DOWN_HEIGHT}}} < 0;
        if (!_out && {CBA_missionTime - (_st get "since") < DISMOUNT_PATIENCE}) exitWith {};
        call _fnc_squadDown;
        [_logic, "squad is on the ground, lifting for base", "normal", _requester] call FUNC(say);
    };
};
