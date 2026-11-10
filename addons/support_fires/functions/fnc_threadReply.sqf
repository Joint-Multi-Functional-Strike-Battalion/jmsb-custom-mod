#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the observer's follow-up in a battery's call-for-fire thread - the
 * "reply" code this addon hands the support core (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 6). The core passes the replies of the
 * issuer, the card's observer and anyone on the FIRES net (D6), gated again,
 * and says what each one is in one word:
 *
 *   "adjust"     ADD / DROP / LEFT / RIGHT n m on the observer-target line,
 *                and the other axis when the card gives it (2026-11-02) -
 *                the observer the card names (where he is now, else where he
 *                was), else the issuer - and the next adjusting round there.
 *                Out of range or danger close (the card's threshold, its
 *                tick): asked again instead, nothing fired
 *   "ffe"        fire for effect on the point, ROUNDS per gun when given
 *   "repeat"     the last salvo again
 *   "confirm"    AT MY COMMAND: the first salvo
 *   "checkfire"  CHECK FIRE: rounds not yet fired are not fired (those in the
 *                air land); the battery holds, the mission and the thread open
 *   "bda"        the observer's BDA: END OF MISSION? - a battery's with what it
 *                has left, "12 HE, 6 SMOKE LEFT - END OF MISSION?" (2026-11-02)
 *   "record"     RECORD AS TARGET (user, 2026-11-02): the mission's point named
 *                and marked for the side (FUNC(record)) - "RECORDED AS TARGET
 *                AB1001", and the question it had asked again, less RECORD
 *   "stop"       CLOSE (= EOM), RTB: the battery stands down, CLOSED
 *   "abort"      ABORT (2026-11-09, no longer a stop): CHECK FIRE, then
 *                ABORTED - CHECK FIRE - STATE INTENTIONS (REPEAT, ADJUST,
 *                FFE, a new CALL FOR FIRE, CLOSE); a launcher ends as CLOSE
 *   "task"       a second CALL FOR FIRE in the thread: a new mission on the
 *                same guns (FUNC(threadRetask), 2026-11-09)
 *   "frago"      a FRAGO: the mission laid again from the order with its
 *                changes - shell, fuze, rounds, sheaf, method, target
 *                (FUNC(threadRetask))
 *
 * A call that fires while rounds are in the air waits for them to land (the
 * board's "wait for the splash"), at most CALL_WAIT s. Only for the thread the
 * battery fires for; another thread's follow-up moves nothing.
 *
 * A CRUISE MISSILE OR LOITERING MUNITION LAUNCHER (2026-11-01) takes "stop",
 * "repeat" (the launch again, FUNC(threadLaunch)), "confirm" and "bda" the
 * same way, and nothing else. Its missiles or munitions in the air count as
 * rounds in the air; CLOSE while they are out lets a missile fly on and sets a
 * munition off where it is (FUNC(loiterTick)).
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: The reply <HASHMAP>
 * 3: Who sent it <OBJECT>
 * 4: What it is <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["fires:0", _thread, _message, _observer, "adjust"] call jmfsb_support_fires_fnc_threadReply
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
if (_word isEqualTo "") exitWith {};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {};
private _threadId = _thread getOrDefault ["id", ""];
if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};

// A cruise missile or loitering munition launcher (2026-11-01) hears only
// CLOSE, REPEAT, CONFIRM and BDA: a launch has no adjust or check fire.
if ((_logic getVariable [QGVAR(type), ""]) isNotEqualTo TYPE_ARTY && !(_word in WORDS_STRIKE)) exitWith {};

private _status = _logic getVariable [QGVAR(status), STATUS_IDLE];
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
private _order = _logic getVariable [QGVAR(threadOrder), createHashMap];

// ROUNDS IN THE AIR (missiles, munitions): a call that fires is taken once
// they are down. Not down within CALL_WAIT (a continuous fire is minutes
// long): dropped, and the battery says so (2026-11-05) - no D9 waits on that
// prompt, the mission is still firing; CHECK FIRE is taken at once.
if (_word in WORDS_FIRE && _status in STATUSES_AIRBORNE) exitWith {
    INFO_2("%1: '%2' waits for the splash",_callsign,_word);
    [
        {!(((_this select 1) getVariable [QGVAR(status), STATUS_IDLE]) in STATUSES_AIRBORNE)},
        {(_this select 0) call FUNC(threadReply)},
        [_this, _logic],
        CALL_WAIT,
        {
            params ["", "_logic"];
            INFO_1("threadReply: a call waited %1 s for the splash and was dropped",CALL_WAIT);
            if ((_logic getVariable [QGVAR(type), ""]) isNotEqualTo TYPE_ARTY) exitWith {};
            // Hoisted: a comma inside a macro argument reads as a separator.
            private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
            INFO_1("%1: told to call again after the splash",_callsign);
            [_logic, PROMPT_IN_AIR, ANSWERS_IN_AIR, false] call FUNC(threadPrompt);
        }
    ] call CBA_fnc_waitUntilAndExecute;
};

INFO_3("%1: '%2' from %3",_callsign,_word,name _who);

