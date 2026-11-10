#include "script_component.hpp"
/*
 * Author: YonV
 * The support assets named in full on the CC line - "@HOG" typed rather than
 * picked from the @ list (user, 2026-11-01: "want to use an @[unit] to
 * enable ai support units").
 *
 * A NAME IS TAKEN WHEN IT IS FINISHED: followed by a comma, or the last one on
 * the line and nothing else either list offers begins with it - "@HOG" with a
 * HOG 2 on the list waits for the comma. A net, squad or man of the same name
 * wins, as it does at the send (FUNC(composeCcIds)): it stays a CC.
 *
 * Every asset taken comes off the line - it goes on the TO line instead
 * (FUNC(composeMention)) - and the rest of the line is handed back as it
 * stands, the name still being typed without a separator after it.
 *
 * Arguments:
 * 0: The CC line <STRING>
 * 1: Asset rows, as FUNC(composeToSupport) gives them <ARRAY>
 * 2: Targets, as FUNC(composeTargets) gives them <ARRAY>
 *
 * Return Value:
 * [asset rows taken, the CC line without them], or [] when none was <ARRAY>
 *
 * Example:
 * private _typed = [ctrlText _cc, _rows, _targets] call jmfsb_tacpad_fnc_composeMentionTyped
 *
 * Public: No
 */

params [["_text", "", [""]], ["_rows", [], [[]]], ["_targets", [], [[]]]];

if (_rows isEqualTo []) exitWith {[]};

private _trimmed = trim _text;
if (_trimmed isEqualTo "") exitWith {[]};

// The line ends on a comma: every name on it is finished.
private _closed = (_trimmed select [(count _trimmed) - 1]) isEqualTo ",";
private _tokens = (_text splitString ",") apply {trim _x};
private _lastAt = (count _tokens) - 1;

private _names = _rows apply {toUpper (_x select 1)};
private _labels = _targets apply {_x select 1};

private _taken = [];
private _kept = [];
private _openKept = false;
{
    private _token = _x;
    private _open = !_closed && _forEachIndex isEqualTo _lastAt;
    private _at = -1;

    if ((_token select [0, 1]) isEqualTo "@") then {
        private _name = toUpper (trim (_token select [1]));
        _at = _names find _name;
        if (_name in _labels) then {_at = -1};

        // Still being typed: only when it is the one name left that fits.
        if (_at >= 0 && _open) then {
            private _n = count _name;
            private _fits = ({(_x select [0, _n]) isEqualTo _name} count _names) + ({(_x select [0, _n]) isEqualTo _name} count _labels);
            if (_fits > 1) then {_at = -1};
        };
    };

    if (_at >= 0) then {
        _taken pushBack (_rows select _at);
        continue;
    };
    if (_token isEqualTo "") then {continue};

    _kept pushBack _token;
    _openKept = _open;
} forEach _tokens;

if (_taken isEqualTo []) exitWith {[]};

private _cc = _kept joinString ", ";
if (_kept isNotEqualTo [] && !_openKept) then {_cc = _cc + ", "};

[_taken, _cc]
