#include "script_component.hpp"
/*
 * Author: JMSB
 * What the walking view's call strip (over the map's bottom left) says about
 * calls, when it has something to say (docs/DESIGN_VOICE.md, the phone and side images):
 *
 *   quick add   ADD < NAME > 2/5 - F1 add - 0 / . move - F4 close
 *   ringing     CALL from NOMAD 2-1 - F1 accept - F4 decline
 *   in a call   CALL 02:14 - NOMAD 2-1, S3 - F4 hang up
 *   dialling    CALL dialling NOMAD 2-1 - F4 hang up
 *   callback    CALLBACK pending - NOMAD 2-1 - rings when in reach
 *   last word   CALL no route - CALL BACK is available (a failure reason, the
 *               priority warning or the end, off jmfsb_voice_callState, held
 *               CALL_STATE_HOLD seconds; the warning outranks a live call)
 *
 * Otherwise "" and the strip is hidden. The F-keys named are the device keys
 * (Ctrl + numpad 1-4 by default).
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

if (GVAR(quickOpen)) exitWith {
    private _offer = [(_live param [0, []]) param [2, []]] call EFUNC(tacpad_apps,radioQuick);
    if (_offer isEqualTo []) exitWith {
        ["ADD", HTML_OK, format ["nobody in reach to add %1 F4 close", MIDDOT]] call _fnc_line
    };
    GVAR(quickCursor) = (GVAR(quickCursor) max 0) min (count _offer - 1);
    [
        "ADD", HTML_OK,
        format [
            "&lt; %1 &gt; %2/%3 %4 F1 add %4 0 / . move %4 F4 close",
            [[_offer select GVAR(quickCursor)]] call _fnc_names,
            GVAR(quickCursor) + 1, count _offer, MIDDOT
        ]
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
    ["CALL", HTML_TX, format ["from %1 %2 F1 accept %2 F4 decline", [(_ring select 0) param [2, []]] call _fnc_names, MIDDOT]] call _fnc_line
};

if (_live isNotEqualTo []) exitWith {
    (_live select 0) params ["", "_state", ["_members", [], [[]]], "", ["_startedAt", CBA_missionTime, [0]]];
    if (_state isEqualTo CALL_OUTGOING) exitWith {
        ["CALL", HTML_OK, format ["dialling %1 %2 F4 hang up", [_members] call _fnc_names, MIDDOT]] call _fnc_line
    };
    private _s = floor ((CBA_missionTime - _startedAt) max 0);
    [
        "CALL", HTML_OK,
        format [
            "%1:%2 %3 %4 %3 F2 add %3 F4 hang up",
            [floor (_s / SECONDS_PER_MINUTE), 2] call CBA_fnc_formatNumber,
            [_s mod SECONDS_PER_MINUTE, 2] call CBA_fnc_formatNumber,
            MIDDOT, [_members] call _fnc_names
        ]
    ] call _fnc_line
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
