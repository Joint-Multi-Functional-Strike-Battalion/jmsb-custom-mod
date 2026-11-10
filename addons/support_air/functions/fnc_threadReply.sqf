#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the issuer's follow-up in a CAS module's thread - the "reply" code
 * this addon hands the support core (2026-11-01, DESIGN_SUPPORT_MESSAGING
 * step 3). The core passes the replies of the issuer, the observer and the
 * FIRES net (D6), gated again, and says what each one is in one word:
 *
 *   "cleared"  CLEARED HOT. In a strike flown from station: in from the hold
 *              (FUNC(casJob)). In a helicopter's ATTACK RUN: in from where it
 *              holds short (FUNC(casTick)).
 *   "allattack" ALL ATTACK (user, 2026-11-02): CLEARED HOT for a fixed-wing
 *              flight's jet and its escort drones - the drones attack the
 *              target area too (FUNC(allAttack)). No escort up, or a
 *              helicopter: NO ESCORTS - USE CLEARED HOT, asked again.
 *   "stop"     CLOSE or RTB. In a strike from station: the strike is
 *              off, the aircraft goes back to (or stays at) the hold. In the
 *              thread the sortie flies for - the REQUEST ON STATION, or the
 *              helicopter's run: off station, home (doc 1.1, "or the
 *              on-station thread closed").
 *
 * THE PROMPTS (step 5, 2026-11-01, doc 5.4), after a strike released - a
 * strike from station holding at the hold, a helicopter's run holding short:
 *
 *   "bda"      the BDA (kept on the thread by the core), its DECISION (user,
 *              2026-11-02: "reattack or egress (reattack back to 3)"):
 *              EGRESS - it flies the strike's egress point (the card's Line
 *              4, else the sortie's) and goes home, its threads CLOSED EGRESS -
 *              RTB; RE-ATTACK with a store left - RE-ATTACK - <n> <store> LEFT
 *              - AWAITING CLEARED HOT; nothing left - home, WINCHESTER; an
 *              older deck's BDA with neither - FURTHER TASKING?
 *   "cleared"  the answer to the re-attack: in again (back to OFF -
 *              RETURNING TO STATION - REQUEST BDA after it), on the BDA's
 *              target when it gave one (EFUNC(support,threadBda)), else the
 *              same grid
 *   "no"       <n> MIN ON STATION - FURTHER TASKING? (its time left)
 *   "task"     a new `cas` card in the thread: FUNC(casRetask) - WILCO and
 *              held for CLEARED HOT; a card it cannot fly asks FURTHER
 *              TASKING? again, the reason in front
 *   "stop"     RTB (the `rtb` card) sends the sortie home from a strike from
 *              station too; CLOSE there ends that strike only
 *
 * THE 2026-11-09 FLOW (docs/DESIGN_MESSAGE_TEMPLATES.md, the trees' tree 3):
 *
 *   "correct"  the READBACK was right: a strike from station leaves the hold
 *              - IP INBOUND (FUNC(casJob)); a helicopter's run says IP
 *              INBOUND for its short hold, where IN asks (FUNC(casRun))
 *   "wrong"    SEND FRAGO
 *   "clearedengage"  Type 3: cleared like CLEARED HOT; ATTACK COMPLETE -
 *              REQUEST BDA after the pass instead of OFF
 *   "continue" at the IP, not cleared: a dry pass and IN again
 *   "abort"    the pass aborted, nothing released, STATE INTENTIONS - no
 *              longer a stop: it stays (a strike from station is dropped at
 *              the hold, its thread kept)
 *   "hold"     an orbit where it is until the next order
 *   "move"     a new station at the MOVE's point (a helicopter's run becomes
 *              a station there); its time up, FURTHER TASKING?
 *   "frago"    the order re-read (FUNC(casRetask)) - until IP INBOUND; after
 *              it, ABORT FIRST
 *   "bda"      three picks: RE-ATTACK - the run in again, a new clearance;
 *              BACK TO STATION - FURTHER TASKING?; RTB - the egress, home
 *   "task"     FUNC(casRetask) - WILCO, then the READBACK again
 * Its questions are EFUNC(cas,casAsk)'s; "stop" is now RTB and CLOSE only.
 *
 * Another thread's follow-up moves nothing. A transport's follow-ups are
 * FUNC(liftReply)'s, a QRF's FUNC(qrfReply)'s (step 7, 2026-11-01).
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: The reply <HASHMAP>
 * 3: Who sent it - the issuer, the observer or a man on the FIRES net <OBJECT>
 * 4: What it is - the support core's word, "" for anything else <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air:0", _thread, _message, _issuer, "cleared"] call jmfsb_support_air_fnc_threadReply
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
private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {};
// Transport and QRF by message (step 7, 2026-11-01): their own answers.
private _moduleKind = _logic getVariable [QGVAR(kind), ""];
if (_moduleKind isEqualTo KIND_TRANSPORT) exitWith {_this call FUNC(liftReply)};
if (_moduleKind isEqualTo KIND_QRF) exitWith {_this call FUNC(qrfReply)};
// Only these: the core hands the observer's fire calls over too (step 6).
if !(_word in WORDS_CAS) exitWith {};
private _threadId = _thread getOrDefault ["id", ""];
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _st = _logic getVariable [QGVAR(sortieState), createHashMap];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _minutes = ((_st getOrDefault ["until", CBA_missionTime]) - CBA_missionTime) / SECONDS_PER_MINUTE;
private _sortieThread = _logic getVariable [QGVAR(sortieThread), ""];

