#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the issuer's follow-up in a CAS drone's thread - the "reply" code
 * this addon hands the support core (2026-11-01, DESIGN_SUPPORT_MESSAGING
 * step 3). The core passes the replies of the issuer, the observer and the
 * FIRES net (D6), gated again, and says what each one is in one word (any
 * other word - the observer's fire calls - moves nothing here):
 *
 *   "cleared"  CLEARED HOT - the strike held over the grid runs in and
 *              releases (FUNC(request)'s run watch). After a strike it is the
 *              answer to RE-ATTACK?: in again, on the BDA's target when the
 *              BDA gave one (EFUNC(support,threadBda)), else on the same grid
 *   "stop"     CLOSE, ABORT or RTB - the drone leaves, as a recall
 *   "allattack" ALL ATTACK (user, 2026-11-02) is a fixed-wing flight's with
 *              escort drones; a CAS drone has none: NO ESCORTS - USE CLEARED
 *              HOT, asked again
 *
 * THE PROMPTS (step 5, 2026-11-01, doc 5.4) - while it holds over the grid
 * after a strike:
 *
 *   "bda"      the BDA (kept on the thread by the core), its DECISION (user,
 *              2026-11-02: "reattack or egress"): EGRESS - it leaves on its
 *              egress line, CLOSED EGRESS - RTB; RE-ATTACK with a store left -
 *              RE-ATTACK - <n> <store> LEFT - AWAITING CLEARED HOT, CLEARED
 *              HOT runs it in again and back to OFF - RETURNING TO STATION -
 *              REQUEST BDA; nothing left - it leaves, CLOSED WINCHESTER; an
 *              older deck's BDA with neither - FURTHER TASKING?
 *   "no"       no re-attack: <n> MIN ON STATION - FURTHER TASKING?
 *   "task"     a new `cas` card in the thread: the same checks as a new
 *              thread (target, danger close, the store, a laser) on the
 *              drone in the air - WILCO with its ETA from where it is, held
 *              over the new grid for CLEARED HOT (60 s: AWAITING CLEARED HOT).
 *              It comes from where it is; the card's ingress is not flown. A
 *              card it cannot fly asks FURTHER TASKING? again, the reason in
 *              front
 *
 * THE 2026-11-09 FLOW (docs/DESIGN_MESSAGE_TEMPLATES.md, the trees' tree 3):
 *   "correct"  the READBACK was right: IP INBOUND (its ETA), and over the
 *              grid IN asks the clearance (FUNC(runTick))
 *   "wrong"    SEND FRAGO
 *   "clearedengage"  Type 3: cleared like CLEARED HOT; after the pass it
 *              reports ATTACK COMPLETE - REQUEST BDA instead of OFF
 *   "continue" no release yet: it keeps its orbit and asks IN again
 *   "abort"    the pass aborted, nothing released, STATE INTENTIONS - it no
 *              longer goes home on ABORT ("stop" is RTB and CLOSE)
 *   "hold"     off the run, an orbit where it is, until the next order
 *   "move"     a new station: it orbits the MOVE's point for the next CAS
 *              REQUEST; the MOVE's time up, FURTHER TASKING?
 *   "frago"    the order re-read - until IP INBOUND (the READBACK not yet
 *              CORRECT); after it, ABORT FIRST
 *   "bda"      three picks: RE-ATTACK - IN asks a new clearance; BACK TO
 *              STATION - FURTHER TASKING?; RTB - out by its egress, home
 *   "task"     a new CAS REQUEST - WILCO, then the READBACK again
 * The questions are FUNC(casAsk)'s.
 *
 * Only for the thread the drone is flying now; an older thread's follow-up
 * moves nothing.
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: The reply <HASHMAP>
 * 3: The issuer <OBJECT>
 * 4: What it is - the support core's word, "" for anything else <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["cas:0", _thread, _message, _issuer, "cleared"] call jmfsb_cas_fnc_threadReply
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_issuer", objNull, [objNull]],
    ["_word", "", [""]]
];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("threadReply: refused - remote call from machine %1",remoteExecutedOwner);
};

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {};
private _threadId = _thread getOrDefault ["id", ""];
if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};
if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) in STATUSES_NO_RUN) exitWith {};

private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];
private _run = _logic getVariable [QGVAR(run), createHashMap];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _struck = _run getOrDefault ["struck", false];
private _minutes = ((_run getOrDefault ["until", CBA_missionTime]) - CBA_missionTime) / SECONDS_PER_MINUTE;

