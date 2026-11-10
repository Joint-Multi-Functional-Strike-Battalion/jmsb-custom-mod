#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the watch on one run, every RUN_TICK seconds. Phases, and what the
 * aircraft says in the run's thread (2026-11-02, the jump by message):
 *
 *   "in"      flying the line; past the red light -> "red": RED LIGHT, FLASH
 *             ("PASS 1 OF 2 - STAND BY"; static line "STAND UP, HOOK UP")
 *   "red"     JUMP open to every man; past the green light -> "green": GREEN
 *             LIGHT - GO, FLASH ("PASS 1 OF 2 - 4 OUT ON THE LIGHT", or
 *             "JUMP FROM THE ACTION MENU" for a manual exit)
 *   "green"   Automatic exit: this pass's share out one every JUMP_INTERVAL
 *             (FUNC(jump) by remoteExec, where each is local). Manual: the
 *             window is WINDOW_LEN past the green light. The pass done: STICK
 *             OUT "4 OUT - 4 ABOARD", and with passes left and men aboard ->
 *             "circle" ("- CIRCLING FOR PASS 2"); nobody aboard -> "leave"
 *             and CLOSE "STICK OUT - LEAVING THE DZ"; else -> "hold" and the
 *             ask MEN STILL ABOARD - HOLDING OVER THE DZ (GO / ABORT; D9 - no
 *             answer in 5 min, FUNC(srvTimeout) puts them out)
 *   "circle"  back to the start of the run-in, then the line again -> "in":
 *             INBOUND "PASS 2 OF 2 - RED LIGHT IN 1:12"
 *   "hold"    orbiting the drop zone while men are still aboard after the
 *             last pass or an ABORT, JUMP open; after GO (FUNC(srvGo)) the
 *             rest out one every JUMP_INTERVAL; empty -> "leave" and CLOSE
 *             "CABIN EMPTY - LEAVING THE DZ"
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
// A module's aircraft that cannot fly is lost too (FUNC(airLost), 2026-11-02).
if (!alive _veh || {_veh getVariable [QGVAR(lost), false]} || {CBA_missionTime - (_st get "started") > RUN_MAX_S}) exitWith {[_st, _handle] call FUNC(srvEnd)};

private _dir = _st get "dir";
private _red = _st get "red";
private _green = _st get "green";
private _pos = getPos _veh;
private _passWord = format [SAID_PASS, (_st get "pass") + 1, _st get "passes"];
// How far along the line the aircraft is past a point (behind it: negative).
private _fnc_past = {
    params ["_from"];
    ((_pos vectorDiff [_from select 0, _from select 1, 0]) vectorDotProduct [sin _dir, cos _dir, 0])
};
private _aboard = [_st] call FUNC(aboard);
private _fnc_phase = {
    params ["_phase", "_text", "_mayJump"];
    _st set ["phase", _phase];
    [_st, _text, _mayJump] call FUNC(srvLight);
};
// The next man out, one every JUMP_INTERVAL.
private _fnc_next = {
    params ["_men"];
    if (_men isEqualTo [] || {CBA_missionTime - (_st get "lastOut") < JUMP_INTERVAL}) exitWith {false};
    private _next = _men select 0;
    _st set ["lastOut", CBA_missionTime];
    [_next, _veh, _st get "type"] remoteExecCall [QFUNC(jump), _next];
    true
};

