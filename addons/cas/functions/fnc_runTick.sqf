#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the run watch, every CAS_ACQUIRE_STEP s (FUNC(launch); was the body
 * of FUNC(request)). A strike is a PASS (2026-11-05, modelled on how Simplex
 * Support Services flies a strafe; no code of it used): the drone is lined
 * up on the ingress bearing by its own orders, dived on the aim - a laser
 * spot or smoke looked for on the way in, the grid else - and the salvo
 * released on a solution (FUNC(passBegin), FUNC(passTick)); before, it fired
 * once inside a 600 m ring from wherever the AI had it. Then out to the
 * egress point. A LOITER is watched by the same tick: it never releases, and
 * what it waits for is the drone over the point, when the gunner's seat
 * changes hands. A thread's strike (step 5) holds over the grid for CLEARED
 * HOT, says IN / OFF, and comes back over the grid for the BDA.
 *
 * DISABLED IS LOST (2026-11-05, Simplex's test): a drone on the ground that
 * cannot move is counted lost like one shot down (FUNC(gone)) and removed.
 *
 * THE BOARD IS FREED WHEN THE RUN IS OVER, not when the airframe is gone: the
 * row reads what FUNC(idleStatus) says - READY, or REARMING after a loss -
 * with the cooldown on top. EVERY ENDING of a living drone flies it home to the
 * module, by the run's egress point when the BDA said EGRESS, where it is
 * removed (FUNC(recover), user 2026-11-02: "all support aircraft needs to be
 * virtual till tasked"); a wreck is cleared at once. A pass under way is
 * finished before the run's patience ends it; a recall ends it at once.
 *
 * Arguments:
 * 0: [drone, logic, aim, search radius, side, egress point, egress heading, until, call sign, mode, hold, thread id, run state] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(runTick), 1, _args] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params ["_args", "_handle"];
_args params ["_veh", "_logic", "_pos", "_radius", "_side", "_end", "_egressHdg", "_until", "_callsign", "_mode", "_hold", "_threadId", "_run"];
// What a thread's answers move (step 5): read again every tick.
_pos = _run getOrDefault ["pos", _pos];
_end = _run getOrDefault ["end", _end];
_egressHdg = _run getOrDefault ["egressHdg", _egressHdg];
_until = _run getOrDefault ["until", _until];
private _asked = _threadId isNotEqualTo "";

private _done = {
    [_handle] call CBA_fnc_removePerFrameHandler;
    if (!isNull _logic) then {
        _logic setVariable [QGVAR(status), [_logic] call FUNC(idleStatus), true];
        _logic setVariable [QGVAR(vehicle), objNull, true];
        _logic setVariable [QGVAR(plan), [], true];
        _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 300]), true];
    };
};

// EVERY ENDING: home to the module and removed (FUNC(recover)) - by the run's
// egress point first when the BDA said EGRESS (user, 2026-11-02).
private _sweep = {
    private _via = [];
    if ((_run getOrDefault ["said", ""]) isEqualTo SAID_EGRESS) then {_via = _run getOrDefault ["end", []]};
    [_logic, _veh, _callsign, _via] call FUNC(recover);
};

// THE ASSET'S THREAD (2026-11-01), if one was filed to it. A run that released
// or reached station and then ends is over (CLOSED); one that ends before
// either never flew the task (DECLINED).
private _thread = {
    params ["_state", "_said"];
    [format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _state, _said, _callsign, false, _threadId] call EFUNC(support,state);
};
private _ended = {
    params ["_said"];
    private _started = _veh getVariable [QGVAR(released), false];
    if (_veh getVariable [QGVAR(onStation), false]) then {_started = true};
    if (_run getOrDefault ["flown", false]) then {_started = true};
    [["DECLINED", "CLOSED"] select _started, _said] call _thread;
};
// THE CHECK-IN (user, 2026-11-02): once a run, in the thread that asked.
private _checkIn = {
    params ["_fly", "_remarks"];
    if (!_asked || (_run getOrDefault ["checkedIn", false])) exitWith {};
    _run set ["checkedIn", true];
    [
        format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
        _threadId,
        _veh,
        _callsign,
        _pos,
        [_veh, _fly] call EFUNC(support,flightHeight),
        ((_until - CBA_missionTime) max 0) / SECONDS_PER_MINUTE,
        _remarks
    ] call EFUNC(support,checkIn);
};
// The way out after a pass: the egress point, as a waypoint of its own.
private _fnc_out = {
    private _grp = group driver _veh;
    [_grp] call CBA_fnc_clearWaypoints;
    private _out = _grp addWaypoint [_end, 0];
    _out setWaypointType "MOVE";
    _out setWaypointSpeed "FULL";
    _grp setCurrentWaypoint _out;
};