switch (_word) do {
    case WORD_STOP: {
        [_logic, SAID_EOM] call FUNC(threadEnd);
    };

    case WORD_CHECKFIRE;
    case WORD_ABORT: {
        // A launcher's ABORT ends it as CLOSE does (2026-11-09): what is in
        // the air flies on.
        if ((_logic getVariable [QGVAR(type), ""]) isNotEqualTo TYPE_ARTY) exitWith {
            [_logic, SAID_EOM] call FUNC(threadEnd);
        };
        // Firing: the mission's token moves on, so its rounds not yet fired,
        // its SHOT / SPLASH cards and its end do nothing; it holds instead.
        // REPEAT resumes it (decision 7, FUNC(threadFire) from the hold).
        if (_status isEqualTo STATUS_FIRING) then {
            private _token = (_logic getVariable [QGVAR(token), -1]) + 1;
            _logic setVariable [QGVAR(token), _token];
            [_logic, _token, "check fire - rounds in the air will still land"] call FUNC(adjustHold);
        };
        // ABORT (2026-11-09): the same check fire, then STATE INTENTIONS.
        if (_word isEqualTo WORD_ABORT) exitWith {
            [_logic, PROMPT_ABORT, ANSWERS_ABORT] call FUNC(threadPrompt);
        };
        [_logic, PROMPT_CHECK_FIRE, ANSWERS_CHECK_FIRE] call FUNC(threadPrompt);
    };

    // A NEW MISSION ON THE SAME GUNS, or the mission's FRAGO (2026-11-09).
    case WORD_TASK;
    case WORD_FRAGO: {
        [_assetId, _thread, _message, _who, _word] call FUNC(threadRetask);
    };

    case WORD_ADJUST: {
        private _correction = [_thread, _message] call EFUNC(support,readOrder);
        private _target = _order getOrDefault ["target", []];
        if (_target isEqualTo []) exitWith {};

        // THE OBSERVER-TARGET LINE: the observer where he is now, else where he
        // was when he called it, else the gun-target line.
        private _observer = _order getOrDefault ["observer", objNull];
        private _from = _order getOrDefault ["observerPos", []];
        if (alive _observer) then {_from = getPosATL _observer};
        if (_from isEqualTo []) then {_from = _logic getVariable [QGVAR(origin), getPosATL _logic]};
        private _dir = _from getDir _target;

        // EVERY CORRECTION ON THE CARD, on the same line (report-card review,
        // 2026-11-02, decision 10: "RIGHT 50, ADD 100" is one transmission).
        private _corrections = _correction getOrDefault ["corrections", []];
        if (_corrections isEqualTo []) then {
            _corrections = [[_correction getOrDefault ["direction", ""], _correction getOrDefault ["distance", -1]]];
        };
        private _next = +_target;
        {
            _x params ["_word", "_distance"];
            private _metres = 0 max _distance;
            private _shift = switch (_word) do {
                case DIR_ADD: {[_metres, _dir]};
                case DIR_DROP: {[_metres, _dir + HALF_TURN]};
                case DIR_RIGHT: {[_metres, _dir + RIGHT_ANGLE]};
                case DIR_LEFT: {[_metres, _dir - RIGHT_ANGLE]};
                default {[0, _dir]};
            };
            (_next getPos _shift) params ["_nx", "_ny"];
            _next = [_nx, _ny, 0];
        } forEach _corrections;

        // Still a point it can fire on, and still clear of friendlies or ticked.
        private _range = [_logic, _next] call FUNC(inRange);
        if (_range isNotEqualTo "") exitWith {
            [_logic, format ["%1 - %2", PROMPT_ADJUST, toUpper _range], ANSWERS_ADJUST] call FUNC(threadPrompt);
        };
        private _check = createHashMapFromArray [
            ["target", _next],
            ["dangerClose", _order getOrDefault ["dangerClose", 0]],
            ["dcTick", _order getOrDefault ["dcTick", false]]
        ];
        ([_check, _logic getVariable [QGVAR(side), west]] call EFUNC(support,dangerClose)) params ["_safe", "_unsafeWhy"];
        if (!_safe) exitWith {
            [_logic, format ["%1 - %2", PROMPT_ADJUST, _unsafeWhy], ANSWERS_ADJUST] call FUNC(threadPrompt);
        };

        [_logic, ADJ_ROUND, _who, _next] call FUNC(threadFire);
    };

    case WORD_FFE: {
        private _call = [_thread, _message] call EFUNC(support,readOrder);
        [_logic, ADJ_FFE, _who, [], _call getOrDefault ["rounds", -1]] call FUNC(threadFire);
    };

    case WORD_REPEAT: {
        [_logic, _order getOrDefault ["call", ADJ_ROUND], _who] call FUNC(threadFire);
    };

    case WORD_CONFIRM: {
        if (_status isNotEqualTo STATUS_LAID) exitWith {};
        [_logic, _order getOrDefault ["call", ADJ_ROUND], _who] call FUNC(threadFire);
    };

    case WORD_BDA: {
        // A battery says what it has left and offers RECORD AS TARGET
        // (2026-11-02); a launcher asks plainly.
        if ((_logic getVariable [QGVAR(type), ""]) isNotEqualTo TYPE_ARTY) exitWith {
            [_logic, PROMPT_EOM, ANSWERS_EOM] call FUNC(threadPrompt);
        };
        [_logic, format [PROMPT_EOM_LEFT, [_logic] call FUNC(stockWords)], ANSWERS_EOM_ARTY] call FUNC(threadPrompt);
    };

    case WORD_RECORD: {
        // RECORD AS TARGET (user, 2026-11-02): the point named and marked,
        // then the question it had asked again, less RECORD.
        private _name = [_logic] call FUNC(record);
        (_logic getVariable [QGVAR(promptAsked), []]) params ["", ["_answers", ANSWERS_EOM_ARTY]];
        private _rest = ((_answers splitString ANSWER_SEP) - [WORD_RECORD]) joinString ANSWER_SEP;
        private _said = [format [PROMPT_RECORDED, _name], WHY_NO_RECORD] select (_name isEqualTo "");
        INFO_2("%1: record - %2",_callsign,_said);
        [_logic, _said, _rest] call FUNC(threadPrompt);
    };

    default {};
};
