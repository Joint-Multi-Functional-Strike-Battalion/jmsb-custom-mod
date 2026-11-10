#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the issuer's answer in a transport's lift thread (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 5.4 and step 7) - from FUNC(threadReply). The core
 * passes the replies of the issuer, the observer and the FIRES net (D6), gated
 * again, as one word; only the thread the job flies for moves it:
 *
 *   "confirm"      a hot LZ confirmed: before the launch it lifts
 *                  (FUNC(liftGo)); held short on the way in, it goes in
 *   "cold"         1 MIN - LZ STATUS? answered cold: in
 *   "hot"          answered hot: HOT LZ - CONFIRM (confirm / rtb), held short
 *   "paxoff"       WHEELS DOWN - PAX OFF? answered: a LIFT REQUEST's
 *                  insertion is over - its EGRESS points, home, CLOSED EGRESS
 *                  - RTB (user, 2026-11-02: "4) insertion 5) egress"); a
 *                  casevac's or an extraction's destination: HOLD, RTB OR
 *                  NEXT LIFT?
 *   "allin"        TROOP LOAD - ALL IN? answered (user, 2026-11-02): it lifts
 *   "extractnow"   an extraction ON STATION called in: on to the HLZ
 *   "hold"         to PAX OFF?: it holds on the ground and asks again
 *                  (HOLDING - PAX OFF?); to HOLD, RTB OR NEXT LIFT?: it holds
 *                  there until the next order, asking nothing
 *   "destination"  to a casevac's DESTINATION? - the card's grid, else DEFAULT:
 *   or a message   the nearest medical facility (EFUNC(support,medicalNearest)),
 *                  else its base; a message gives a grid, a marker or DEFAULT
 *   "received"     PACKAGE AWAY - CONFIRM RECEIPT: CLOSED "RECEIVED"
 *   "notfound"     CLOSED "NOT FOUND - DROPPED AT <grid>"
 *   "task"         a NEXT LIFT - an `hlz`, `casevac` or `airdrop` filed in the
 *                  thread while it is out: WILCO with the ETA from where it is
 *                  (a RED LZ waits for CONFIRM again) and flown; no target:
 *                  NO TARGET LOCATION - HOLD, RTB OR NEXT LIFT?
 *
 * THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09):
 *
 *   "escort"       ESCORT, in any step: FUNC(escortCall) - up now, or with the
 *                  launch
 *   "abort"        ABORT is no longer a stop: it does not complete the
 *                  landing or the lift-off - it stops where it is and asks
 *                  STATE INTENTIONS (FUNC(liftHold), JOB_ABORTED)
 *   "hold"         beside its PAX OFF? and NEXT LIFT? meanings, in any other
 *                  step: it stops where it is till told (JOB_HELD)
 *   "confirm"      EXECUTE (CONFIRM retired): also a paradrop's STAND BY -
 *                  the drop - and a held or aborted lift's carry on
 *                  (FUNC(liftResume))
 *   "nodrop"       NO DROP to STAND BY: closed traffic, another pass; the
 *                  PARADROP_PASSES_MAX-th, or PARADROP_NODROPS_MAX in a row,
 *                  STATE INTENTIONS
 *   "move"         MOVE (DESTINATION retired): DESTINATION? answered with its
 *                  point; anywhere else FUNC(liftMove)
 *   "frago"        FUNC(liftFrago) - the job planned again from the merged
 *                  order
 *   "goaround"     GO AROUND the core's landing wait did not take (after
 *                  CLEARED TO LAND, a low hover): FUNC(liftGoAround)
 *   "continueapproach"  outside the wait: CONTINUING APPROACH
 *
 *   "stop"         an RTB with a LAND AT point and players aboard (2026-11-09,
 *                  EFUNC(support,rtbLanding)): there first - a MOVE LAND -
 *                  then PAX OFF? (or the players out), then home
 *   "stop"         CLOSE, RTB: waiting for a hot LZ's CONFIRM - CANTCO
 *                  "HOT LZ NOT ACKNOWLEDGED" (nothing to say after a CLOSE);
 *                  launching - stood down; out - home (FUNC(liftEnd))
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
 * ["air:1", _thread, _message, _issuer, "cold"] call jmfsb_support_air_fnc_liftReply
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
    WARNING_1("liftReply: refused - remote call from machine %1",remoteExecutedOwner);
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
private _threadId = _thread getOrDefault ["id", ""];
if ((_job getOrDefault ["thread", ""]) isNotEqualTo _threadId) exitWith {};