// The 2026-11-09 flow's words (EFUNC(cas,casAsk) - the drones say the same).
private _fnc_ask = {
    params ["_what", ["_values", []]];
    [_assetId, _threadId, _what, _values, _callsign, {_this call FUNC(threadTimeout)}] call EFUNC(cas,casAsk);
};
// Home, with the words its threads close with (FUNC(casTick)).
private _fnc_home = {
    params ["_said"];
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE) exitWith {};
    _st set ["said", _said];
    _logic setVariable [QGVAR(abort), true, true];
    INFO_3("%1 going home - %2 (%3)",_callsign,_said,name _issuer);
};
// A new `cas` card in the thread (step 5), or the order a FRAGO changed
// (2026-11-09 - the message is the order with the FRAGO laid over it):
// FUNC(casRetask), else FURTHER TASKING? again with why not.
private _fnc_retask = {
    private _order = [_thread, _message] call EFUNC(support,readOrder);
    if ((_order getOrDefault ["kind", ""]) isNotEqualTo ORDER_STRIKE) exitWith {};
    private _why = [_logic, _threadId, _order, _issuer] call FUNC(casRetask);
    if (_why isNotEqualTo "") then {[_logic, _threadId, CAS_TASKING, [_minutes, _why]] call FUNC(casSay)};
};
// After the BDA its DECISION decides - THREE PICKS (2026-11-09): RTB
// (BDA_EGRESS) - the strike's egress point, home (FUNC(casTick)
// "egressOut"); RE-ATTACK with a store left - RE-ATTACK - <n> <store> LEFT,
// and the run in again for a new clearance (true back - the caller resets
// the strike); BACK TO STATION, or an older deck's BDA with none - FURTHER
// TASKING?; nothing left - Winchester, home.
private _fnc_bda = {
    params ["_mag", "_egressTo"];
    private _decision = ([_thread, _message] call EFUNC(support,readOrder)) getOrDefault ["decision", ""];
    if (_decision isEqualTo BDA_EGRESS) exitWith {
        // The card's egress, else the sortie's own; neither - straight home.
        if (_egressTo isEqualTo []) then {_egressTo = _st getOrDefault ["egress", []]};
        _st set ["egressTo", _egressTo];
        [OFF_EGRESS] call _fnc_home;
        false
    };
    ([_veh, _mag] call EFUNC(cas,storesLeft)) params ["_rounds", "_name"];
    if (_rounds <= 0) exitWith {
        [OFF_WINCHESTER] call _fnc_home;
        false
    };
    if (_decision isNotEqualTo BDA_REATTACK) exitWith {
        [_logic, _threadId, CAS_TASKING, [_minutes, ""]] call FUNC(casSay);
        false
    };
    [CAS_ASK_LINE, [format [CAS_SAID_REATTACK, _rounds, _name]]] call _fnc_ask;
    true
};
// A re-attack goes in on the BDA's target when it gave one.
private _fnc_again = {
    private _again = ([_threadId] call EFUNC(support,threadBda)) getOrDefault ["target", []];
    if (_again isEqualTo []) exitWith {[]};
    _again params ["_ax", "_ay"];
    [_ax, _ay, 0]
};
// MOVE ON STATION (2026-11-09): the station moves to the MOVE's point - a
// fixed-wing's hold with it (FUNC(casTick)'s reposition); the MOVE's time up,
// FURTHER TASKING?.
private _fnc_reposition = {
    params ["_point", "_stay"];
    _logic setVariable [QGVAR(reposition), [CAS_MODE_LOITER, _point, (_st getOrDefault ["radius", RADIUS_MIN]) max RADIUS_MIN, "", false, _issuer]];
    [CAS_ASK_LINE, [format [CAS_SAID_MOVING, mapGridPosition _point]]] call _fnc_ask;
    if (_stay <= 0) exitWith {};
    [{
        params ["_logic", "_threadId", "_point"];
        if !(_logic getVariable [QGVAR(onStation), false]) exitWith {};
        if (((_logic getVariable [QGVAR(sortieState), createHashMap]) getOrDefault ["pos", []]) isNotEqualTo _point) exitWith {};
        [_logic, _threadId, CAS_TASKING, [-1, ""]] call FUNC(casSay);
    }, [_logic, _threadId, _point], _stay * SECONDS_PER_MINUTE] call CBA_fnc_waitAndExecute;
};
private _fnc_movePoint = {
    private _move = [_thread, _message] call EFUNC(support,readOrder);
    private _point = _move getOrDefault ["point", []];
    if (_point isEqualTo []) exitWith {[[], -1]};
    _point params ["_px", "_py"];
    [[_px, _py, 0], _move getOrDefault ["minutes", -1]]
};

