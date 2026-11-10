#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a transport's lift job ends (2026-11-01, DESIGN_SUPPORT_MESSAGING
 * step 7) - the issuer's RTB, ABORT or CLOSE (FUNC(liftReply)), no answer to a
 * prompt (D9, FUNC(threadTimeout)), a hot LZ not confirmed, an insertion's PAX
 * OFF (2026-11-02: its egress). A helicopter that is out goes home - by the
 * card's egress points when it gave them - and one still
 * launching is stood down (FUNC(transportOrder)'s RTB); the thread is closed
 * with what it says (or declined: a hot LZ never confirmed), and the job is
 * over.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: What it says <STRING>
 * 2: The thread's state - "CLOSED" or "DECLINED" <STRING> (optional, default "CLOSED")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "RTB"] call jmfsb_support_air_fnc_liftEnd
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_said", "", [""]], ["_state", "CLOSED", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if (count _job isEqualTo 0) exitWith {};
private _threadId = _job get "thread";

private _out = _logic getVariable [QGVAR(ticking), false];
private _launching = (_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_LAUNCHING;
if (_out || _launching) then {
    [_logic, TASK_RTB, [], [], _job get "issuer"] call FUNC(transportOrder);
};
// Home by the card's egress points (user, 2026-11-02: the LIFT REQUEST's
// EGRESS, up to four, in order; an extraction's are flown from its HLZ, not on
// an RTB - FUNC(liftJob) "homeVia").
private _homeVia = _job getOrDefault ["homeVia", []];
if (_out && _homeVia isNotEqualTo []) then {
    ((_logic getVariable [QGVAR(order), []]) param [7, createHashMap]) set ["via", +_homeVia];
};
// The ACE action ALL IN goes with the job (FUNC(canAllIn)).
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
if (!isNull _veh) then {
    _veh setVariable [QGVAR(allIn), nil, true];
    // ...and WAVE OFF (2026-11-08, FUNC(canWaveOff))
    _veh setVariable [QGVAR(waveOff), nil, true];
};

INFO_3("liftEnd: %1 - %2 (%3)",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_said,_threadId);
// PAX OFF, RTB, ABORT: nothing of the job is open on the ground any more.
[_threadId, []] call EFUNC(support,zones);
[_logic, _state, _said, _threadId] call FUNC(threadState);
_logic setVariable [QGVAR(liftJob), nil];
if ((_logic getVariable [QGVAR(threadHold), ""]) isEqualTo _threadId) then {
    _logic setVariable [QGVAR(threadHold), nil];
};
// An ESCORT called for a launch that never came goes with the job (2026-11-09).
if (!_out && !_launching) then {_logic setVariable [QGVAR(escortWanted), nil]};
// Not flying and not launching: nothing more will answer this thread.
if (!_out && !_launching) then {_logic setVariable [QGVAR(sortieThread), nil]};