private _step = _job get "step";
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _cardId = _message getOrDefault ["templateId", ""];
INFO_4("liftReply: %1 '%2' (%3) from %4",_callsign,_word,_step,name _who);

// IN AGAIN from holding short.
private _fnc_goIn = {
    _job set ["step", JOB_FLYING];
    if !(_job get "holding") exitWith {};
    _job set ["holding", false];
    if (!alive _veh) exitWith {};
    private _order = _logic getVariable [QGVAR(order), []];
    [_veh, _order param [1, getPosATL _veh], SPEED_WORDS param [_order param [4, 0], "NORMAL"]] call FUNC(moveTo);
    [_logic, "going in", "normal", _job get "issuer"] call FUNC(say);
};
// The thread over, the job with it.
private _fnc_close = {
    params ["_said"];
    [_logic, "CLOSED", _said, _threadId] call FUNC(threadState);
    _logic setVariable [QGVAR(liftJob), nil];
    if (!isNull _veh) then {_veh setVariable [QGVAR(waveOff), nil, true]};
    if ((_logic getVariable [QGVAR(threadHold), ""]) isEqualTo _threadId) then {
        _logic setVariable [QGVAR(threadHold), nil];
    };
};

// A destination may come as a plain message, or as a MOVE (2026-11-09).
if (_word isEqualTo "" && _cardId isEqualTo CARD_FREETEXT && _step isEqualTo JOB_DEST) then {_word = WORD_DESTINATION};
if (_word isEqualTo WORD_MOVE && _step isEqualTo JOB_DEST) then {_word = WORD_DESTINATION};

