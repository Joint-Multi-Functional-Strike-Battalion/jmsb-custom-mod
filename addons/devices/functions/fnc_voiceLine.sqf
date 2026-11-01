#include "script_component.hpp"
/*
 * Author: JMSB
 * What the walking view's call strip (over the map's bottom left) says about
 * calls, when it has something to say (docs/DESIGN_VOICE.md, the phone and side images):
 *
 *   quick add   ADD < NAME > 2/5 - NUM * add - 0 / . move
 *   ringing     CALL from NOMAD 2-1 - NUM * answer - NUM / decline
 *   dialling    CALL dialling NOMAD 2-1 - NUM * hang up
 *   (each key as bound; an unbound one is left out)
 *   callback    CALLBACK pending - NOMAD 2-1 - rings when in reach
 *   last word   CALL no route - CALL BACK is available (a failure reason, the
 *               priority warning or the end, off jmfsb_voice_callState, held
 *               CALL_STATE_HOLD seconds; the warning outranks a live call)
 *
 * A LIVE CALL IS QUIET HERE (notes, 2026-10-30: the strip only while a key
 * press is wanted): its clock is the talking box's (FUNC(overlayTalker)).
 * Otherwise "" and the strip is hidden. The keys named are as bound (the
 * device keys numpad 6-9, answer * and decline / by default).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Structured text, "" when there is no call business <STRING>
 *
 * Example:
 * private _line = [] call jmfsb_devices_fnc_voiceLine
 *
 * Public: No
 */

if (isNil QEFUNC(voice,calls)) exitWith {""};

private _me = call CBA_fnc_currentUnit;
private _fnc_names = {
    params ["_units"];
    [toUpper (((_units select {!isNull _x && _x isNotEqualTo _me}) apply {name _x}) joinString ", ")] call EFUNC(tacpad,xmlSafe)
};
private _fnc_line = {
    params ["_word", "_colour", "_rest"];
    format ["<t font='RobotoCondensedBold' color='%1'>%2</t> <t color='%3'>%4</t>", _colour, _word, HTML_TEXT, _rest]
};

private _calls = [] call EFUNC(voice,calls);
private _live = _calls select {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};

// The call keys as he has them bound (the numpad standard, user 2026-10-25:
// answer / hang up / add numpad *; decline and F1 have no default key). A key
// he has not bound is left out of the line rather than shown as UNBOUND.
private _fnc_hint = {
    params ["_action", "_word"];
    private _key = [_action] call FUNC(keyLabel);
    if (_key in [KEY_LABEL_UNBOUND, KEY_LABEL_NONE]) exitWith {""};
    format [" %1 %2 %3", MIDDOT, _key, _word]
};
private _hintAnswer = [QGVAR(answerKey), "answer"] call _fnc_hint;
private _hintHang = [QGVAR(answerKey), "hang up"] call _fnc_hint;

if (GVAR(quickOpen)) exitWith {
    private _offer = [(_live param [0, []]) param [2, []]] call EFUNC(tacpad_apps,radioQuick);
    private _close = [QGVAR(button_F1), "close"] call _fnc_hint;
    if (_offer isEqualTo []) exitWith {
        ["ADD", HTML_OK, "nobody in reach to add" + _close] call _fnc_line
    };
    GVAR(quickCursor) = (GVAR(quickCursor) max 0) min (count _offer - 1);
    [
        "ADD", HTML_OK,
        format [
            "&lt; %1 &gt; %2/%3",
            [[_offer select GVAR(quickCursor)]] call _fnc_names,
            GVAR(quickCursor) + 1, count _offer
        ] + ([QGVAR(answerKey), "add"] call _fnc_hint) + format [" %1 0 / . move", MIDDOT] + _close
    ] call _fnc_line
};

GVAR(callLast) params [["_lastState", "", [""]], ["_lastAt", -1, [0]]];
private _lastWord = "";
if (CBA_missionTime - _lastAt < CALL_STATE_HOLD) then {
    _lastWord = (createHashMapFromArray CALL_STATE_WORDS) getOrDefault [_lastState, ""];
};
if (_lastState isEqualTo CALL_WARNING && _lastWord isNotEqualTo "") exitWith {
    ["CALL", HTML_TX, _lastWord] call _fnc_line
};

private _ring = _calls select {(_x param [1, ""]) isEqualTo CALL_RINGING};
if (_ring isNotEqualTo []) exitWith {
    [
        "CALL", HTML_TX,
        format ["from %1", [(_ring select 0) param [2, []]] call _fnc_names]
            + _hintAnswer + ([QGVAR(declineKey), "decline"] call _fnc_hint)
    ] call _fnc_line
};

if (_live isNotEqualTo []) exitWith {
    (_live select 0) params ["", "_state", ["_members", [], [[]]]];
    // Dialling still wants a key (hang up); a live call's clock is the
    // talking box's and the strip stays quiet.
    if (_state isNotEqualTo CALL_OUTGOING) exitWith {""};
    ["CALL", HTML_OK, format ["dialling %1", [_members] call _fnc_names] + _hintHang] call _fnc_line
};

if (_lastWord isNotEqualTo "") exitWith {
    ["CALL", HTML_TX, _lastWord] call _fnc_line
};

private _callbacks = if (isNil QEFUNC(voice,callbacks)) then {[]} else {[] call EFUNC(voice,callbacks)};
if (_callbacks isNotEqualTo []) exitWith {
    (_callbacks select 0) params [["_from", objNull, [objNull]], ["_to", objNull, [objNull]]];
    private _other = [_from, _to] select (_from isEqualTo _me);
    ["CALLBACK", HTML_TX, format ["pending %1 %2 %1 rings when in reach", MIDDOT, [[_other]] call _fnc_names]] call _fnc_line
};

""
