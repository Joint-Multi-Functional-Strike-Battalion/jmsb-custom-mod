#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the issuer's answer in a logistics thread - the "reply" code this
 * addon hands the support core (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4 and
 * step 7). Only the thread the delivery flies for moves it:
 *
 *   "received"  to PACKAGE AWAY - CONFIRM RECEIPT: CLOSED "RECEIVED - <what
 *               was delivered>"
 *   "notfound"  every item set off its marking again where it lies, and
 *               CLOSED "NOT FOUND - LANDED AT <grids>"
 *   "stop"      CLOSE, ABORT, RTB. Waiting for the receipt: closed with what
 *               was delivered. Launching: stood down (FUNC(launch), CANTCO).
 *               In the air: recalled - what is still aboard is not delivered,
 *               and the thread closes with what was (FUNC(account)), no
 *               receipt asked
 *   "abort"     ABORT (2026-11-09, no longer a stop): as "stop" - a delivery
 *               is not called back into the hold
 *   "escort"    ESCORT (user, 2026-11-09): drone escorts now, or at the
 *               launch (EFUNC(support_air,escortCall))
 *   "frago"     FRAGO (2026-11-09): items or point only before it is loaded -
 *               it is airborne the frame after its WILCO, so FRAGO NOT TAKEN
 *               - LOADED (or - DELIVERED after the drop)
 *   "task"      a RESUPPLY REQUEST filed in the thread: another run once the
 *               last is down (FUNC(srvThread)); still on its way - unable
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: The reply <HASHMAP>
 * 3: Who sent it <OBJECT>
 * 4: What it is <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["logi:0", _thread, _message, _issuer, "received"] call jmfsb_support_logistics_fnc_threadReply
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_who", objNull, [objNull]],
    ["_word", "", [""]]
];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("threadReply: refused - remote call from machine %1",remoteExecutedOwner);
};
if !(_word in [WORD_RECEIVED, WORD_NOTFOUND, WORD_STOP, WORD_ABORT, WORD_ESCORT, WORD_FRAGO, WORD_TASK]) exitWith {};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {};
private _job = _logic getVariable [QGVAR(threadJob), createHashMap];
private _threadId = _thread getOrDefault ["id", ""];
private _callsign = _logic getVariable [QGVAR(callsign), DEF_CALLSIGN];

// ANOTHER RUN, SAME THREAD (2026-11-09, tree 5): a RESUPPLY REQUEST filed in
// the thread once the last one is down. The last one's receipt is closed with
// what it had - the thread stays open - and the new card goes the card's own
// way (FUNC(srvThread)). Still on its way: unable, said in the thread.
if (_word isEqualTo WORD_TASK) exitWith {
    if ((_job getOrDefault ["step", ""]) isEqualTo JOB_FLYING) exitWith {
        [_assetId, _threadId, SAID_STILL_RUNNING, false, _callsign] call EFUNC(support,threadEvent);
    };
    _logic setVariable [QGVAR(threadJob), nil];
    ([_assetId, _thread, _message, _who] call FUNC(srvThread)) params [["_ok", false], ["_why", ""]];
    if (!_ok) then {
        [_assetId, _threadId, format [SAID_NO_RUN, [_why, WHY_TASKED] select (_why isEqualTo "")], false, _callsign] call EFUNC(support,threadEvent);
    };
};

if ((_job getOrDefault ["thread", ""]) isNotEqualTo _threadId) exitWith {};
INFO_3("threadReply: %1 '%2' from %3",_callsign,_word,name _who);

// ESCORT (user, 2026-11-09: "a way to call in escorts to all transports no
// mater the phase or tasking"): up now with the aircraft, or with it at the
// launch (EFUNC(support_air,escortCall)).
if (_word isEqualTo WORD_ESCORT) exitWith {
    private _point = ((_logic getVariable [QGVAR(plan), []]) param [0, []]) param [0, []];
    [_logic, _logic getVariable [QGVAR(vehicle), objNull], _point, _assetId, _logic getVariable [QGVAR(side), west], _threadId, _callsign] call EFUNC(support_air,escortCall);
};

// FRAGO (2026-11-09, tree 5: "items or delivery point, before it is loaded"):
// the delivery is made airborne the frame after its WILCO (FUNC(deliver)), so
// a FRAGO finds it loaded - or already down - and is not taken; the thread
// says so. A new RESUPPLY REQUEST after the receipt is the next run.
if (_word isEqualTo WORD_FRAGO) exitWith {
    private _said = [SAID_FRAGO_DELIVERED, SAID_FRAGO_LOADED] select ((_job get "step") isEqualTo JOB_FLYING);
    [_assetId, _threadId, _said, false, _callsign] call EFUNC(support,threadEvent);
};

// ABORT (2026-11-09, no longer a stop): a delivery cannot be called back
// into the hold, so it stands down as RTB does - what is dropped stays, the
// aircraft goes home - and the thread closes.
if (_word isEqualTo WORD_ABORT) then {_word = WORD_STOP};

private _fnc_close = {
    params ["_said"];
    [_logic, "CLOSED", _said, _threadId] call FUNC(threadState);
    _logic setVariable [QGVAR(threadJob), nil];
};

if ((_job get "step") isEqualTo JOB_RECEIPT) exitWith {
    private _line = _job get "line";
    switch (_word) do {
        case WORD_RECEIVED: {[format ["%1 - %2", SAID_RECEIVED, _line]] call _fnc_close};
        case WORD_NOTFOUND: {
            private _items = (_job get "items") select {alive _x};
            private _grids = [];
            {
                _grids pushBackUnique mapGridPosition _x;
                [_x, _job get "signal"] call FUNC(markItem);
            } forEach _items;
            [format [SAID_NOT_FOUND, ["?", _grids joinString ", "] select (_grids isNotEqualTo [])]] call _fnc_close;
        };
        default {[_line] call _fnc_close};
    };
};
if (_word isNotEqualTo WORD_STOP) exitWith {};

// Stood down: the thread closes with what was delivered, no receipt asked.
_job set ["step", JOB_STOPPED];
_logic setVariable [QGVAR(abort), true, true];