// A strike from station.
private _job = _logic getVariable [QGVAR(job), createHashMap];
if ((_job getOrDefault ["thread", ""]) isEqualTo _threadId) exitWith {
    private _struck = _job getOrDefault ["struck", false];
    private _phase = _st getOrDefault ["phase", ""];
    // A re-attack: cleared on the way back, kept for the hold (FUNC(casTick)
    // "back"). A clearance before the READBACK came back is taken as its
    // CORRECT; it ends a HOLD (2026-11-09).
    private _fnc_cleared = {
        params ["_all"];
        if (_struck) then {
            private _again = call _fnc_again;
            if (_again isNotEqualTo []) then {_job set ["pos", _again]};
            _job set ["again", true];
        };
        _job set ["rb", RB_OK];
        _job set ["held", false];
        _job set ["engaged", _word isEqualTo WORD_CAS_ENGAGE];
        _job set ["allAttack", _all];
        _job set ["cleared", true];
    };
    // Off the run and back to the hold (ABORT, MOVE).
    private _fnc_turnBack = {
        if !(_phase in (JOB_PHASES_IN + ["jobHold"])) exitWith {};
        [_veh, "broken off", "", true] call EFUNC(cas,passEnd);
        [_veh, _st get "hold", "FULL"] call FUNC(moveTo);
        _st set ["phase", "back"];
        _logic setVariable [QGVAR(status), "off target", true];
    };
    switch (_word) do {
        case WORD_CAS_ENGAGE;
        case WORD_CLEARED: {[false] call _fnc_cleared};
        // ALL ATTACK (user, 2026-11-02): CLEARED HOT for the jet and its
        // escort drones (FUNC(allAttack) when it runs in, FUNC(casJob)); a
        // flight with no escort up - or a helicopter's - asks again.
        case WORD_ALL_ATTACK: {
            if !([_veh] call FUNC(canAllAttack)) exitWith {
                [_logic, _threadId, CAS_NO_ESCORTS, []] call FUNC(casSay);
            };
            [true] call _fnc_cleared;
        };
        // THE READBACK (2026-11-09): CORRECT - IP INBOUND (FUNC(casJob));
        // WRONG - SEND FRAGO.
        case WORD_CAS_CORRECT: {
            if ((_job getOrDefault ["rb", ""]) isNotEqualTo RB_ASKED) exitWith {};
            _job set ["rb", RB_OK];
            _job set ["held", false];
        };
        case WORD_CAS_WRONG: {
            if ((_job getOrDefault ["rb", ""]) isNotEqualTo RB_ASKED) exitWith {};
            [CAS_ASK_SEND_FRAGO] call _fnc_ask;
        };
        // CONTINUE (2026-11-09): a dry pass from the IP, no release, then IN
        // again (FUNC(casJob) "jobDry").
        case WORD_CAS_CONTINUE: {
            if !(_phase in ["jobIn", "jobIp"]) exitWith {};
            if (_job getOrDefault ["cleared", false]) exitWith {};
            _job set ["dry", true];
            [_veh, _job get "pos", "FULL"] call FUNC(moveTo);
            _st set ["phase", "jobDry"];
            _logic setVariable [QGVAR(status), "attacking", true];
            [CAS_ASK_LINE, [CAS_SAID_CONTINUE]] call _fnc_ask;
        };
        // ABORT (2026-11-09, JP 3-09.3 Fig V-13): the pass is aborted, nothing
        // released; back to the hold, the strike dropped there (FUNC(casTick)
        // "back") - the thread stays, and it asks STATE INTENTIONS.
        case WORD_CAS_ABORT: {
            _job set ["aborted", true];
            _job set ["cleared", false];
            call _fnc_turnBack;
            if (_phase isEqualTo "station") then {_logic setVariable [QGVAR(job), nil]};
            INFO_2("%1 strike aborted by %2",_callsign,name _issuer);
            [CAS_ASK_INTENTIONS, [CAS_SAID_ABORTED]] call _fnc_ask;
        };
        // HOLD (2026-11-09): off the run, an orbit where it is, until the next
        // order - a clearance, CORRECT, a new card, a MOVE (FUNC(casJob)).
        case WORD_CAS_HOLD: {
            if (!alive _veh) exitWith {};
            _job set ["held", true];
            _job set ["cleared", false];
            _job set ["inAsked", false];
            private _here = getPosATL _veh;
            if (_phase in JOB_PHASES_IN) then {
                [_veh, "holding", "", true] call EFUNC(cas,passEnd);
                [_veh, _here, "NORMAL", "LOITER", RADIUS_MIN] call FUNC(moveTo);
                _st set ["phase", "jobHold"];
                _logic setVariable [QGVAR(status), "holding", true];
            };
            [CAS_ASK_LINE, [format [CAS_SAID_HOLDING, mapGridPosition _here]]] call _fnc_ask;
        };
        // MOVE (2026-11-09): the strike is dropped, a new station.
        case WORD_CAS_MOVE: {
            (call _fnc_movePoint) params ["_point", "_stay"];
            if (_point isEqualTo []) exitWith {};
            call _fnc_turnBack;
            _logic setVariable [QGVAR(job), nil];
            [_point, _stay] call _fnc_reposition;
        };
        // A FRAGO (2026-11-09): taken until IP INBOUND.
        case WORD_CAS_FRAGO: {
            if (_job getOrDefault ["ip", false]) exitWith {[CAS_ASK_FRAGO_LATE] call _fnc_ask};
            call _fnc_retask;
        };
        case WORD_STOP: {
            // RTB sends the sortie home; CLOSE ends this strike only - unless
            // it is the thread the sortie flies for (doc 1.1).
            if ((_message getOrDefault ["templateId", ""]) isEqualTo CARD_RTB || _threadId isEqualTo _sortieThread) exitWith {[OFF_RTB] call _fnc_home};
            _job set ["stop", true];
        };
        case WORD_BDA: {
            if (!_struck) exitWith {};
            if !([_job getOrDefault ["mag", ""], _job getOrDefault ["egress", []]] call _fnc_bda) exitWith {};
            private _again = call _fnc_again;
            if (_again isNotEqualTo []) then {_job set ["pos", _again]};
            {_job set _x} forEach [["struck", false], ["begun", false], ["over", false], ["cleared", false], ["inAsked", false], ["ip", false], ["again", false]];
        };
        case WORD_NO: {
            if (_struck) then {[_logic, _threadId, CAS_TASKING, [_minutes, ""]] call FUNC(casSay)};
        };
        case WORD_CAS_TASK: {call _fnc_retask};
    };
    INFO_3("%1 strike %2 by %3",_callsign,_word,name _issuer);
};

