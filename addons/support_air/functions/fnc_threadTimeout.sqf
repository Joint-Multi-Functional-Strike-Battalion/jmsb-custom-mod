#include "script_component.hpp"
/*
 * Author: YonV
 * Server: nobody answered a transport's or a QRF's prompt for 5 min (D9, user
 * 2026-11-01; the support core's prompt calls this, DESIGN_SUPPORT_MESSAGING
 * 5.4 and step 7):
 *
 *   a hot LZ never confirmed       CANTCO "HOT LZ NOT ACKNOWLEDGED" (home if
 *                                  it was out for a NEXT LIFT)
 *   a receipt or a link-up         CLOSED "NO RESPONSE" - the aircraft has
 *                                  gone already
 *   a QRF circling its grid        the insertion aborted, home, CLOSED "NO
 *                                  RESPONSE - RTB" (user, 2026-11-02)
 *   anything else on a transport   home, CLOSED "NO RESPONSE - RTB"
 *
 * And a CAS module's (step 5, 2026-11-01): a strike from station is dropped,
 * back to the hold, CLOSED "NO RESPONSE"; the thread its sortie flies for
 * sends it home, CLOSED "NO RESPONSE - RTB".
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air:1", "T0042"] call jmfsb_support_air_fnc_threadTimeout
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("threadTimeout: refused - remote call from machine %1",remoteExecutedOwner);
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {};

// A CAS MODULE (step 5, 2026-11-01): AWAITING CLEARED HOT, REQUEST BDA,
// RE-ATTACK? or FURTHER TASKING? unanswered. A strike from station is dropped
// (back to the hold, CLOSED NO RESPONSE); the thread the sortie flies for
// sends it home, NO RESPONSE - RTB.
if ((_logic getVariable [QGVAR(kind), ""]) isEqualTo KIND_CAS) exitWith {
    private _job = _logic getVariable [QGVAR(job), createHashMap];
    if ((_job getOrDefault ["thread", ""]) isEqualTo _threadId && (_logic getVariable [QGVAR(sortieThread), ""]) isNotEqualTo _threadId) exitWith {
        _job set ["said", SAID_SILENT];
        _job set ["stop", true];
    };
    if ((_logic getVariable [QGVAR(sortieThread), ""]) isNotEqualTo _threadId) exitWith {};
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE) exitWith {};
    (_logic getVariable [QGVAR(sortieState), createHashMap]) set ["said", SAID_NO_RESPONSE];
    _logic setVariable [QGVAR(abort), true, true];
};

private _fnc_closeHeld = {
    params ["_said"];
    [_logic, "CLOSED", _said, _threadId] call FUNC(threadState);
    if ((_logic getVariable [QGVAR(threadHold), ""]) isEqualTo _threadId) then {
        _logic setVariable [QGVAR(threadHold), nil];
    };
};

// A QRF's link-up - or its air assault circling the grid, unanswered (user,
// 2026-11-02): the insertion is off, squad and aircraft home (FUNC(qrfTick)).
private _qrf = _logic getVariable [QGVAR(qrfJob), createHashMap];
if ((_qrf getOrDefault ["thread", ""]) isEqualTo _threadId) exitWith {
    if ((_qrf getOrDefault ["step", ""]) isNotEqualTo JOB_LINKUP) exitWith {
        _logic setVariable [QGVAR(abort), true, true];
        [SAID_NO_RESPONSE] call _fnc_closeHeld;
        _logic setVariable [QGVAR(qrfJob), nil];
    };
    [trim format ["%1 - %2", _qrf getOrDefault ["line", ""], SAID_SILENT]] call _fnc_closeHeld;
    _logic setVariable [QGVAR(qrfJob), nil];
};

private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if ((_job getOrDefault ["thread", ""]) isNotEqualTo _threadId) exitWith {};
switch (_job get "step") do {
    case JOB_CONFIRM: {[_logic, WHY_HOT_LZ, "DECLINED"] call FUNC(liftEnd)};
    case JOB_RECEIPT: {
        [SAID_SILENT] call _fnc_closeHeld;
        _logic setVariable [QGVAR(liftJob), nil];
    };
    default {[_logic, SAID_NO_RESPONSE] call FUNC(liftEnd)};
};
