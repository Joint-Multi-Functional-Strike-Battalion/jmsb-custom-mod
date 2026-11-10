#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a run begins. A SIDE'S OWN AIRCRAFT: the frame after its WILCO
 * (FUNC(srvThread)); a run stood down in the meantime (FUNC(srvAbort)) is not
 * flown; the aircraft appears RUN_IN short of the red light at the type's
 * altitude. A MODULE'S (user, 2026-11-02: virtual until tasked, boarded by
 * message): on the leader's BOARD (FUNC(srvBoard)), its aircraft made at the
 * request and orbiting the module (FUNC(airUp)) - it leaves its orbit for the
 * start of the run-in, climbing or coming down
 * to the type's altitude, and turns in there (FUNC(srvTick) PHASE_CIRCLE);
 * the thread hears STICK ABOARD - n MEN - RED LIGHT IN m:ss with its ON TASK.
 * Either way every man of the stick is put aboard where
 * he is local (FUNC(board), by remoteExec - seats or the bay, as the
 * aircraft says: its module, or the setting for a side's own), and the run's
 * watch starts (FUNC(srvTick)): red light, green light, the passes, the hold
 * and the leaving are its.
 *
 * IN THE THREAD (2026-11-02), a side's own: WHEELS UP "8 ABOARD - RED LIGHT IN
 * 1:12", then IN_PROGRESS. An aircraft that could not be made: CANTCO "COULD NOT LAUNCH",
 * and the run is dropped (FUNC(srvRelease)). The run is published on the
 * squad's group and on a JMSB - Jump Aircraft module (QGVAR(run): the
 * aircraft and its path) - the row reads TASKED and the thread's pin draws
 * the run-in from it (FUNC(assets)).
 *
 * Never a client's call (review S7: it was a CBA event, then a remoteExec
 * target that checked the sender; the card is the way in now).
 *
 * Arguments:
 * 0: The run <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st] call jmfsb_jumpmaster_fnc_srvLaunch
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvLaunch: refused - remote call from machine %1",remoteExecutedOwner);
};
// Stood down before WHEELS UP: the run is no longer on the list.
if ((GVAR(runs) findIf {(_x get "thread") isEqualTo (_st get "thread")}) < 0) exitWith {};

private _red = _st get "red";
private _green = _st get "green";
private _dir = _st get "dir";
private _alt = _st get "alt";
private _start = _red getPos [RUN_IN, _dir + 180];
_st set ["start", _start];

// A MODULE'S AIRCRAFT WAS MADE AT THE REQUEST (2026-11-02, FUNC(airUp),
// FUNC(srvBoard)); a side's own is made at the run-in.
private _module = _st getOrDefault ["module", false];
private _veh = if (_module) then {_st get "veh"} else {
    [_st get "side", _st get "cls", _start, _dir, _alt] call FUNC(spawnAircraft)
};
if (isNull _veh) exitWith {
    [_st] call FUNC(srvRelease);
    [_st, "DECLINED", WHY_NO_LAUNCH] call FUNC(threadState);
};
_st set ["veh", _veh];
_st set ["flown", true];
// The run's clock (RUN_MAX_S) starts at WHEELS UP, not in the response delay.
_st set ["started", CBA_missionTime];

private _jumpers = (_st get "jumpers") select {alive _x};
_st set ["jumpers", _jumpers];
{
    [_x, _veh, _st get "bay", _forEachIndex, _st get "type"] remoteExecCall [QFUNC(board), _x];
} forEach _jumpers;
private _run = [_veh, [[_start, PLAN_RUN_IN], [_red, PLAN_RED], [_green, PLAN_GREEN]]];
(_st get "group") setVariable [QGVAR(run), _run, true];
private _logic = _st getOrDefault ["logic", objNull];
if (!isNull _logic) then {_logic setVariable [QGVAR(run), _run, true]};

// FROM ITS ORBIT OVER THE MODULE (user, 2026-11-02: "static 2000 then move to
// jump alt, halo haho 6k"): to the start of the run-in, climbing or coming
// down to the jump's altitude on the way; turned in there (FUNC(srvTick)
// PHASE_CIRCLE, which says INBOUND - PASS 1 OF n). One message: STICK ABOARD -
// n MEN - RED LIGHT IN m:ss, ON TASK.
if (_module) exitWith {
    _logic setVariable [QGVAR(airPhase), AIR_RUN, true];
    [_veh, _alt] call EFUNC(support,flyAt);
    [_veh, _start, "NORMAL"] call EFUNC(support_air,moveTo);
    _st set ["phase", PHASE_CIRCLE];
    [_st, format ["Aboard. To the run-in at %1 m.", round _alt], false] call FUNC(srvLight);
    private _ahead = [[_veh, _start] call EFUNC(support,etaTo), [_st get "cls"] call FUNC(runEta)];
    private _eta = [[ETA_UNKNOWN, (_ahead select 0) + (_ahead select 1)] select (ETA_UNKNOWN in _ahead), ETA_RED] call EFUNC(support,etaText);
    [_st, "IN_PROGRESS", ([format [SAID_STICK_ABOARD, count _jumpers, [WORD_MAN, WORD_MEN] select (count _jumpers > 1)], _eta] select {_x isNotEqualTo ""}) joinString WILCO_SEP] call FUNC(threadState);
    [FUNC(srvTick), RUN_TICK, [_st]] call CBA_fnc_addPerFrameHandler;
};

[_veh, _green getPos [RUN_OUT, _dir], "NORMAL"] call EFUNC(support_air,moveTo);
[_st, format ["Aboard at %1 m, %2 km out from the red light.", round _alt, round (RUN_IN / 1000)], false] call FUNC(srvLight);

private _eta = [[_veh, _red] call EFUNC(support,etaTo), ETA_RED] call EFUNC(support,etaText);
[_st, CARD_WHEELS_UP, ([format [SAID_ABOARD, count _jumpers], _eta] select {_x isNotEqualTo ""}) joinString WILCO_SEP] call FUNC(threadCard);
[_st, "IN_PROGRESS"] call FUNC(threadState);

[FUNC(srvTick), RUN_TICK, [_st]] call CBA_fnc_addPerFrameHandler;
