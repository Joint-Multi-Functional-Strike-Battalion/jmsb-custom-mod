#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the issuer's answer in a QRF's link-up thread (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 7) - from FUNC(threadReply). Only the thread
 * the QRF was sent for moves it:
 *   "received"  to SQUAD DOWN ... LINKED UP?: CLOSED "LINKED UP - <the squad>"
 *   "stop"      CLOSE, RTB. The squad on the ground: the thread is closed
 *               with where it is (it stays). In the air before anyone is out:
 *               the insertion is aborted, squad and aircraft home
 *               (FUNC(qrfTick)), CLOSED "RTB". Still launching: stood down
 *               (FUNC(qrfLaunch), CANTCO)
 *
 * THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md tree 5, 2026-11-09):
 *   "escort"    ESCORT, any time: the aircraft's drone escorts
 *               (FUNC(escortCall))
 *   "move"      MOVE: on the way in, the insertion goes to the new point
 *               (its ON ARRIVAL is the card's method there - land or rope,
 *               or the static line); the squad down, it moves there
 *   "frago"     FRAGO: the merged order - a new link-up as MOVE, its ACTION
 *               ON ARRIVAL taken for what the squad does there
 *   "hold"      on the way in (or before the ropes go): it orbits where it
 *               is till told; the squad down, it stops where it is
 *   "abort"     the same stop - the landing or the rope hover not completed
 *               - and STATE INTENTIONS (EFUNC(support,askIntentions))
 *   "confirm"   EXECUTE to a held or aborted QRF: on in to its point again
 *   "stop"      an RTB with a LAND AT point and players aboard (user,
 *               2026-11-09, EFUNC(support,rtbLanding)): it flies there,
 *               circles for the mark and the clearance, lands, asks PAX OFF?
 *               and goes home once they are out (FUNC(qrfTick) "rtbIn")
 *   "paxoff"    PAX OFF at that landing: home, CLOSED RTB
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: The reply <HASHMAP>
 * 3: Who sent it <OBJECT>
 * 4: What it is <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air:3", _thread, _message, _issuer, "received"] call jmfsb_support_air_fnc_qrfReply
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
    WARNING_1("qrfReply: refused - remote call from machine %1",remoteExecutedOwner);
};
if !(_word in [WORD_RECEIVED, WORD_STOP, WORD_ESCORT, WORD_ABORT, WORD_HOLD, WORD_MOVE, WORD_FRAGO, WORD_CONFIRM, WORD_PAXOFF]) exitWith {};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {};
private _job = _logic getVariable [QGVAR(qrfJob), createHashMap];
private _threadId = _thread getOrDefault ["id", ""];
if ((_job getOrDefault ["thread", ""]) isNotEqualTo _threadId) exitWith {};
private _callsign = _logic getVariable [QGVAR(callsign), "QRF"];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _st = _logic getVariable [QGVAR(qrfState), createHashMap];
private _phase = _st getOrDefault ["phase", ""];
private _grp = _st getOrDefault ["group", grpNull];
INFO_3("qrfReply: %1 '%2' from %3",_callsign,_word,name _who);

private _fnc_close = {
    params ["_said"];
    [_logic, "CLOSED", _said, _threadId] call FUNC(threadState);
    _logic setVariable [QGVAR(qrfJob), nil];
    if ((_logic getVariable [QGVAR(threadHold), ""]) isEqualTo _threadId) then {
        _logic setVariable [QGVAR(threadHold), nil];
    };
};
// The aircraft can still be stopped short of its insertion: on the way in,
// circling, or before the ropes go.
private _inbound = alive _veh && {_phase in ["in", "ropeIn", "landing", QRF_PHASE_HELD]} && {!isTouchingGround _veh || _phase isEqualTo QRF_PHASE_HELD};
private _down = (_job get "step") isEqualTo JOB_LINKUP;