switch (_st get "phase") do {
    case PHASE_IN: {
        if (([_red] call _fnc_past) < 0) exitWith {};
        private _static = (_st get "type") isEqualTo TYPE_STATIC;
        [PHASE_RED, ["RED LIGHT. Stand by.", "RED LIGHT. Stand up, hook up."] select _static, true] call _fnc_phase;
        [_st, CARD_RED_LIGHT, [_passWord, [SAID_STAND_BY, SAID_HOOK_UP] select _static] joinString WILCO_SEP, true] call FUNC(threadCard);
    };

    case PHASE_RED: {
        // The green-light point, or the leader's GO at the red light
        // (FUNC(srvGo), 2026-11-09).
        if (([_green] call _fnc_past) < 0 && {!(_st getOrDefault ["goNow", false])}) exitWith {};
        _st set ["goNow", false];
        _st set ["lastOut", 0];
        [PHASE_GREEN, "GREEN LIGHT. GO.", true] call _fnc_phase;
        private _how = if ((_st get "exit") isEqualTo EXIT_AUTO) then {
            format [SAID_AUTO, count (((_st get "stick") param [_st get "pass", []]) select {_x in _aboard})]
        } else {
            SAID_MANUAL
        };
        [_st, CARD_GREEN_LIGHT, [_passWord, _how] joinString WILCO_SEP, true] call FUNC(threadCard);
    };

    case PHASE_GREEN: {
        private _pass = _st get "pass";
        private _auto = (_st get "exit") isEqualTo EXIT_AUTO;
        private _mine = ((_st get "stick") param [_pass, []]) select {_x in _aboard};
        if (_auto && {[_mine] call _fnc_next}) exitWith {};
        private _done = if (_auto) then {_mine isEqualTo []} else {([_green] call _fnc_past) > WINDOW_LEN};
        if (!_done) exitWith {};

        private _out = format [SAID_OUT, count (_st get "jumpers") - count _aboard, count _aboard];
        if (_pass + 1 < (_st get "passes") && {_aboard isNotEqualTo []}) exitWith {
            _st set ["pass", _pass + 1];
            [_veh, _st get "start", "NORMAL"] call EFUNC(support_air,moveTo);
            [PHASE_CIRCLE, format ["Pass %1 of %2 flown. Circling for the next.", _pass + 1, _st get "passes"], false] call _fnc_phase;
            [_st, CARD_STICK_OUT, [_out, format [SAID_CIRCLING, _pass + 2]] joinString WILCO_SEP] call FUNC(threadCard);
        };
        [_st, CARD_STICK_OUT, _out] call FUNC(threadCard);
        if (_aboard isEqualTo []) exitWith {
            [_veh, _green getPos [LEAVE_DIST * 2, _dir], "FULL"] call EFUNC(support_air,moveTo);
            [PHASE_LEAVE, "Stick is out. The aircraft is leaving.", false] call _fnc_phase;
            [_st, "CLOSED", SAID_LEAVING] call FUNC(threadState);
        };
        [_veh, _green, "NORMAL", "LOITER", HOLD_RADIUS] call EFUNC(support_air,moveTo);
        [PHASE_HOLD, "Last pass flown. Holding over the drop zone: JUMP when ready.", true] call _fnc_phase;
        [_st get "assetId", _st get "thread", PROMPT_HOLD_TEXT, PROMPT_HOLD_ANSWERS, _st get "callsign", {_this call FUNC(srvTimeout)}] call EFUNC(support,prompt);
    };

    case PHASE_CIRCLE: {
        if ((_pos distance2D (_st get "start")) > POINT_RING) exitWith {};
        [_veh, _green getPos [RUN_OUT, _dir], "NORMAL"] call EFUNC(support_air,moveTo);
        [PHASE_IN, format ["Pass %1 of %2: inbound.", (_st get "pass") + 1, _st get "passes"], false] call _fnc_phase;
        private _eta = [[_veh, _red] call EFUNC(support,etaTo), ETA_RED] call EFUNC(support,etaText);
        [_st, CARD_INBOUND, ([_passWord, _eta] select {_x isNotEqualTo ""}) joinString WILCO_SEP] call FUNC(threadCard);
    };

    case PHASE_HOLD: {
        if (_st get "go") then {[_aboard] call _fnc_next};
        if (_aboard isNotEqualTo []) exitWith {};
        [_veh, _green getPos [LEAVE_DIST * 2, _dir], "FULL"] call EFUNC(support_air,moveTo);
        [PHASE_LEAVE, "Cabin is empty. The aircraft is leaving.", false] call _fnc_phase;
        [_st, "CLOSED", SAID_EMPTY] call FUNC(threadState);
    };

    // AN RTB WITH A LANDING POINT (user, 2026-11-09; FUNC(srvRtbLand)): down
    // and stopped, everyone aboard gets out (FUNC(unload), where each is
    // local); the cabin empty, the thread closes and it goes home - a
    // module's to the module, a side's own clear of the point first.
    case PHASE_LAND: {
        if (!isTouchingGround _veh || {speed _veh > RTB_STOPPED_KMH}) exitWith {};
        if (_aboard isNotEqualTo []) exitWith {
            private _sent = _st getOrDefault ["unloadSent", []];
            {
                _sent pushBack _x;
                [_x, _veh] remoteExecCall [QFUNC(unload), _x];
            } forEach (_aboard - _sent);
            _st set ["unloadSent", _sent];
        };
        [_st, "CLOSED", format [SAID_RTB_LANDED, mapGridPosition _veh]] call FUNC(threadState);
        _st set ["leaveFrom", +_pos];
        [_veh, _pos getPos [RTB_LEAVE_DIST * 2, getDir _veh], "FULL"] call EFUNC(support_air,moveTo);
        [PHASE_LEAVE, "Everyone is off. The aircraft is leaving.", false] call _fnc_phase;
    };

    case PHASE_LEAVE: {
        // A module's aircraft turns straight for home, the module, where it is
        // removed (2026-11-02, FUNC(airHome)); a side's own flies clear first
        // - of the green light, or of where it landed its players
        // (2026-11-09) - and is removed.
        if (!(_st getOrDefault ["module", false]) && (_pos distance2D (_st getOrDefault ["leaveFrom", _green])) < LEAVE_DIST) exitWith {};
        [_st, _handle] call FUNC(srvEnd);
    };
};