// The thread the sortie flies for.
if (_sortieThread isNotEqualTo _threadId) exitWith {};
private _struck = _st getOrDefault ["struck", false];
private _run = (_st getOrDefault ["mode", ""]) isEqualTo "run";
private _pos = _st getOrDefault ["pos", []];
private _runIn = _logic getVariable [QGVAR(runIn), CAS_IP_DEFAULT];
// A helicopter's run off its pass to an orbit, nothing released (ABORT, HOLD).
private _fnc_break = {
    params ["_at"];
    [_veh, "broken off", "", true] call EFUNC(cas,passEnd);
    _logic setVariable [QGVAR(cleared), false];
    {_st set _x} forEach [["inAsked", false], ["moved", true], ["again", false], ["inSaid", false], ["phase", "short"]];
    [_veh, _at, "NORMAL", "LOITER", RADIUS_MIN] call FUNC(moveTo);
    _logic setVariable [QGVAR(status), "holding", true];
};
switch (_word) do {
    case WORD_CAS_ENGAGE;
    case WORD_CLEARED: {
        // A re-attack: cleared on the way out, kept for the turn back
        // (FUNC(casTick) "out").
        if (_struck) then {
            private _again = call _fnc_again;
            if (_again isNotEqualTo []) then {_st set ["pos", _again]};
            _st set ["again", true];
        };
        _st set ["rb", RB_OK];
        _st set ["moved", false];
        _st set ["engaged", _word isEqualTo WORD_CAS_ENGAGE];
        _logic setVariable [QGVAR(cleared), true];
        INFO_3("%1 %2 by %3",_callsign,_word,name _issuer);
    };
    // A helicopter's run: ALL ATTACK is a fixed-wing flight's (user,
    // 2026-11-02: "helicopter flights: not this time").
    case WORD_ALL_ATTACK: {[_logic, _threadId, CAS_NO_ESCORTS, []] call FUNC(casSay)};
    // THE READBACK (2026-11-09): CORRECT - IP INBOUND for the short hold,
    // where IN asks the clearance (FUNC(casRun)); WRONG - SEND FRAGO.
    case WORD_CAS_CORRECT: {
        if ((_st getOrDefault ["rb", ""]) isNotEqualTo RB_ASKED) exitWith {};
        _st set ["rb", RB_OK];
        _st set ["ip", true];
        private _eta = 0;
        if (alive _veh && _pos isNotEqualTo []) then {
            _eta = [typeOf _veh, [getPosATL _veh, _pos getPos [_runIn, _pos getDir _veh]], SPEED_FULL] call FUNC(flightTime);
        };
        [CAS_ASK_IP_INBOUND, [format [CAS_IP_ETA, [_eta] call EFUNC(support,etaText)]]] call _fnc_ask;
    };
    case WORD_CAS_WRONG: {
        if ((_st getOrDefault ["rb", ""]) isNotEqualTo RB_ASKED) exitWith {};
        [CAS_ASK_SEND_FRAGO] call _fnc_ask;
    };
    // CONTINUE (2026-11-09): a dry pass from the short hold (FUNC(casRun) "dry").
    case WORD_CAS_CONTINUE: {
        if (!_run || (_st getOrDefault ["phase", ""]) isNotEqualTo "short" || (_logic getVariable [QGVAR(cleared), true])) exitWith {};
        [_veh, _pos, "FULL"] call FUNC(moveTo);
        _st set ["phase", "dry"];
        _logic setVariable [QGVAR(status), "attacking", true];
        [CAS_ASK_LINE, [CAS_SAID_CONTINUE]] call _fnc_ask;
    };
    // ABORT (2026-11-09): the pass aborted, nothing released, back to its short
    // hold - not home - and STATE INTENTIONS.
    case WORD_CAS_ABORT: {
        if (_run && alive _veh && _pos isNotEqualTo []) then {
            [_pos getPos [_runIn, _pos getDir _veh]] call _fnc_break;
            _st set ["struck", false];
        };
        INFO_2("%1 aborted by %2",_callsign,name _issuer);
        [CAS_ASK_INTENTIONS, [CAS_SAID_ABORTED]] call _fnc_ask;
    };
    // HOLD (2026-11-09): an orbit where it is until the next order.
    case WORD_CAS_HOLD: {
        if (!alive _veh) exitWith {};
        private _here = getPosATL _veh;
        if (_run) then {[_here] call _fnc_break};
        [CAS_ASK_LINE, [format [CAS_SAID_HOLDING, mapGridPosition _here]]] call _fnc_ask;
    };
    // MOVE (2026-11-09): a helicopter's run becomes a station at the MOVE's
    // point (it checks in there and takes the next CAS REQUEST from it); an
    // aircraft on station moves its station.
    case WORD_CAS_MOVE: {
        (call _fnc_movePoint) params ["_point", "_stay"];
        if (_point isEqualTo [] || !alive _veh) exitWith {};
        if (_logic getVariable [QGVAR(onStation), false]) exitWith {[_point, _stay] call _fnc_reposition};
        if (!_run) exitWith {};
        [_veh, "moving", "", true] call EFUNC(cas,passEnd);
        private _radius = (_st getOrDefault ["radius", RADIUS_MIN]) max RADIUS_MIN;
        {_st set _x} forEach [["mode", CAS_MODE_LOITER], ["pos", _point], ["hold", _point], ["radius", _radius], ["struck", false], ["moved", true], ["phase", "in"]];
        if (_stay > 0) then {_st set ["stationTime", _stay * SECONDS_PER_MINUTE]};
        _logic setVariable [QGVAR(cleared), true];
        [group driver _veh, CAS_MODE_LOITER] call FUNC(casPosture);
        [_veh, _point, "NORMAL"] call FUNC(moveTo);
        _logic setVariable [QGVAR(status), "inbound", true];
        [CAS_ASK_LINE, [format [CAS_SAID_MOVING, mapGridPosition _point]]] call _fnc_ask;
    };
    // A FRAGO (2026-11-09): taken until IP INBOUND.
    case WORD_CAS_FRAGO: {
        if (_st getOrDefault ["ip", false]) exitWith {[CAS_ASK_FRAGO_LATE] call _fnc_ask};
        call _fnc_retask;
    };
    case WORD_STOP: {[OFF_RTB] call _fnc_home};
    case WORD_BDA: {
        if (!_struck) exitWith {};
        if !([_veh getVariable [QEGVAR(cas,ordnance), ""], _st getOrDefault ["egress", []]] call _fnc_bda) exitWith {};
        private _again = call _fnc_again;
        if (_again isNotEqualTo []) then {_st set ["pos", _again]};
        {_st set _x} forEach [["struck", false], ["inAsked", false], ["moved", false], ["ip", false], ["again", false]];
    };
    case WORD_NO: {
        if (_struck) then {[_logic, _threadId, CAS_TASKING, [_minutes, ""]] call FUNC(casSay)};
    };
    case WORD_CAS_TASK: {call _fnc_retask};
};
