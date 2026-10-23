#include "script_component.hpp"
/*
 * Author: JMSB
 * A CAS module's order, on the server: books the sortie and launches it after
 * the response delay (FUNC(casLaunch)), or recalls the aircraft.
 *
 * WHAT THE REQUESTER SET is read here, once, from the steppers and points
 * this provider declared: passes, ordnance, radius, altitude, danger close,
 * INGRESS and EGRESS. The ordnance index becomes a magazine class NOW, from the same stores list the row
 * offered (EFUNC(cas,stores)), so an index can never point at a different
 * store by the time the aircraft gets there.
 *
 * ON STATION a second SAD or LOITER is not refused: it moves the orbit to
 * the new grid without a new sortie, as a Simplex loiter repositions.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: "SAD", "LOITER", "ATTACK RUN" or "rtb" <STRING>
 * 2: Target position ATL <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 * 4: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "SAD", _pos, [], player] call jmfsb_support_air_fnc_casOrder
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_requester", objNull, [objNull]]];

if (_task isEqualTo TASK_RTB) exitWith {
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isNotEqualTo STATUS_IDLE) then {
        _logic setVariable [QGVAR(abort), true, true];
    };
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[_logic, "cannot take it - " + _why, "normal", _requester, false] call FUNC(say)};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _synced = _logic getVariable [QGVAR(synced), objNull];

private _alt = [_prm, SLOT_CAS_ALT, 0, count CAS_ALT_TABLE - 1, CAS_ALT_TABLE, _logic getVariable [QGVAR(altitude), 600]] call FUNC(readParam);
if (_cls isKindOf "Helicopter") then {_alt = _alt min HELI_CEILING};
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

private _mode = switch (_task) do {
    case TASK_SAD: {"sad"};
    case TASK_LOITER: {"loiter"};
    default {"run"};
};

// ON STATION, A SAD OR LOITER MOVES THE ORBIT - the watch picks it up on its
// next tick (FUNC(casTick)). Nothing else is taken while it is out.
if (_logic getVariable [QGVAR(ticking), false]) exitWith {
    if !(_task in [TASK_SAD, TASK_LOITER]) exitWith {
        [_logic, "is on station - only a SAD or a LOITER moves it, RTB first for a run", "normal", _requester, false] call FUNC(say);
    };
    _logic setVariable [QGVAR(reposition), [_mode, _pos, _radius, _alt, _mag, _danger, _requester]];
    [_logic, format ["copy %1, repositioning to %2", _task, mapGridPosition _pos], "high", _requester] call FUNC(say);
};

private _left = _logic getVariable [QGVAR(left), -1];
if (_left > 0) then {_logic setVariable [QGVAR(left), _left - 1, true]};
_logic setVariable [QGVAR(status), STATUS_LAUNCHING, true];
if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_START) then {
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 0]), true];
};

private _opts = createHashMapFromArray [
    ["ingress", [_prm, SLOT_INGRESS] call FUNC(readPoint)],
    ["egress", [_prm, SLOT_EGRESS] call FUNC(readPoint)],
    ["danger", _danger]
];

// A synced aircraft is already on the map: it starts now and takes off.
private _delay = [_logic getVariable [QGVAR(spawnDelay), 60], 0] select (alive _synced);
[_logic, format ["copy %1 on %2 - airborne in %3 sec", _task, mapGridPosition _pos, round _delay], "high", _requester] call FUNC(say);
_logic setVariable [QGVAR(plan), [[_pos, _task]], true];

[FUNC(casLaunch), [_logic, _mode, _pos, _alt, _radius, _passes, _mag, _requester, _opts], _delay] call CBA_fnc_waitAndExecute;