private _onEnd = {_this call FUNC(threadTimeout)};
private _fnc_ask = {
    params ["_what", ["_values", []]];
    [_assetId, _threadId, _what, _values, _callsign, _onEnd] call FUNC(casAsk);
};
// Off the pass and back to an orbit, nothing released (ABORT, HOLD, MOVE).
private _fnc_break = {
    params ["_at"];
    [_veh, "broken off", "", true] call FUNC(passEnd);
    _veh setVariable [QGVAR(released), false];
    _veh setVariable [QGVAR(runIn), false];
    _logic setVariable [QGVAR(cleared), false];
    _run set ["again", false];
    _run set ["inAsked", false];
    _run set ["moved", true];
    _logic setVariable [QGVAR(status), STATUS_STATION, true];
    if (!alive _veh) exitWith {};
    private _grp = group driver _veh;
    [_grp] call CBA_fnc_clearWaypoints;
    private _wp = _grp addWaypoint [_at, 0];
    _wp setWaypointType "LOITER";
    _wp setWaypointLoiterRadius CAS_LOITER_RADIUS;
    _wp setWaypointSpeed "NORMAL";
};
// A new order in the thread - a new CAS REQUEST, or the order a FRAGO changed:
// the same checks as a new thread (target, danger close, the store, a laser)
// on the drone in the air; WILCO with its ETA from where it is, then the
// READBACK again (FUNC(runOrder)). It comes from where it is; the card's IP
// is not flown. A card it cannot fly asks FURTHER TASKING? again, the reason
// in front.
private _fnc_retask = {
    if (!alive _veh) exitWith {};
    private _order = [_thread, _message] call EFUNC(support,readOrder);
    if ((_order getOrDefault ["kind", ""]) isNotEqualTo ORDER_STRIKE) exitWith {};

    private _target = _order getOrDefault ["target", []];
    private _why = ["", WHY_NO_TARGET] select (_target isEqualTo []);
    private _mag = "";
    if (_why isEqualTo "") then {
        ([_order, _logic getVariable [QGVAR(side), west]] call EFUNC(support,dangerClose)) params ["_safe", "_unsafeWhy"];
        if (!_safe) then {_why = _unsafeWhy};
    };
    if (_why isEqualTo "") then {
        ([_veh, _order] call FUNC(orderStore)) params ["_armed", "_unarmedWhy", "_storeMag"];
        if (_armed) then {_mag = _storeMag} else {_why = _unarmedWhy};
    };
    if (_why isNotEqualTo "") exitWith {
        [_logic, _threadId, CAS_TASKING, [_minutes, _why]] call FUNC(threadSay);
    };

    // The new run: from where it is, out by the card's egress or straight
    // through, the run-in floor kept. A pass still under way is over.
    [_veh, "re-tasked", "", true] call FUNC(passEnd);
    private _dist = _run getOrDefault ["distance", REACH_DEF_DISTANCE];
    private _end = _order getOrDefault ["egress", []];
    if (_end isEqualTo []) then {_end = _target getPos [_dist, (getPosATL _veh) getDir _target]};
    if (_end distance2D _target < _dist) then {_end = _target getPos [_dist, _target getDir _end]};
    {_run set _x} forEach [
        ["pos", _target],
        ["end", _end],
        ["egressHdg", _target getDir _end],
        ["inDir", -1],
        ["mag", _mag],
        ["struck", false],
        ["offSaid", false],
        ["again", false],
        ["aimNext", []]
    ];
    _veh setVariable [QGVAR(ordnance), _mag];
    _veh setVariable [QGVAR(released), false];
    _veh setVariable [QGVAR(runIn), false];
    _logic setVariable [QGVAR(status), STATUS_MISSION, true];
    private _grp = group driver _veh;
    [_grp] call CBA_fnc_clearWaypoints;
    private _wp = _grp addWaypoint [_target, 0];
    _wp setWaypointType "LOITER";
    _wp setWaypointLoiterRadius CAS_LOITER_RADIUS;
    _wp setWaypointSpeed "NORMAL";

    // WILCO with the ETA from where it is, then the READBACK.
    private _speed = ((_logic getVariable [QGVAR(speed), REACH_DEF_SPEED]) / KMH_PER_MS) max 1;
    private _words = [[(_veh distance2D _target) / _speed] call EFUNC(support,etaText)];
    private _what = _order getOrDefault ["description", ""];
    if (_what isNotEqualTo "") then {_words pushBack (_what select [0, DESCRIPTION_MAX])};
    [_assetId, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP, _callsign, false, _threadId] call EFUNC(support,state);
    [_logic, _threadId, _order] call FUNC(runOrder);
    [CAS_ASK_READBACK, [mapGridPosition _target, _order getOrDefault ["remarks", ""]]] call _fnc_ask;
    INFO_3("%1 re-tasked in thread %2 onto %3",_callsign,_threadId,mapGridPosition _target);
};

