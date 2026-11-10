#include "script_component.hpp"
/*
 * Author: YonV
 * Puts the composer on the card an @ mention asks for, keeping what was typed
 * (user, 2026-11-01: "need to have the proper template also for the type of
 * unit").
 *
 * NOTHING TYPED IS LOST WITHOUT ASKING. Every filled field of the card being
 * written (the plain message's one box when there is none) is looked at:
 *
 *   the new card has the line, of the same type   it stays - line titles are
 *                                                  field keys, so it is there
 *   a text value the new card has no line for     the first one moves into the
 *                                                  new card's empty REMARKS line
 *   anything else                                 it would be lost: without
 *                                                  the player's yes (argument 1)
 *                                                  nothing changes and the count
 *                                                  is handed back to ask him
 *
 * A same-named line of another type (a `cas` grid on Line 1, REQUEST ON
 * STATION's minutes on Line 1) is not carried: it is cleared on the yes, so the
 * new card does not open with a grid in a minutes box. Values the new card has
 * no line for at all stay in the answer map, where CHANGE TEMPLATE back to the
 * old card finds them.
 *
 * Harvest first: this reads the answer map, not the edits.
 *
 * Arguments:
 * 0: The card id <STRING>
 * 1: Switch even when typed values would be lost - the player said yes <BOOL> (optional, default false)
 *
 * Return Value:
 * 0: Switched <BOOL>
 * 1: Typed values the new card does not keep <NUMBER>
 *
 * Example:
 * ([_card, false] call jmfsb_tacpad_fnc_composeMentionSwitch) params ["_switched", "_lost"]
 *
 * Public: No
 */

params [["_card", "", [""]], ["_confirmed", false, [false]]];

private _to = [_card] call EFUNC(messaging,template);
if (_card isEqualTo "" || count _to isEqualTo 0) exitWith {[false, 0]};
if (_card isEqualTo GVAR(composeTemplate)) exitWith {[true, 0]};

private _fromId = [GVAR(composeTemplate), "freetext"] select (GVAR(composeTemplate) isEqualTo "");
private _from = [_fromId] call EFUNC(messaging,template);
private _fromFields = _from getOrDefault ["fields", createHashMap];
private _toFields = _to getOrDefault ["fields", createHashMap];

private _fnc_filled = {
    private _v = GVAR(composeValues) getOrDefault [_this, ""];
    !(_v isEqualTo "" || _v isEqualTo false || _v isEqualTo [])
};

// The new card's REMARKS line, while it is empty.
private _toOrder = _to getOrDefault ["order", []];
private _remarksAt = _toOrder findIf {
    private _title = toUpper ((_x splitString ".") param [0, ""]);
    private _type = (_toFields getOrDefault [_x, createHashMap]) getOrDefault ["type", "text"];
    _title isEqualTo MENTION_NOTE_LINE && _type in MENTION_TEXT_TYPES && !(_x call _fnc_filled)
};
private _remarks = "";
if (_remarksAt >= 0) then {_remarks = _toOrder select _remarksAt};

private _move = [];
private _lost = [];
{
    private _key = _x;
    if !(_key call _fnc_filled) then {continue};

    private _type = (_fromFields getOrDefault [_key, createHashMap]) getOrDefault ["type", "text"];
    private _there = _toFields getOrDefault [_key, createHashMap];
    if (count _there > 0 && (_there getOrDefault ["type", "text"]) isEqualTo _type) then {continue};

    if (_move isEqualTo [] && _remarks isNotEqualTo "" && _type in MENTION_TEXT_TYPES) then {
        _move = [_key, _remarks];
        continue;
    };
    _lost pushBack _key;
} forEach (_from getOrDefault ["order", []]);

if (_lost isNotEqualTo [] && !_confirmed) exitWith {[false, count _lost]};

if (_move isNotEqualTo []) then {
    _move params ["_old", "_new"];
    GVAR(composeValues) set [_new, GVAR(composeValues) get _old];
    GVAR(composeValues) deleteAt _old;
    GVAR(composeGridText) deleteAt _old;
};

// A line of the same name and another type would open holding the wrong thing.
{
    if (_x in _toFields) then {
        GVAR(composeValues) deleteAt _x;
        GVAR(composeGridText) deleteAt _x;
    };
} forEach _lost;

GVAR(composeTemplate) = _card;
GVAR(composeFrago) = [];
GVAR(composeShortOn) = [] call FUNC(composeShortDefault);
GVAR(composePick) = false;
GVAR(composeMarker) = "";
GVAR(composePinPick) = false;
GVAR(composeMissing) = [];
GVAR(composeMentionAsk) = [];

[true, count _lost]
