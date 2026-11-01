#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a run is over - flown away, lost, or out of time. Anyone still
 * aboard is put out (the aircraft is about to go), the aircraft and its crew
 * are removed, and the leader's page is told.
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
private _i = GVAR(runs) findIf {(_x get "leader") isEqualTo (_st get "leader")};
if (_i >= 0) then {GVAR(runs) deleteAt _i};

private _veh = _st get "veh";
private _aboard = (_st get "jumpers") select {alive _x && {vehicle _x isEqualTo _veh || {attachedTo _x isEqualTo _veh}}};
{
    // By remoteExec to where he is local, taken only from the server (review S7).
    [_x, _veh, _st get "type"] remoteExecCall [QFUNC(jump), _x];
} forEach _aboard;

(_st get "leader") setVariable [QGVAR(run), [], true];
["The jump is over.", "normal"] remoteExecCall [QFUNC(say), _st get "leader"];

// The last men need a moment to be out before the hull goes.
[{
    params ["_veh"];
    if (isNull _veh) exitWith {};
    {deleteVehicle _x} forEach (crew _veh select {!isPlayer _x});
    deleteVehicle _veh;
}, [_veh], JUMP_INTERVAL * 4] call CBA_fnc_waitAndExecute;
