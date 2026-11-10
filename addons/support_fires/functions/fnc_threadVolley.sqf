#include "script_component.hpp"
/*
 * Author: YonV
 * Server: SHOT and SPLASH for one volley in the thread a call for fire tasked
 * the battery with (2026-11-01, DESIGN_SUPPORT_MESSAGING step 6), called by
 * FUNC(fireVirtual) beside its rail calls - nothing when the battery fires
 * for no thread (the board, a coordinated partner).
 *
 *   SHOT     when the volley leaves, with its time of flight ("TOF 32"); a
 *            mission of several volleys numbers it, "VOLLEY 2 OF 3 - TOF 32"
 *            (2026-11-05: volleys follow on the gun's rhythm, so this SHOT
 *            can come before the volley before has splashed - as Simplex
 *            notifies each loop - and the number says which is which)
 *   SPLASH   SPLASH_LEAD s before it lands (doctrinal: 5 s), "VOLLEY 2 OF 3"
 *            when numbered
 *   each with a short cue on the caller's machine (FUNC(cue), 2026-11-02)
 *   then, after the last volley's splash, the battery's prompt (doc 5.4,
 *   FUNC(threadPrompt)):
 *     an adjusting round       ADJUST?                          adjust, ffe, close
 *     fire for effect          ROUNDS COMPLETE - <left> - REQUEST BDA
 *                                                     bda, record, repeat, close
 *     the same, unobserved     ROUNDS COMPLETE - <left> - END OF MISSION?
 *                                                     close, record, repeat
 *   <left> is what the battery still holds, "12 HE, 6 SMOKE LEFT"
 *   (FUNC(stockWords)); RECORD AS TARGET is the observer's `record` (user,
 *   2026-11-02).
 *
 * A mission that moved on (check fire, a new call, the end) files nothing
 * more for it: each card checks the mission's token and the thread.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The mission's token <NUMBER>
 * 2: The call, ADJ_* <NUMBER>
 * 3: When the volley is shot, s from now <NUMBER>
 * 4: Time of flight (s) <NUMBER>
 * 5: It is the salvo's last volley <BOOL>
 * 6: How long the volley fires, first round to last (s) - the prompt comes
 *    SPLASH_LEAD s before its last round lands, so a long volley (a CONTINUOUS
 *    FIRE, 2026-11-02) is complete when it says so <NUMBER> (optional, default 0)
 * 7: The volley's number in the salvo, from 1 <NUMBER> (optional, default 1)
 * 8: Volleys in the salvo - over 1, SHOT and SPLASH are numbered <NUMBER> (optional, default 1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, 3, 1, 12, 32, true, 24, 1, 1] call jmfsb_support_fires_fnc_threadVolley
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_token", -1, [0]], ["_call", ADJ_NONE, [0]], ["_start", 0, [0]], ["_eta", 0, [0]], ["_last", true, [true]], ["_length", 0, [0]], ["_volley", 1, [0]], ["_volleys", 1, [0]]];

if (!isServer || {isNull _logic}) exitWith {};
private _threadId = _logic getVariable [QGVAR(thread), ""];
if (_threadId isEqualTo "") exitWith {};

private _numbered = _volleys > 1;
private _shotText = [format [CARD_TOF, round _eta], format [CARD_TOF_VOLLEY, _volley, _volleys, round _eta]] select _numbered;
private _splashPayload = [[], [[CARD_TEXT_KEY, format [CARD_VOLLEY, _volley, _volleys]]]] select _numbered;

[{
    params ["_logic", "_token", "_threadId", "_shotText"];
    if (isNull _logic) exitWith {};
    if ((_logic getVariable [QGVAR(token), -1]) isNotEqualTo _token) exitWith {};
    if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};
    [_logic, CARD_SHOT, [[CARD_TEXT_KEY, _shotText]]] call FUNC(threadCard);
    [_logic, CARD_SHOT] call FUNC(cue);
}, [_logic, _token, _threadId, _shotText], 0 max _start] call CBA_fnc_waitAndExecute;

[{
    params ["_logic", "_token", "_threadId", "_splashPayload"];
    if (isNull _logic) exitWith {};
    if ((_logic getVariable [QGVAR(token), -1]) isNotEqualTo _token) exitWith {};
    if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};
    [_logic, CARD_SPLASH, _splashPayload] call FUNC(threadCard);
    [_logic, CARD_SPLASH] call FUNC(cue);
}, [_logic, _token, _threadId, _splashPayload], _start max (_start + _eta - SPLASH_LEAD)] call CBA_fnc_waitAndExecute;

if (!_last) exitWith {};

// THE PROMPT, as the last round of the volley comes down (2026-11-02: a
// continuous fire is minutes long). What is left in the words, RECORD AS
// TARGET among the answers (user, 2026-11-02).
[{
    params ["_logic", "_token", "_threadId", "_call"];
    if (isNull _logic) exitWith {};
    if ((_logic getVariable [QGVAR(token), -1]) isNotEqualTo _token) exitWith {};
    if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};
    private _observed = (_logic getVariable [QGVAR(threadOrder), createHashMap]) getOrDefault ["observed", true];
    // ROUNDS COMPLETE (2026-11-09): the card, what is left as its text, then
    // the question - an adjusting round is not the mission's end.
    if (_call isNotEqualTo ADJ_ROUND) then {
        private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
        [_assetId, _threadId, CARD_ROUNDS_COMPLETE, [[CARD_TEXT_KEY, [_logic] call FUNC(stockWords)]], _logic getVariable [QGVAR(callsign), ""]] call EFUNC(support,fileCard);
    };
    switch (true) do {
        case (_call isEqualTo ADJ_ROUND): {[_logic, PROMPT_ADJUST, ANSWERS_ADJUST] call FUNC(threadPrompt)};
        case (_observed): {[_logic, format [PROMPT_COMPLETE_LEFT, [_logic] call FUNC(stockWords)], ANSWERS_COMPLETE_ARTY] call FUNC(threadPrompt)};
        default {[_logic, format [PROMPT_UNOBSERVED_LEFT, [_logic] call FUNC(stockWords)], ANSWERS_EOM_ARTY] call FUNC(threadPrompt)};
    };
}, [_logic, _token, _threadId, _call], (_start max (_start + _eta - SPLASH_LEAD)) + (_length max PROMPT_LAG)] call CBA_fnc_waitAndExecute;
