#include "script_component.hpp"
/*
 * Author: YonV
 * The rows of the TO picker's SUPPORT group: the support assets this player
 * may address, each with its state and its ETA to him (user, 2026-11-01:
 * "make the cas units selectable as message receivers";
 * docs/DESIGN_SUPPORT_MESSAGING.md sections 3 and 6.1).
 *
 * THE SUPPORT CORE ANSWERS, THIS ONLY ASKS. Which assets, of which types, in
 * which state and how far out is EFUNC(support,mailboxes); this addon does
 * not require the support addon, so it is asked only when it is loaded.
 *
 * ASKED WHEN THE PICKER OPENS AND ON ITS POLL, NEVER PER FRAME. Rows asked
 * less than TO_SUPPORT_POLL seconds ago for the same card are handed back as
 * they are - a reader redraw on arriving traffic does not ask again. The
 * tasking gate (decision D3: the Support tasking tag,
 * EFUNC(support,canTask)) is asked once per opening: the CHANGE press clears
 * GVAR(toSupport), and the gate's answer is kept until it does again.
 *
 * THE ETA IS TO WHERE HIS GPS SAYS HE IS (decision D2), as CURRENT LOC reads
 * it (EFUNC(ew,gpsHere), quiet - this is polled): no fix, no ETA.
 *
 * THE @ LIST ASKS FOR EVERY TYPE (2026-11-01): the CC line's @ mentions pass
 * card "" (FUNC(composeCcDrop)), so a `cas` card being written does not hide
 * the batteries from it. The rows are kept per card, as before.
 *
 * Arguments:
 * 0: Ask again even when the rows are fresh - the poll <BOOL> (optional, default false)
 * 1: The card the rows are for, "" for every type <STRING> (optional, default the card being written)
 *
 * Return Value:
 * 0: He may task support - the group is drawn <BOOL>
 * 1: The card being written goes to support - the group comes first, narrowed to its types <BOOL>
 * 2: Rows, as EFUNC(support,mailboxes) gives them <ARRAY>
 *
 * Example:
 * ([] call jmfsb_tacpad_fnc_composeToSupport) params ["_show", "_forCard", "_rows"]
 *
 * Public: No
 */

params [["_force", false, [false]], ["_for", GVAR(composeTemplate), [""]]];

if (isNil QEFUNC(support,mailboxes)) exitWith {[false, false, []]};

GVAR(toSupport) params [["_askedAt", -1, [0]], ["_card", "", [""]], ["_show", false, [false]], ["_forCard", false, [false]], ["_rows", [], [[]]]];

private _fresh = _askedAt >= 0 && diag_tickTime < _askedAt + TO_SUPPORT_POLL && _card isEqualTo _for;
if (!_force && _fresh) exitWith {[_show, _forCard, +_rows]};

if (_askedAt < 0) then {
    _show = ([player] call EFUNC(support,canTask)) select 0;
};

_forCard = false;
_rows = [];
if (_show) then {
    private _here = if (isNil QEFUNC(ew,gpsHere)) then {getPosATL player} else {[] call EFUNC(ew,gpsHere)};
    ([_here, _for] call EFUNC(support,mailboxes)) params [["_matched", false, [false]], ["_found", [], [[]]]];
    _forCard = _matched;
    _rows = _found;
};

GVAR(toSupport) = [diag_tickTime, _for, _show, _forCard, _rows];
[_show, _forCard, +_rows]
