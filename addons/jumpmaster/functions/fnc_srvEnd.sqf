#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a run is over - flown away, lost, or out of time. Anyone still
 * aboard is put out (the aircraft is about to go), the aircraft and its crew
 * are removed - a module's flies home to the module and is removed there
 * instead (user, 2026-11-02: virtual until tasked; FUNC(airHome)) - and the
 * aircraft is given back
 * (FUNC(srvRelease): the squad's
 * published run cleared, a JMSB - Jump Aircraft module's aircraft into its
 * cooldown). The thread is CLOSED (2026-11-02): "AIRCRAFT LOST", "OUT OF TIME -
 * 2 PUT OUT"; a run that left the DZ said its CLOSE already, and nothing is
 * said twice.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: Its watch's PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st, _handle] call jmfsb_jumpmaster_fnc_srvEnd
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_handle", -1, [0]]];

if (_handle >= 0) then {[_handle] call CBA_fnc_removePerFrameHandler};
[_st] call FUNC(srvRelease);

private _veh = _st get "veh";
private _aboard = [_st] call FUNC(aboard);
{
    // By remoteExec to where he is local, taken only from the server (review S7).
    [_x, _veh, _st get "type"] remoteExecCall [QFUNC(jump), _x];
} forEach _aboard;

private _said = switch (true) do {
    case (!alive _veh || {_veh getVariable [QGVAR(lost), false]}): {SAID_LOST};
    case ((_st get "phase") isNotEqualTo PHASE_LEAVE): {format [SAID_OUT_OF_TIME, count _aboard]};
    default {SAID_LEAVING};
};
[_st, "CLOSED", _said] call FUNC(threadState);

// A MODULE'S AIRCRAFT GOES HOME TO THE MODULE AND IS REMOVED THERE (user,
// 2026-11-02: virtual until tasked) - sent by FUNC(srvRelease) above
// (FUNC(airHome)); a lost one was counted by FUNC(airLost).
if (_st getOrDefault ["module", false]) exitWith {};

// The last men need a moment to be out before the hull goes.
[{
    params ["_veh"];
    if (isNull _veh) exitWith {};
    {deleteVehicle _x} forEach (crew _veh select {!isPlayer _x});
    deleteVehicle _veh;
}, [_veh], JUMP_INTERVAL * 4] call CBA_fnc_waitAndExecute;