switch (_word) do {
    // CLEARED HOT, or - Type 3 - CLEARED TO ENGAGE (2026-11-09): a clearance
    // given before the READBACK came back is taken as its CORRECT.
    case WORD_CAS_ENGAGE;
    case WORD_CLEARED: {
        _run set ["rb", RB_OK];
        _run set ["moved", false];
        _run set ["engaged", _word isEqualTo WORD_CAS_ENGAGE];
        // RE-ATTACK (step 5): on the BDA's target when it gave one.
        if (_struck) then {
            private _again = ([_threadId] call EFUNC(support,threadBda)) getOrDefault ["target", []];
            if (_again isNotEqualTo []) then {
                _again params ["_ax", "_ay"];
                _again = [_ax, _ay, 0];
                // Still on its way out: the new aim waits for the turn back
                // (FUNC(request)'s run watch), the egress point it flies to
                // stays.
                if (_veh getVariable [QGVAR(released), false]) exitWith {_run set ["aimNext", _again]};
                _run set ["pos", _again];
                _run set ["end", _again getPos [_run getOrDefault ["distance", REACH_DEF_DISTANCE], _run getOrDefault ["egressHdg", 0]]];
            };
            _run set ["struck", false];
            // Cleared while still on its way out: kept for when it turns back.
            _run set ["again", true];
            _logic setVariable [QGVAR(status), STATUS_MISSION, true];
            INFO_1("%1 re-attacking",_callsign);
        };
        _logic setVariable [QGVAR(cleared), true];
        INFO_3("%1 %2 by %3",_callsign,_word,name _issuer);
    };
    // THE READBACK (2026-11-09): CORRECT - IP INBOUND, and over the grid IN
    // asks the clearance (FUNC(runTick)); WRONG - SEND FRAGO.
    case WORD_CAS_CORRECT: {
        if ((_run getOrDefault ["rb", ""]) isNotEqualTo RB_ASKED) exitWith {};
        _run set ["rb", RB_OK];
        private _speed = ((_logic getVariable [QGVAR(speed), REACH_DEF_SPEED]) / KMH_PER_MS) max 1;
        private _eta = if (alive _veh) then {(_veh distance2D (_run getOrDefault ["pos", getPosATL _veh])) / _speed} else {0};
        [CAS_ASK_IP_INBOUND, [format [CAS_IP_ETA, [_eta] call EFUNC(support,etaText)]]] call _fnc_ask;
    };
    case WORD_CAS_WRONG: {
        if ((_run getOrDefault ["rb", ""]) isNotEqualTo RB_ASKED) exitWith {};
        [CAS_ASK_SEND_FRAGO] call _fnc_ask;
    };
    // CONTINUE (2026-11-09): no release yet - a drone's run in is its orbit of
    // the grid, so it keeps it and asks IN again CAS_CONTINUE_DELAY s on.
    case WORD_CAS_CONTINUE: {
        if (_logic getVariable [QGVAR(cleared), true]) exitWith {};
        _run set ["inAsked", false];
        _run set ["continueAt", CBA_missionTime + CAS_CONTINUE_DELAY];
        [CAS_ASK_LINE, [CAS_SAID_CONTINUE]] call _fnc_ask;
    };
    // ABORT (2026-11-09, JP 3-09.3 Fig V-13): the pass is aborted, nothing is
    // released, and it asks STATE INTENTIONS - it does not go home.
    case WORD_CAS_ABORT: {
        [_run getOrDefault ["pos", getPosATL _veh]] call _fnc_break;
        _run set ["struck", false];
        INFO_2("%1 aborted by %2",_callsign,name _issuer);
        [CAS_ASK_INTENTIONS, [CAS_SAID_ABORTED]] call _fnc_ask;
    };
    // HOLD (2026-11-09): off the run, an orbit where it is, until the next order.
    case WORD_CAS_HOLD: {
        if (!alive _veh) exitWith {};
        private _here = getPosATL _veh;
        [_here] call _fnc_break;
        [CAS_ASK_LINE, [format [CAS_SAID_HOLDING, mapGridPosition _here]]] call _fnc_ask;
    };
    // MOVE (2026-11-09): a new station - it orbits the point for the next CAS
    // REQUEST; the MOVE's time up, FURTHER TASKING?.
    case WORD_CAS_MOVE: {
        private _move = [_thread, _message] call EFUNC(support,readOrder);
        private _point = _move getOrDefault ["point", []];
        if (_point isEqualTo [] || !alive _veh) exitWith {};
        _point params ["_px", "_py"];
        _point = [_px, _py, 0];
        [_point] call _fnc_break;
        _run set ["pos", _point];
        _run set ["struck", false];
        _run set ["end", _point getPos [_run getOrDefault ["distance", REACH_DEF_DISTANCE], _run getOrDefault ["egressHdg", 0]]];
        [CAS_ASK_LINE, [format [CAS_SAID_MOVING, mapGridPosition _point]]] call _fnc_ask;
        private _stay = _move getOrDefault ["minutes", -1];
        if (_stay > 0) then {
            [{
                params ["_logic", "_threadId", "_run"];
                if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};
                if !(_run getOrDefault ["moved", false]) exitWith {};
                [_logic, _threadId, CAS_TASKING, [-1, ""]] call FUNC(threadSay);
            }, [_logic, _threadId, _run], _stay * SECONDS_PER_MINUTE] call CBA_fnc_waitAndExecute;
        };
    };
    // A FRAGO (2026-11-09): taken until IP INBOUND - the READBACK not yet
    // CORRECT; the message is the order with the FRAGO laid over it.
    case WORD_CAS_FRAGO: {
        if ((_run getOrDefault ["rb", RB_OK]) isEqualTo RB_OK) exitWith {[CAS_ASK_FRAGO_LATE] call _fnc_ask};
        call _fnc_retask;
    };
    // ALL ATTACK (user, 2026-11-02): a drone flies alone - asked again.
    case WORD_ALL_ATTACK: {[_logic, _threadId, CAS_NO_ESCORTS, []] call FUNC(threadSay)};
    case WORD_STOP: {
        if ((_message getOrDefault ["templateId", ""]) isEqualTo CARD_RTB) then {_run set ["said", SAID_RTB]};
        _logic setVariable [QGVAR(abort), true, true];
        INFO_2("%1 stood down by %2",_callsign,name _issuer);
    };
    case WORD_BDA: {
        if (!_struck) exitWith {};
        // THE BDA'S DECISION, THREE PICKS (2026-11-09): RTB (EGRESS) - out by
        // its egress point, then home to its module and removed
        // (FUNC(recover)), CLOSED EGRESS - RTB; RE-ATTACK with a store left -
        // RE-ATTACK - <n> <store> LEFT, and IN asks a new clearance over the
        // grid (FUNC(runTick)); BACK TO STATION, or an older deck's BDA with
        // none - FURTHER TASKING?.
        private _decision = ([_thread, _message] call EFUNC(support,readOrder)) getOrDefault ["decision", ""];
        if (_decision isEqualTo BDA_EGRESS) exitWith {
            INFO_1("%1 egress after the BDA - leaving",_callsign);
            _run set ["said", SAID_EGRESS];
            _logic setVariable [QGVAR(abort), true, true];
        };
        ([_veh, _run getOrDefault ["mag", ""]] call FUNC(storesLeft)) params ["_rounds", "_name"];
        if (_rounds > 0) exitWith {
            if (_decision isEqualTo BDA_REATTACK) exitWith {
                private _again = ([_threadId] call EFUNC(support,threadBda)) getOrDefault ["target", []];
                if (_again isNotEqualTo [] && !(_veh getVariable [QGVAR(released), false])) then {
                    _again params ["_ax", "_ay"];
                    _run set ["pos", [_ax, _ay, 0]];
                };
                _run set ["struck", false];
                _run set ["inAsked", false];
                _run set ["moved", false];
                [CAS_ASK_LINE, [format [CAS_SAID_REATTACK, _rounds, _name]]] call _fnc_ask;
            };
            [_logic, _threadId, CAS_TASKING, [_minutes, ""]] call FUNC(threadSay);
        };
        INFO_1("%1 Winchester after the BDA - leaving",_callsign);
        _run set ["said", SAID_WINCHESTER];
        _logic setVariable [QGVAR(abort), true, true];
    };
    case WORD_NO: {
        if (!_struck) exitWith {};
        [_logic, _threadId, CAS_TASKING, [_minutes, ""]] call FUNC(threadSay);
    };
    case WORD_TASK: {call _fnc_retask};
};
