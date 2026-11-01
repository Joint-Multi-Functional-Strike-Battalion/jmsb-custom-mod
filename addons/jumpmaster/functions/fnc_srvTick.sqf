#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the watch on one run, every RUN_TICK seconds. Phases:
 *
 *   "in"      flying the line; past the red light -> "red"
 *   "red"     RED LIGHT said, JUMP open to every man; past the green light
 *             -> "green"
 *   "green"   GREEN LIGHT said. Automatic exit: this pass's share out one
 *             every JUMP_INTERVAL (FUNC(jump) by remoteExec, where each is local).
 *             Manual: the window is WINDOW_LEN past the green light. The pass
 *             done, with passes left and men aboard -> "circle"; else nobody
 *             aboard -> "leave", or -> "hold"
 *   "circle"  back to the start of the run-in, then the line again -> "in"
 *   "hold"    orbiting the drop zone while men are still aboard after the
 *             last pass or an abort; empty -> "leave"
 *   "leave"   away down the line; far enough, or out of time -> over
 *
 * The aircraft lost, or the run older than RUN_MAX_S: over (FUNC(srvEnd)).
 *
 * Arguments:
 * 0: [the run] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [jmfsb_jumpmaster_fnc_srvTick, 0.5, [_st]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params [["_st", createHashMap, [createHashMap]]];

private _veh = _st get "veh";
if (!alive _veh || {CBA_missionTime - (_st get "started") > RUN_MAX_S}) exitWith {[_st, _handle] call FUNC(srvEnd)};

private _dir = _st get "dir";
private _red = _st get "red";
private _green = _st get "green";
private _pos = getPos _veh;
// How far along the line the aircraft is past a point (behind it: negative).
private _fnc_past = {
    params ["_from"];
    ((_pos vectorDiff [_from select 0, _from select 1, 0]) vectorDotProduct [sin _dir, cos _dir, 0])
};
private _aboard = (_st get "jumpers") select {alive _x && {vehicle _x isEqualTo _veh || {attachedTo _x isEqualTo _veh}}};
private _fnc_phase = {
    params ["_phase", "_text", "_mayJump"];
    _st set ["phase", _phase];
    [_st, _text, _mayJump] call FUNC(srvLight);
};

switch (_st get "phase") do {
    case PHASE_IN: {
        if (([_red] call _fnc_past) < 0) exitWith {};
        [PHASE_RED, ["RED LIGHT. Stand by.", "RED LIGHT. Stand up, hook up."] select ((_st get "type") isEqualTo TYPE_STATIC), true] call _fnc_phase;
    };

    case PHASE_RED: {
        if (([_green] call _fnc_past) < 0) exitWith {};
        _st set ["lastOut", 0];
        [PHASE_GREEN, "GREEN LIGHT. GO.", true] call _fnc_phase;
    };

    case PHASE_GREEN: {
        private _pass = _st get "pass";
        private _auto = (_st get "exit") isEqualTo EXIT_AUTO;
        private _mine = ((_st get "stick") param [_pass, []]) select {_x in _aboard};
        if (_auto && {_mine isNotEqualTo []} && {CBA_missionTime - (_st get "lastOut") >= JUMP_INTERVAL}) exitWith {
            private _next = _mine select 0;
            _st set ["lastOut", CBA_missionTime];
            [_next, _veh, _st get "type"] remoteExecCall [QFUNC(jump), _next];
        };
        private _done = if (_auto) then {_mine isEqualTo []} else {([_green] call _fnc_past) > WINDOW_LEN};
        if (!_done) exitWith {};

        if (_pass + 1 < (_st get "passes") && {_aboard isNotEqualTo []}) exitWith {
            _st set ["pass", _pass + 1];
            [_veh, _red getPos [RUN_IN, _dir + 180], "NORMAL"] call EFUNC(support_air,moveTo);
            [PHASE_CIRCLE, format ["Pass %1 of %2 flown. Circling for the next.", _pass + 1, _st get "passes"], false] call _fnc_phase;
        };
        if (_aboard isEqualTo []) exitWith {
            [_veh, _green getPos [LEAVE_DIST * 2, _dir], "FULL"] call EFUNC(support_air,moveTo);
            [PHASE_LEAVE, "Stick is out. The aircraft is leaving.", false] call _fnc_phase;
        };
        [_veh, _green, "NORMAL", "LOITER", HOLD_RADIUS] call EFUNC(support_air,moveTo);
        [PHASE_HOLD, "Last pass flown. Holding over the drop zone: JUMP when ready.", true] call _fnc_phase;
    };

    case PHASE_CIRCLE: {
        if ((_pos distance2D (_red getPos [RUN_IN, _dir + 180])) > POINT_RING) exitWith {};
        [_veh, _green getPos [RUN_OUT, _dir], "NORMAL"] call EFUNC(support_air,moveTo);
        [PHASE_IN, format ["Pass %1 of %2: inbound.", (_st get "pass") + 1, _st get "passes"], false] call _fnc_phase;
    };

    case PHASE_HOLD: {
        if (_aboard isNotEqualTo []) exitWith {};
        [_veh, _green getPos [LEAVE_DIST * 2, _dir], "FULL"] call EFUNC(support_air,moveTo);
        [PHASE_LEAVE, "Cabin is empty. The aircraft is leaving.", false] call _fnc_phase;
    };

    case PHASE_LEAVE: {
        if ((_pos distance2D _green) < LEAVE_DIST) exitWith {};
        [_st, _handle] call FUNC(srvEnd);
    };
};