switch (_word) do {
    case WORD_STOP: {
        // A CLOSE has closed the thread already; then nothing more is said.
        if (_step isEqualTo JOB_CONFIRM) exitWith {[_logic, WHY_HOT_LZ, "DECLINED"] call FUNC(liftEnd)};
        if (_step isEqualTo JOB_RECEIPT) exitWith {[SAID_SILENT] call _fnc_close};
        // PLAYERS ABOARD (user, 2026-11-09: "we need a way to set an rtb
        // landing location if an aircraft has players on board"): an RTB that
        // gives a LAND AT point flies there first, lands through the
        // clearance as every landing, waits for the players to get out (PAX
        // OFF? or the cabin empty of them, FUNC(liftTick)), then goes home.
        private _land = [_message, _veh] call EFUNC(support,rtbLanding);
        if (_land isNotEqualTo [] && {_logic getVariable [QGVAR(ticking), false]}) exitWith {
            private _move = createHashMapFromArray [["point", _land], ["arrival", MOVE_LAND], ["route", []], ["altitude", -1], ["minutes", -1]];
            if ([_logic, _move, format [SAID_RTB_LAND, mapGridPosition _land]] call FUNC(liftMove)) then {
                (_logic getVariable [QGVAR(liftJob), createHashMap]) set ["rtbLand", true];
            } else {
                [_logic, SAID_RTB] call FUNC(liftEnd);
            };
        };
        [_logic, SAID_RTB] call FUNC(liftEnd);
    };

    // ESCORT (user, 2026-11-09: "no mater the phase or tasking").
    case WORD_ESCORT: {
        private _point = _job getOrDefault ["lz", []];
        if (_point isEqualTo []) then {_point = _job getOrDefault ["first", []]};
        [_logic, _veh, _point, _assetId, _logic getVariable [QGVAR(side), west], _threadId, _callsign] call FUNC(escortCall);
    };

    case WORD_ABORT: {
        if (_step isEqualTo JOB_RECEIPT) exitWith {[SAID_SILENT] call _fnc_close};
        [_logic, JOB_ABORTED] call FUNC(liftHold);
    };

    case WORD_NO_DROP: {
        if (_step isNotEqualTo JOB_STANDBY) exitWith {};
        private _passes = (_job getOrDefault ["passes", 0]) + 1;
        _job set ["passes", _passes];
        if (_passes >= PARADROP_PASSES_MAX || _passes >= PARADROP_NODROPS_MAX) exitWith {
            [_logic, JOB_ABORTED, SAID_NO_DROP_END] call FUNC(liftHold);
        };
        [_assetId, _threadId, format [PROMPT_NO_DROP, _passes + 1], ANSWERS_STANDBY, _callsign, {_this call FUNC(threadTimeout)}, true, true] call EFUNC(support,prompt);
    };

    case WORD_MOVE: {
        [_logic, [_thread, _message] call EFUNC(support,readOrder)] call FUNC(liftMove);
    };

    case WORD_FRAGO: {
        [_logic, _thread, _message] call FUNC(liftFrago);
    };

    case WORD_GO_AROUND: {
        private _lz = [_logic] call FUNC(liftGoAround);
        if (_lz isNotEqualTo "") then {[_logic, _threadId, format [SAID_GOING_AROUND, _lz]] call FUNC(liftSay)};
    };

    case WORD_CONTINUE_APP: {
        [_logic, _threadId, SAID_CONTINUING] call FUNC(liftSay);
    };

    case WORD_CONFIRM: {
        // a held or aborted lift carries on (2026-11-09)
        if (_step in [JOB_HELD, JOB_ABORTED]) exitWith {[_logic] call FUNC(liftResume)};
        // the paradrop's STAND BY: the drop (2026-11-09)
        if (_step isEqualTo JOB_STANDBY) exitWith {
            {_job set _x} forEach [["dropCleared", true], ["closedTraffic", false], ["step", JOB_FLYING], ["passes", 0]];
            private _order = _logic getVariable [QGVAR(order), []];
            [_veh, _order param [1, getPosATL _veh], SPEED_WORDS param [_order param [4, 0], "NORMAL"]] call FUNC(moveTo);
            [_logic, _threadId, format [SAID_WILCO, SAID_EXECUTE]] call FUNC(liftSay);
        };
        // a RED insertion confirmed on the deck at its pickup: the troop load
        if (_step isEqualTo JOB_CONFIRM && {_job getOrDefault ["onDeck", false]}) exitWith {
            _job set ["hotPending", false];
            [_logic] call FUNC(liftLoad);
        };
        if (_step isEqualTo JOB_CONFIRM) exitWith {[_logic] call FUNC(liftGo)};
        if (_step isEqualTo JOB_HOT) exitWith {call _fnc_goIn};
    };

    case WORD_COLD: {
        if (_step isEqualTo JOB_LZ_STATUS) then {call _fnc_goIn};
    };

    case WORD_HOT: {
        if (_step isNotEqualTo JOB_LZ_STATUS) exitWith {};
        _job set ["step", JOB_HOT];
        [_logic, _threadId, PROMPT_HOT, ANSWERS_HOT] call FUNC(threadPrompt);
    };

    case WORD_PAXOFF: {
        if (_step isNotEqualTo JOB_PAX) exitWith {};
        // The RTB's landing for the players aboard (2026-11-09): home now.
        if (_job getOrDefault ["rtbLand", false]) exitWith {[_logic, SAID_RTB] call FUNC(liftEnd)};
        // THE INSERTION ENDS IN ITS EGRESS (user, 2026-11-02: "4) insertion
        // 5) egress"): the LIFT REQUEST's EGRESS points, home, CLOSED EGRESS -
        // RTB (FUNC(liftEnd)). AN EXTRACTION THE SAME (user, 2026-11-02:
        // "rtb via egress" - "Extraction and QRF lifts: the same, egress then
        // RTB"): its egress was flown from the HLZ, so home direct from its
        // destination. A casevac's destination still asks HOLD, RTB OR NEXT
        // LIFT?.
        if ((_job get "kind") in [ORDER_LIFT, ORDER_EXTRACT]) exitWith {[_logic, SAID_EGRESS] call FUNC(liftEnd)};
        _job set ["step", JOB_NEXT];
        [_logic, _threadId, PROMPT_NEXT, ANSWERS_NEXT] call FUNC(threadPrompt);
    };

    // ALL IN (user, 2026-11-02: "troop load, all in"): the troop load is done,
    // it lifts (FUNC(transportStep)). The ACE action aboard does the same
    // (FUNC(srvAllIn)).
    case WORD_ALL_IN: {
        if (_step isNotEqualTo JOB_ALL_IN) exitWith {};
        _job set ["allIn", true];
        [_logic, "all in, lifting", "normal", _job get "issuer"] call FUNC(say);
    };

    // EXTRACT (user, 2026-11-02: "1) on station 2) extraction"): off its
    // station and in to the HLZ (FUNC(liftTick)).
    case WORD_EXTRACT_NOW: {
        if (_step isNotEqualTo JOB_STATION) exitWith {};
        _job set ["step", JOB_FLYING];
    };

    case WORD_HOLD: {
        if (_step isEqualTo JOB_PAX) exitWith {
            [_logic, _threadId, PROMPT_PAX_HOLD, ANSWERS_PAX_HOLD] call FUNC(threadPrompt);
        };
        if (_step isEqualTo JOB_NEXT) exitWith {
            _job set ["step", JOB_HOLDING];
            [_logic, format ["holding at %1", mapGridPosition _veh], "normal", _job get "issuer"] call FUNC(say);
        };
        // HOLD WIDENED (2026-11-09): stop where you are and wait, any step.
        if (_step in [JOB_HOLDING, JOB_HELD, JOB_RECEIPT]) exitWith {};
        [_logic, JOB_HELD] call FUNC(liftHold);
    };

    case WORD_DESTINATION: {
        if (_step isNotEqualTo JOB_DEST) exitWith {};
        private _answer = [_thread, _message] call EFUNC(support,readOrder);
        private _point = _answer getOrDefault ["point", []];
        private _name = "";
        if (_point isEqualTo [] && !(_answer getOrDefault ["default", false])) exitWith {
            INFO_2("liftReply: %1 - '%2' gives no destination, still asking",_callsign,_answer getOrDefault [ARR_2("text","")]);
        };
        if (_point isEqualTo []) then {
            ([getPosATL _veh] call EFUNC(support,medicalNearest)) params [["_at", []], ["_what", ""]];
            _point = _at;
            _name = _what;
        };
        if (_point isEqualTo []) then {
            _point = _logic getVariable [QGVAR(home), getPosATL _logic];
            _name = "BASE";
        };
        _job set ["task", TASK_LAND];
        _job set ["first", _point];
        [_logic] call FUNC(liftGo);
        _job set ["destName", _name];
        // The pickup's zone gives way to the destination's (FUNC(liftZones)).
        [_logic] call FUNC(liftZones);
    };

    case WORD_RECEIVED: {
        if (_step isEqualTo JOB_RECEIPT) then {[SAID_RECEIVED] call _fnc_close};
    };

    case WORD_NOTFOUND: {
        if (_step isEqualTo JOB_RECEIPT) then {[format [SAID_NOT_FOUND, mapGridPosition (_job get "first")]] call _fnc_close};
    };

    case WORD_TASK: {
        // Out, or stopped on its pad by a HOLD or ABORT (2026-11-09).
        if (!(_logic getVariable [QGVAR(ticking), false]) && {!(_step in [JOB_HELD, JOB_ABORTED])}) exitWith {};
        private _order = [_thread, _message] call EFUNC(support,readOrder);
        // THE INSERTION AFTER THE PICKUP (user, 2026-11-08: "insertion happens
        // after a pickup"): filed in a PICKUP's thread before it lifts, its LZ,
        // route, egress and method join the job at that pickup - WILCO
        // INSERTION <grid>; on the ground there it asks the troop load now
        // (FUNC(liftLoad)), on the way it asks at wheels down (FUNC(liftTick)).
        // A RED LZ is confirmed first.
        if ((_job get "kind") isEqualTo ORDER_PICKUP && {(_order getOrDefault ["kind", ""]) isEqualTo ORDER_LIFT} && {!(_job getOrDefault ["lifted", false])}) exitWith {
            if ((_order getOrDefault ["lz", []]) isEqualTo []) exitWith {
                [_logic, _threadId, format ["%1 - %2", WHY_NO_TARGET, PROMPT_INSERT], ANSWERS_INSERT] call FUNC(threadPrompt);
            };
            private _next = [_logic, _order, _job get "issuer", _threadId, TASK_LIFT, _job get "first"] call FUNC(liftJob);
            {_next set [_x, _job getOrDefault [_x, _next get _x]]} forEach ["legs", "leg", "down"];
            _next set ["onDeck", _job getOrDefault ["onDeck", false]];
            private _hot = (_order getOrDefault ["security", ""]) isEqualTo LZ_RED;
            _next set ["hotPending", _hot];
            _logic setVariable [QGVAR(liftJob), _next];
            private _method = ["", toUpper (_order getOrDefault ["insert", ""])] select ((_next get "insertTask") isNotEqualTo TASK_LAND);
            private _words = [format ["INSERTION %1", mapGridPosition (_order get "lz")], _method, toUpper (_order getOrDefault ["carry", ""])];
            if (_hot) then {_words = [WILCO_HOT] + _words};
            [_assetId, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP, _callsign, false, _threadId] call EFUNC(support,state);
            [_logic] call FUNC(liftZones);
            if (_next get "onDeck") then {[_logic] call FUNC(liftLoad)};
        };
        ([_logic, _order, _who] call FUNC(liftLegs)) params ["_task", "_first", "_why"];
        if (_why isNotEqualTo "") exitWith {
            _job set ["step", JOB_NEXT];
            [_logic, _threadId, PROMPT_NO_TARGET, ANSWERS_NEXT] call FUNC(threadPrompt);
        };
        private _next = [_logic, _order, _job get "issuer", _threadId, _task, _first] call FUNC(liftJob);
        _next set ["legs", _job get "legs"];
        _logic setVariable [QGVAR(liftJob), _next];

        private _from = [getPosATL _logic, getPosATL _veh] select (alive _veh);
        private _eta = [typeOf _veh, [_from, _first], SPEED_NORMAL] call FUNC(flightTime);
        private _hot = (_order getOrDefault ["security", ""]) isEqualTo LZ_RED;
        private _words = [[_eta] call EFUNC(support,etaText), toUpper (_order getOrDefault ["carry", ""])];
        if (_hot) then {_words = [WILCO_HOT] + _words};
        [_assetId, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP, _callsign, false, _threadId] call EFUNC(support,state);
        // The NEXT LIFT's zones replace the last card's (FUNC(liftZones)).
        [_logic] call FUNC(liftZones);
        if (_hot) exitWith {
            _next set ["step", JOB_CONFIRM];
            [_logic, _threadId, "", ANSWERS_HOT] call FUNC(threadPrompt);
        };
        [_logic] call FUNC(liftGo);
    };

    default {};
};