// The insertion re-aimed at a point - MOVE and FRAGO alike.
private _fnc_reaim = {
    params ["_pos"];
    [_threadId, WORD_ABORT] call EFUNC(support,lzClearReply);
    _job set ["landing", ""];
    _job set ["landAt", []];
    _st set ["pos", _pos];
    _st set ["phase", "in"];
    [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
    [_veh, _pos, "NORMAL"] call FUNC(moveTo);
    _logic setVariable [QGVAR(status), "inbound", true];
    private _task = _st getOrDefault ["task", TASK_ASSAULT];
    [_threadId, [[[ZONE_QRF, ZONE_QRF_DROP] select (_task isEqualTo TASK_STATIC), _pos, _callsign]], _logic getVariable [QGVAR(side), west]] call EFUNC(support,zones);
};
// The squad down, sent to a point (it holds it).
private _fnc_squadTo = {
    params ["_pos"];
    if (isNull _grp) exitWith {};
    [_grp] call CBA_fnc_clearWaypoints;
    [_grp, _pos, 0, "MOVE", "AWARE", "YELLOW"] call CBA_fnc_addWaypoint;
};
// Stopped where it is.
private _fnc_stop = {
    if (_inbound) exitWith {
        [_threadId, WORD_ABORT] call EFUNC(support,lzClearReply);
        _job set ["landing", ""];
        if (!isNil "ace_fastroping_fnc_cutRopes" && {(_veh getVariable ["ace_fastroping_deployedRopes", []]) isNotEqualTo []}) then {
            [_veh] call ace_fastroping_fnc_cutRopes;
        };
        _veh land "NONE";
        [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
        [_veh, getPosATL _veh, "LIMITED", "LOITER", LZ_HOLD_ORBIT] call FUNC(moveTo);
        _st set ["phase", QRF_PHASE_HELD];
        _logic setVariable [QGVAR(status), "holding", true];
        true
    };
    if (_down && {!isNull _grp}) exitWith {
        [_grp] call CBA_fnc_clearWaypoints;
        {doStop _x} forEach units _grp;
        true
    };
    false
};

switch (_word) do {
    case WORD_ESCORT: {
        [_logic, _veh, _st getOrDefault ["pos", []], _assetId, _logic getVariable [QGVAR(side), west], _threadId, _callsign] call FUNC(escortCall);
    };

    case WORD_MOVE: {
        private _move = [_thread, _message] call EFUNC(support,readOrder);
        private _pos = _move getOrDefault ["point", []];
        if (_pos isEqualTo []) exitWith {[_logic, _threadId, WHY_NO_TARGET] call FUNC(liftSay)};
        if (_inbound) exitWith {
            [_pos] call _fnc_reaim;
            [_logic, _threadId, format [SAID_WILCO, format [SAID_MOVE_WILCO, mapGridPosition _pos, _move getOrDefault ["arrival", ""]]]] call FUNC(liftSay);
        };
        if (_down) exitWith {
            [_pos] call _fnc_squadTo;
            [_logic, _threadId, format [SAID_WILCO, format [SAID_MOVE_WILCO, mapGridPosition _pos, MOVE_HOLD]]] call FUNC(liftSay);
        };
        [_logic, _threadId, SAID_FRAGO_NONE] call FUNC(liftSay);
    };

    case WORD_FRAGO: {
        private _order = [_thread, _message] call EFUNC(support,readOrder);
        private _pos = _order getOrDefault ["linkup", []];
        private _action = _order getOrDefault ["action", ""];
        if ((QRF_DEFEND_WORDS findIf {_x in _action}) >= 0) then {_job set ["onLanding", ON_LANDING_DEFEND]};
        if ((QRF_JOIN_WORDS findIf {_x in _action}) >= 0) then {_job set ["onLanding", ON_LANDING_JOIN]};
        private _changed = ([(_message getOrDefault ["frago", createHashMap]) getOrDefault ["payload", []]] call EFUNC(messaging,fragoLines)) apply {toUpper (_x select 0)};
        private _what = [_changed joinString ", ", ORDER_LINKUP] select (_changed isEqualTo []);
        if (_pos isNotEqualTo [] && _inbound) then {[_pos] call _fnc_reaim};
        if (_pos isNotEqualTo [] && _down) then {[_pos] call _fnc_squadTo};
        [_logic, _threadId, format [SAID_WILCO, format [SAID_FRAGO, toUpper _what]]] call FUNC(liftSay);
    };

    case WORD_HOLD: {
        if (call _fnc_stop) then {[_logic, _threadId, format [SAID_HELD, mapGridPosition ([_veh, leader _grp] select _down)]] call FUNC(liftSay)};
    };

    case WORD_ABORT: {
        if !(call _fnc_stop) exitWith {};
        [_assetId, _threadId, _callsign, SAID_ABORTED, ANSWERS_CARRY_ON, {_this call FUNC(threadTimeout)}] call EFUNC(support,askIntentions);
    };

    case WORD_PAXOFF: {
        if (_phase isNotEqualTo QRF_PHASE_RTB_DOWN) exitWith {};
        _st set ["phase", "home"];
        [SAID_RTB] call _fnc_close;
    };

    case WORD_CONFIRM: {
        if (_phase isNotEqualTo QRF_PHASE_HELD || {!alive _veh}) exitWith {};
        [_st getOrDefault ["pos", getPosATL _veh]] call _fnc_reaim;
        [_logic, _threadId, format [SAID_WILCO, SAID_CARRY_ON]] call FUNC(liftSay);
    };

    default {
        if (_down) exitWith {
            private _line = _job get "line";
            [[_line, trim format ["%1 - %2", SAID_LINKED_UP, _line]] select (_word isEqualTo WORD_RECEIVED)] call _fnc_close;
        };
        if (_word isNotEqualTo WORD_STOP) exitWith {};

        // PLAYERS ABOARD (user, 2026-11-09): an RTB's LAND AT point first.
        private _land = [_message, _veh] call EFUNC(support,rtbLanding);
        if (_land isNotEqualTo [] && {_phase in ["in", "ropeIn", "landing", QRF_PHASE_HELD, QRF_PHASE_RTB_IN]}) exitWith {
            [_threadId, WORD_ABORT] call EFUNC(support,lzClearReply);
            _job set ["landing", ""];
            _job set ["landAt", []];
            _st set ["rtbPos", _land];
            _st set ["phase", QRF_PHASE_RTB_IN];
            _veh land "NONE";
            [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
            [_veh, _land, "NORMAL"] call FUNC(moveTo);
            _logic setVariable [QGVAR(status), "rtb", true];
            [_logic, _threadId, format [SAID_RTB_LAND, mapGridPosition _land]] call FUNC(liftSay);
        };

        // Still launching: FUNC(qrfLaunch) stands it down and declines the thread.
        if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_LAUNCHING) exitWith {
            _logic setVariable [QGVAR(abort), true, true];
            _logic setVariable [QGVAR(qrfJob), nil];
        };
        // Held: back to the way in, so the tick's abort sends it home.
        if (_phase isEqualTo QRF_PHASE_HELD) then {_st set ["phase", "in"]};
        _logic setVariable [QGVAR(abort), true, true];
        [SAID_RTB] call _fnc_close;
    };
};