// Shot down: FUNC(killed) has already counted it against the module.
if (isNull _veh || {!alive _veh}) exitWith {
    call _done;
    ["shot down"] call _ended;
    if (!isNull _veh) then {call _sweep};
};
// DISABLED: on the ground and going nowhere - lost (2026-11-05).
if (isTouchingGround _veh && !canMove _veh) exitWith {
    call _done;
    WARNING_2("%1 is down and cannot move at %2 - lost",_callsign,mapGridPosition _veh);
    ["disabled"] call _ended;
    if !(_veh getVariable [QGVAR(counted), false]) then {
        _veh setVariable [QGVAR(counted), true];
        [_logic, "disabled"] call FUNC(gone);
    };
    call _sweep;
};

// BINGO (step 5, 2026-11-01), in a thread: its time on station or its fuel is
// short - BINGO IN 2 MIN (FLASH), and it leaves BINGO_LEAD s on.
if (_asked && !(_run getOrDefault ["bingo", false]) && ((_until - CBA_missionTime) <= BINGO_LEAD || fuel _veh <= BINGO_FUEL)) then {
    _until = _until min (CBA_missionTime + BINGO_LEAD);
    {_run set _x} forEach [["bingo", true], ["until", _until], ["said", SAID_BINGO]];
    INFO_2("%1 bingo - leaving in %2 s",_callsign,round (_until - CBA_missionTime));
    [_logic, _threadId, CAS_BINGO, []] call FUNC(threadSay);
};

// Recalled, or the run has outlasted its patience - a pass under way is
// finished first (2026-11-05); a recall ends it at once (FUNC(recover)).
private _passing = [_veh] call FUNC(passActive);
if ((_logic getVariable [QGVAR(abort), false]) || (!_passing && CBA_missionTime > _until)) exitWith {
    call _done;
    if (!isNull _logic) then {_logic setVariable [QGVAR(abort), false, true]};
    INFO_1("%1 off task - leaving the area",_callsign);
    [_run getOrDefault ["said", SAID_OFF_TASK]] call _ended;
    call _sweep;
};

// ON STATION IS WHERE A LOITER HANDS OVER - over the grid. Nothing is released
// or acquired: what happens over that grid from here is a man on a terminal.
if (_mode isEqualTo MODE_LOITER) exitWith {
    if (_veh getVariable [QGVAR(onStation), false]) exitWith {};
    if (_veh distance2D _hold > CAS_STATION_RING) exitWith {};

    _veh setVariable [QGVAR(onStation), true, true];
    if (!isNull _logic) then {_logic setVariable [QGVAR(status), STATUS_STATION, true]};
    INFO_2("%1 on station over %2 - the gunner is the drone controller's",_callsign,mapGridPosition _pos);
    ["IN_PROGRESS", format ["on station over %1", mapGridPosition _pos]] call _thread;
    [FLY_STATION, CHECKIN_REMARKS_LOITER] call _checkIn;
    // To the side by remoteExec, taken only from the server (review S7).
    [_logic, _veh, _veh getVariable [QGVAR(caller), objNull]] remoteExecCall [QFUNC(onStation), _side];
};

