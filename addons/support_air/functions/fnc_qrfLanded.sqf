#include "script_component.hpp"
/*
 * Author: YonV
 * A QRF squad is on the ground: give it its job.
 *
 *   DEFEND (the module's default) - CBA's defend task on the grid, inside
 *   the module's Defend Radius: buildings and statics manned, the rest on
 *   watch.
 *   JOIN - the squad joins the requester's group and takes his orders. A
 *   requester who is gone, or not on the squad's side any more, gets a
 *   defending squad instead of nobody's.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The squad <GROUP>
 * 2: The grid, ATL <ARRAY>
 * 3: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _grp, _pos, player] call jmfsb_support_air_fnc_qrfLanded
 *
 * Public: No
 */

// CBA defend: share of the squad that may patrol, and that holds its spot.
#define DEFEND_THRESHOLD 2
#define DEFEND_PATROL 0.2
#define DEFEND_HOLD 0.5

params [["_logic", objNull, [objNull]], ["_grp", grpNull, [grpNull]], ["_pos", [], [[]]], ["_requester", objNull, [objNull]]];

if (isNull _grp || {_grp getVariable [QGVAR(tasked), false]}) exitWith {};
_grp setVariable [QGVAR(tasked), true];

// A QRF TASKED BY MESSAGE (step 7, 2026-11-01): the card's action on arrival
// over the module's On The Ground, and the link-up asked in its thread.
private _job = _logic getVariable [QGVAR(qrfJob), createHashMap];
private _threadId = _job getOrDefault ["thread", ""];
// The insertion is done: its LZ or DZ leaves the side's AiTR (FUNC(qrfThread)).
if (_threadId isNotEqualTo "") then {[_threadId, []] call EFUNC(support,zones)};

private _alive = (units _grp) select {alive _x};
{_x allowDamage true} forEach _alive;
if (_alive isEqualTo []) exitWith {
    [_logic, "reports the squad lost on insertion", "high", _requester, false] call FUNC(say);
    if (_threadId isEqualTo "") exitWith {};
    [_logic, "CLOSED", "SQUAD LOST ON INSERTION", _threadId] call FUNC(threadState);
    _logic setVariable [QGVAR(qrfJob), nil];
};

_grp setBehaviour "AWARE";
_grp setCombatMode "YELLOW";

private _onLanding = _job getOrDefault ["onLanding", -1];
if (_onLanding < 0) then {_onLanding = _logic getVariable [QGVAR(onLanding), ON_LANDING_DEFEND]};
private _join = _onLanding isEqualTo ON_LANDING_JOIN
    && {alive _requester}
    && {(side group _requester) isEqualTo (_logic getVariable [QGVAR(side), west])};

// SQUAD DOWN - LINKED UP? The thread is held open past the sortie's end
// (QGVAR(threadHold)) for the answer (FUNC(qrfReply)), D9 too.
private _fnc_linkup = {
    params ["_where", "_what"];
    if (_threadId isEqualTo "") exitWith {};
    _job set ["step", JOB_LINKUP];
    _job set ["line", format ["SQUAD DOWN AT %1 - %2 MEN - %3", _where, count _alive, _what]];
    _logic setVariable [QGVAR(threadHold), _threadId];
    [_logic, _threadId, format [PROMPT_LINKUP, _where, count _alive, _what], ANSWERS_LINKUP] call FUNC(threadPrompt);
};

if (_join) exitWith {
    _alive joinSilent (group _requester);
    [_logic, format ["squad is down at %1 and is yours - %2 men", mapGridPosition (_alive select 0), count _alive], "high", _requester] call FUNC(say);
    [mapGridPosition (_alive select 0), "YOURS"] call _fnc_linkup;
};

[_grp, _pos, _logic getVariable [QGVAR(defendRadius), 100], DEFEND_THRESHOLD, DEFEND_PATROL, DEFEND_HOLD] call CBA_fnc_taskDefend;
[_logic, format ["squad is down and holding %1 - %2 men", mapGridPosition _pos, count _alive], "high", _requester] call FUNC(say);
[mapGridPosition _pos, "HOLDING"] call _fnc_linkup;
