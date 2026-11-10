#include "script_component.hpp"
/*
 * Author: YonV
 * One item of a delivery accounted for - delivered, or not and why - and,
 * once every item ordered is, the delivery said and the asset's thread
 * CLOSED with it (2026-11-01):
 *
 *   "delivered 2 x HUNTER, 1 x CRATE - MAGAZINES at 045 782"
 *   "delivered 1 of 3 (1 x HUNTER) at 045 782 - aircraft lost at 046 779"
 *   "nothing delivered - recalled"
 *
 * The thread closes on the items, not on the aircraft: the section has its
 * answer when the last load is down, while the aircraft are still leaving.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The sortie <HASHMAP>
 * 2: The item's name <STRING>
 * 3: Delivered <BOOL>
 * 4: Why not, when it was not <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _sortie, "HUNTER", true] call jmfsb_support_logistics_fnc_account
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_sortie", createHashMap, [createHashMap]], ["_name", "", [""]], ["_ok", false, [false]], ["_why", "", [""]]];

if (isNull _logic || {_sortie getOrDefault ["closed", true]}) exitWith {};

private _got = _sortie get "delivered";
private _lost = _sortie get "failed";
if (_ok) then {_got pushBack _name} else {
    _lost pushBack _name;
    if (_why isNotEqualTo "") then {_sortie set ["why", _why]};
};

private _total = _sortie get "total";
if (count _got + count _lost < _total) exitWith {};
_sortie set ["closed", true];

private _grid = mapGridPosition (_sortie get "pos");
private _what = [_got] call FUNC(countLine);
private _line = switch (true) do {
    case (_got isEqualTo []): {format ["nothing delivered - %1", _sortie get "why"]};
    case (_lost isEqualTo []): {format ["delivered %1 at %2", _what, _grid]};
    default {format ["delivered %1 of %2 (%3) at %4 - %5", count _got, _total, _what, _grid, _sortie get "why"]};
};

[_logic, _line, "high", _sortie get "requester", _got isNotEqualTo []] call FUNC(say);

// A DELIVERY TASKED BY MESSAGE (step 7, 2026-11-01) asks for the receipt
// before it closes - PACKAGE AWAY - CONFIRM RECEIPT (FUNC(threadReply)), D9
// too (FUNC(threadTimeout)). Nothing delivered, or stood down: closed now.
private _job = _logic getVariable [QGVAR(threadJob), createHashMap];
if (_got isNotEqualTo [] && (_job getOrDefault ["step", ""]) isEqualTo JOB_FLYING) exitWith {
    _job set ["step", JOB_RECEIPT];
    _job set ["line", toUpper _line];
    _job set ["items", +(_sortie getOrDefault ["items", []])];
    [
        format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
        _job get "thread",
        PROMPT_RECEIPT,
        ANSWERS_RECEIPT,
        _logic getVariable [QGVAR(callsign), DEF_CALLSIGN],
        {_this call FUNC(threadTimeout)}
    ] call EFUNC(support,prompt);
};
[_logic, "CLOSED", _line] call FUNC(threadState);
_logic setVariable [QGVAR(threadJob), nil];