// HELD FOR CLEARED HOT (2026-11-01, a thread's strike): orbiting the grid
// until the issuer clears it (FUNC(threadReply)). Over the grid it is on
// station for its strike and checks in (user, 2026-11-02).
if !(_logic getVariable [QGVAR(cleared), true]) exitWith {
    if (_veh distance2D _pos > CAS_STATION_RING) exitWith {};
    [FLY_ATTACK, CHECKIN_REMARKS_HELD] call _checkIn;
    // IN ASKS THE CLEARANCE (2026-11-09, tree 3): over the grid - its run in
    // is its orbit - once the READBACK was CORRECT, once a pass, not after a
    // MOVE (it waits for the next CAS REQUEST) nor while it holds for a BDA.
    // CONTINUE asks again CAS_CONTINUE_DELAY s on (FUNC(threadReply)).
    if (!_asked || {(_run getOrDefault ["rb", RB_OK]) isNotEqualTo RB_OK}) exitWith {};
    if ((_run getOrDefault ["inAsked", false]) || (_run getOrDefault ["moved", false]) || (_run getOrDefault ["struck", false])) exitWith {};
    if (CBA_missionTime < (_run getOrDefault ["continueAt", 0])) exitWith {};
    _run set ["inAsked", true];
    [format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _threadId, CAS_ASK_IN, [mapGridPosition _pos, _run getOrDefault ["control", 0], false], _callsign, {_this call FUNC(threadTimeout)}] call FUNC(casAsk);
};
// THE TOT (2026-11-09): cleared, it does not begin the pass before the order's
// time on target, less the dive (FUNC(runOrder)).
if (!(_veh getVariable [QGVAR(runIn), true]) && {CBA_missionTime < (_run getOrDefault ["leaveAt", -1])}) exitWith {};
if !(_veh getVariable [QGVAR(runIn), true]) then {
    _veh setVariable [QGVAR(runIn), true];
    // The clearance it was waiting for is spent.
    _run set ["again", false];
    if (_asked) then {
        ["IN_PROGRESS", format ["in hot on %1", mapGridPosition _pos]] call _thread;
        // IN was said when it asked the clearance (2026-11-09); cleared before
        // it asked, it says IN now.
        if !(_run getOrDefault ["inAsked", false]) then {[_logic, _threadId, CAS_IN, []] call FUNC(threadSay)};
    };
    // THE PASS: on the run's ingress bearing the first time, from where it
    // is after that (a re-attack, a re-task); its own orders fly the line-up.
    private _inDir = _run getOrDefault ["inDir", -1];
    if (_inDir < 0) then {_inDir = _pos getDir _veh};
    _run set ["inDir", -1];
    [group driver _veh] call CBA_fnc_clearWaypoints;
    ([_pos, _radius, _side] call FUNC(acquire)) params ["_aim", "_by", "_track"];
    private _opts = createHashMapFromArray [["search", [_pos, _radius, _side, 0, true]], ["by", _by]];
    if ([_veh, _aim, _track, _inDir, _opts] call FUNC(passBegin)) then {
        INFO_3("%1 cleared hot - pass on %2 (%3)",_callsign,mapGridPosition _aim,_by);
        ["IN_PROGRESS", format ["in hot - %1", mapGridPosition _aim]] call _thread;
        [_logic, _aim, _by] remoteExecCall [QFUNC(release), _side];
    } else {
        // Nothing aboard: the run is flown dry, out to the egress - the BDA
        // finds it Winchester.
        WARNING_1("%1 has nothing to release - the run goes out dry",_callsign);
        _veh setVariable [QGVAR(released), true];
        {_run set _x} forEach [["flown", true], ["struck", true], ["offSaid", false]];
        call _fnc_out;
    };
};

if (_veh getVariable [QGVAR(released), false]) exitWith {
    // OFF (step 5): clear of the target, in a thread - OFF, then REQUEST BDA.
    // TYPE 3 (2026-11-09): cleared to engage, it reports ATTACK COMPLETE and
    // asks for the BDA instead.
    if (_asked && !(_run getOrDefault ["offSaid", false]) && _veh distance2D _pos > CAS_RELEASE_RING) then {
        _run set ["offSaid", true];
        if (_run getOrDefault ["engaged", false]) exitWith {
            _run set ["engaged", false];
            [format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _threadId, CAS_ASK_COMPLETE, [], _callsign, {_this call FUNC(threadTimeout)}] call FUNC(casAsk);
        };
        [_logic, _threadId, CAS_OFF, []] call FUNC(threadSay);
    };
    if (_veh distance2D _end >= CAS_RELEASE_RING) exitWith {};

    // A THREAD'S STRIKE STAYS (step 5): at the egress point it comes back over
    // the grid and holds there for the BDA and what comes after it.
    if (_asked) exitWith {
        _veh setVariable [QGVAR(released), false];
        _veh setVariable [QGVAR(runIn), false];
        // A re-attack cleared on the way out goes straight back in, on the
        // BDA's grid when it gave one.
        _logic setVariable [QGVAR(cleared), _run getOrDefault ["again", false]];
        _run set ["again", false];
        // A new clearance each pass: IN is asked again for the next one.
        _run set ["inAsked", false];
        private _aimNext = _run getOrDefault ["aimNext", []];
        if (_aimNext isNotEqualTo []) then {
            _pos = _aimNext;
            _run set ["pos", _pos];
            _run set ["end", _pos getPos [_run getOrDefault ["distance", REACH_DEF_DISTANCE], _egressHdg]];
            _run set ["aimNext", []];
        };
        _logic setVariable [QGVAR(status), STATUS_STATION, true];
        private _grp = group driver _veh;
        [_grp] call CBA_fnc_clearWaypoints;
        private _wp = _grp addWaypoint [_pos, 0];
        _wp setWaypointType "LOITER";
        _wp setWaypointLoiterRadius CAS_LOITER_RADIUS;
        _wp setWaypointSpeed "NORMAL";
        INFO_2("%1 back over %2 - holding for the BDA",_callsign,mapGridPosition _pos);
    };

    // Outbound and clear: the run is over.
    call _done;
    INFO_1("%1 egressed",_callsign);
    ["CLOSED", "run complete"] call _thread;
    call _sweep;
};

// THE PASS UNDER WAY, until it is over; then out to the egress point.
private _res = [_veh] call FUNC(passTick);
if (_res in [PASS_LINE, PASS_DIVE]) exitWith {};
INFO_2("%1 pass over - %2 - out to the egress",_callsign,_res);
_veh setVariable [QGVAR(released), true];
{_run set _x} forEach [["flown", true], ["struck", true], ["offSaid", false]];
call _fnc_out;
