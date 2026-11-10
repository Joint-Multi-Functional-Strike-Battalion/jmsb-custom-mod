#include "script_component.hpp"
/*
 * Author: YonV
 * SEND SITREP from a TIC thread (user, 2026-11-02: "after contact a sitrep
 * should be sent"): the composer on the deck's SITREP card, filed INTO the TIC
 * thread, one press from the thread's row (FUNC(readerQuickTiles)) - the tile
 * the TIC's sender and his squad leader see, and the CONTACT OVER? line the
 * sender gets when the contact has gone quiet (FUNC(contactCheck)).
 *
 * WHAT IS ALREADY FILLED. LOCATION is the thread's own point - the TIC's grid
 * (FUNC(autoAnchor)) - or, where the thread has none, where his GPS says he is
 * (jmfsb_ew_fnc_gpsHere when EW is loaded). It goes in as an answer handed in,
 * shown as its grid and typed over like CUR LOC. STATUS AMMO and CAS are the
 * card's own autofills (squadAce:A / squadAce:C, FUNC(autoSquadAce)): the
 * worst of the squad's ACE letters, applied before every draw of the card.
 *
 * A SITREP THAT IS STILL A ROOT CARD (the mod's built-in one is "both" and
 * always wins; a SITREP from elsewhere might not be) cannot
 * file it in a thread - the reader offers only reply cards there. Then it
 * opens a NEW SITREP thread on the TIC's net, its location the TIC's, its
 * REMARKS naming the TIC's grid and thread, and the line beside SEND says so.
 * The subject is the server's, from the card (`SITREP <grid>`): the same grid
 * as the TIC's.
 *
 * Arguments:
 * 0: The TIC thread <STRING>
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * ["T0004"] call jmfsb_tacpad_fnc_sitrepAfterTic
 *
 * Public: No
 */

params [["_threadId", "", [""]]];

if (_threadId isEqualTo "") exitWith {false};
if (isNil QEFUNC(messaging,template)) exitWith {false};

private _template = [SITREP_CARD] call EFUNC(messaging,template);
if (_template isEqualTo createHashMap) exitWith {
    ["SITREP", SITREP_NO_CARD, "high"] call EFUNC(messaging,notify);
    false
};

private _rows = missionNamespace getVariable [QEGVAR(messaging,index), []];
private _rowAt = _rows findIf {
    _x isEqualType createHashMap && {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId}
};
private _row = createHashMap;
if (_rowAt >= 0) then {_row = _rows select _rowAt};

// Where: the TIC's point, else where his GPS puts him.
private _at = [_threadId] call FUNC(autoAnchor);
if (_at isEqualTo []) then {
    _at = if (isNil QEFUNC(ew,gpsHere)) then {getPosATL player} else {[] call EFUNC(ew,gpsHere)};
};

private _values = [];
private _locKey = ([SITREP_CARD, SITREP_LOCATION_LINE] call EFUNC(messaging,fieldKeys)) param [0, ""];
if (_locKey isNotEqualTo "" && _at isNotEqualTo []) then {
    _values pushBack [_locKey, _at];
};

// INTO THE THREAD where the deck lets it: a SITREP of kind "both" that the
// thread's state takes now - the reader's own rule (FUNC(readerThreadView)).
private _legal = ["reply", _row getOrDefault ["status", ""]] call EFUNC(messaging,templateIds);
if (SITREP_CARD in _legal) exitWith {
    [_threadId, SITREP_CARD, false, "", _values] call FUNC(composeOpen)
};

// A ROOT SITREP: its own thread, on the TIC's net, the TIC named in REMARKS.
private _grid = "";
if (_at isNotEqualTo []) then {_grid = mapGridPosition _at};
private _remarksKey = ([SITREP_CARD, SITREP_REMARKS_LINE] call EFUNC(messaging,fieldKeys)) param [0, ""];
if (_remarksKey isNotEqualTo "") then {
    _values pushBack [_remarksKey, format [SITREP_AFTER_TIC, _grid, _threadId]];
};

private _opened = ["", SITREP_CARD, false, _row getOrDefault ["boxId", ""], _values] call FUNC(composeOpen);
if (_opened) then {GVAR(composeNote) = SITREP_OWN_THREAD};

_opened
