#include "script_component.hpp"
/*
 * Author: YonV
 * The CC line, turned into mailbox ids.
 *
 * THE LINE IS NAMES, THE SEND IS IDS. The player types "@HQ, @REAPER, @SGT DOE"
 * because that is what those things are called on the rail and on the roster; the
 * engine addresses B:, G: and P: ids - see EFUNC(messaging,submit). The
 * conversion happens once, here, so the visible line stays readable and the
 * addressees stay correct.
 *
 * A NAME NOBODY ANSWERS TO IS DROPPED, not passed through. Submit treats an
 * unrecognised string as a shared mailbox name, so a typo would file the report
 * in a net that does not exist and nobody would ever see it - the CC would look
 * like it worked. An id typed or pasted in full is honoured as it stands.
 *
 * A SUPPORT ASSET'S CALL SIGN IS A NAME TOO (2026-11-01): one the @ mention did
 * not take off the line - "@HOG" last on it with a HOG 2 also listed - is its
 * box, "B:SUPPORT:<assetId>", when no net, squad or man has the name.
 *
 * Arguments:
 * 0: The CC line as typed <STRING>
 *
 * Return Value:
 * Mailbox ids <ARRAY> of <STRING>
 *
 * Example:
 * private _cc = [jmfsb_tacpad_composeCc] call jmfsb_tacpad_fnc_composeCcIds
 *
 * Public: Yes
 */

params [["_text", "", [""]]];

private _tokens = ((_text splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
if (_tokens isEqualTo []) exitWith {[]};

private _targets = [] call FUNC(composeTargets);
private _assets = ([false, ""] call FUNC(composeToSupport)) select 2;
private _ids = [];

{
    private _token = _x;

    // The @ is how the line offers completions; it is not part of the name.
    if ((_token select [0, 1]) isEqualTo "@") then {
        _token = trim (_token select [1]);
    };
    if (_token isEqualTo "") then {continue};

    if ((_token select [0, 2]) in ["B:", "G:", "P:"]) then {
        _ids pushBackUnique _token;
        continue;
    };

    private _up = toUpper _token;
    private _at = _targets findIf {(_x # 1) isEqualTo _up};
    if (_at < 0) then {
        private _asset = _assets findIf {toUpper (_x # 1) isEqualTo _up};
        if (_asset >= 0) then {_ids pushBackUnique ((_assets # _asset) # 0)};
        continue;
    };

    _ids pushBackUnique ((_targets # _at) # 0);
} forEach _tokens;

_ids
