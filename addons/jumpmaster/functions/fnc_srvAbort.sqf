#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the leader aborted (by remoteExec, from FUNC(abort)). No more
 * passes: the aircraft holds over the drop zone while anyone is aboard, with
 * JUMP open to every man, and leaves once the cabin is empty (FUNC(srvTick)).
 *
 * The leader named must be the sender's own unit (review S7: it was a CBA
 * event, so any client could abort any squad's run).
 *
 * Arguments:
 * 0: The leader <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_jumpmaster_fnc_srvAbort
 *
 * Public: No
 */

params [["_leader", objNull, [objNull]]];

if (!isServer || {isNull _leader}) exitWith {};
if !([_leader] call EFUNC(common,senderIs)) exitWith {
    WARNING_1("srvAbort: refused - machine %1 named a leader not its own",remoteExecutedOwner);
};

private _i = GVAR(runs) findIf {(_x get "leader") isEqualTo _leader};
if (_i < 0) exitWith {};
private _st = GVAR(runs) select _i;
if ((_st get "phase") in [PHASE_HOLD, PHASE_LEAVE]) exitWith {};

_st set ["passes", (_st get "pass") + 1];
_st set ["phase", PHASE_HOLD];
[_st get "veh", _st get "green", "NORMAL", "LOITER", HOLD_RADIUS] call EFUNC(support_air,moveTo);
[_st, "Jump aborted by the jumpmaster. Holding over the drop zone: JUMP when ready, or stay aboard.", true] call FUNC(srvLight);
