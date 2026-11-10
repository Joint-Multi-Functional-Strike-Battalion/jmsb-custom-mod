#include "script_component.hpp"
/*
 * Author: YonV
 * A CAS module's order, on the server: books the sortie and launches it at
 * once (FUNC(casLaunch) - user, 2026-11-02: virtual until tasked, the airframe
 * made over the module now; the Response Delay is retired), or recalls the
 * aircraft.
 *
 * WHAT THE REQUESTER SET is read here, once, from the steppers and points
 * this provider declared: passes, ordnance, radius, danger close, INGRESS
 * and EGRESS. Not the height: the support core's tactical flight sets it
 * (user, 2026-11-01 - ALTITUDE retired, FUNC(casLaunch)). The ordnance index becomes a magazine class NOW, from the same stores list the row
 * offered (EFUNC(cas,stores)), so an index can never point at a different
 * store by the time the aircraft gets there.
 *
 * ON STATION a second SAD or LOITER is not refused: it moves the orbit to
 * the new grid without a new sortie, as a Simplex loiter repositions. A class
 * aircraft on station (user, 2026-11-02) flies a board's ATTACK RUN from there
 * as a strike from station and holds again after; RTB sends it home to the
 * module, where it is removed.
 *
 * FROM A THREAD (2026-11-01, FUNC(srvThread)): the sortie answers that thread
 * (FUNC(threadState)), may hold a run short until CLEARED HOT, carries the
 * store the card asked for and the time on station it asked for. A sortie
 * the board launched answers the asset's open thread and needs no clearance.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: "SAD", "LOITER", "ATTACK RUN" or "rtb" <STRING>
 * 2: Target position ATL <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 * 4: Who asked <OBJECT>
 * 5: A thread's order - "thread" id, "mag" store, "clear" (hold for CLEARED HOT), "stationTime" (s), "flow" (FUNC(casFlow)'s pairs, 2026-11-09) <HASHMAP> (optional, default empty)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "SAD", _pos, [], player] call jmfsb_support_air_fnc_casOrder
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_requester", objNull, [objNull]], ["_thread", createHashMap, [createHashMap]]];

if (_task isEqualTo TASK_RTB) exitWith {
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isNotEqualTo STATUS_IDLE) then {
        _logic setVariable [QGVAR(abort), true, true];
    };
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[_logic, "cannot take it - " + _why, "normal", _requester, false] call FUNC(say)};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _synced = _logic getVariable [QGVAR(synced), objNull];

private _radius = [_prm, SLOT_RADIUS, RADIUS_MIN, RADIUS_MAX] call FUNC(readParam);
private _passes = [_prm, SLOT_PASSES, PASSES_MIN, PASSES_MAX] call FUNC(readParam);
// ORDNANCE is declared on ATTACK RUN and SAD (FUNC(tasks)); the slot keeps its
// last value between orders, so a LOITER - weapons tight - reads none.
private _ordIdx = if (_task in [TASK_RUN, TASK_SAD]) then {[_prm, SLOT_ORDNANCE, 0, 1e3] call FUNC(readParam)} else {0};
// DANGER CLOSE is declared on the two tasks that release, and only while the
// module holds releases near friendlies at all.
private _danger = _task in [TASK_RUN, TASK_SAD] && {([_prm, SLOT_DANGER, 0, 1] call FUNC(readParam)) isEqualTo 1};

private _stores = [[_cls, _synced] select (alive _synced)] call EFUNC(cas,stores);
private _mag = if (_ordIdx > 0) then {(_stores param [_ordIdx - 1, []]) param [0, ""]} else {""};
// A thread's card names its store itself (EFUNC(cas,orderStore)).
if ("mag" in _thread) then {_mag = _thread get "mag"};

private _mode = switch (_task) do {
    case TASK_SAD: {"sad"};
    case TASK_LOITER: {"loiter"};
    default {"run"};
};

// ON STATION, A SAD OR LOITER MOVES THE ORBIT - the watch picks it up on its
// next tick (FUNC(casTick)). Nothing else is taken while it is out.
if (_logic getVariable [QGVAR(ticking), false]) exitWith {
    // AN AIRCRAFT ON STATION (user, 2026-11-02) flies a board's ATTACK RUN as a
    // strike from station, cleared - no thread to answer - and holds again
    // after it (FUNC(casJob), FUNC(casTick) "back").
    if (_task isEqualTo TASK_RUN && (_logic getVariable [QGVAR(onStation), false]) && count (_logic getVariable [QGVAR(job), createHashMap]) isEqualTo 0) exitWith {
        _logic setVariable [QGVAR(job), createHashMapFromArray [
            ["thread", ""],
            ["pos", _pos],
            ["ingress", [_prm, SLOT_INGRESS] call FUNC(readPoint)],
            ["egress", [_prm, SLOT_EGRESS] call FUNC(readPoint)],
            ["mag", _mag],
            ["danger", _danger],
            ["requester", _requester],
            ["cleared", true]
        ]];
        [_logic, format ["copy %1, in from station on %2", _task, mapGridPosition _pos], "high", _requester] call FUNC(say);
    };
    if !(_task in [TASK_SAD, TASK_LOITER]) exitWith {
        [_logic, "is on station - only a SAD or a LOITER moves it, RTB first for a run", "normal", _requester, false] call FUNC(say);
    };
    _logic setVariable [QGVAR(reposition), [_mode, _pos, _radius, _mag, _danger, _requester]];
    [_logic, format ["copy %1, repositioning to %2", _task, mapGridPosition _pos], "high", _requester] call FUNC(say);
};

_logic setVariable [QGVAR(status), STATUS_LAUNCHING, true];
// THE THREAD THIS SORTIE ANSWERS (2026-11-01), "" for a board order - server
// only, read by FUNC(threadState) and FUNC(threadReply) - and whether its run
// waits for CLEARED HOT.
_logic setVariable [QGVAR(sortieThread), _thread getOrDefault ["thread", ""]];
_logic setVariable [QGVAR(cleared), !(_thread getOrDefault ["clear", false])];
_logic setVariable [QGVAR(job), nil];
_logic setVariable [QGVAR(onStation), false];
if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_START) then {
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 0]), true];
};

private _opts = createHashMapFromArray [
    ["ingress", [_prm, SLOT_INGRESS] call FUNC(readPoint)],
    ["egress", [_prm, SLOT_EGRESS] call FUNC(readPoint)],
    ["danger", _danger],
    ["clear", _thread getOrDefault ["clear", false]],
    // THE CAS FLOW'S KEYS (2026-11-09, FUNC(casFlow)) for the sortie state.
    ["flow", _thread getOrDefault ["flow", []]],
    ["stationTime", _thread getOrDefault ["stationTime", _logic getVariable [QGVAR(stationTime), 600]]]
];

// VIRTUAL UNTIL TASKED (user, 2026-11-02): made over the module now - on the
// next frame, so the WILCO is in the thread first. A synced aircraft takes
// off now.
[_logic, format ["copy %1 on %2 - airborne", _task, mapGridPosition _pos], "high", _requester] call FUNC(say);
_logic setVariable [QGVAR(plan), [[_pos, _task]], true];

[FUNC(casLaunch), [_logic, _mode, _pos, _radius, _passes, _mag, _requester, _opts]] call CBA_fnc_execNextFrame;
