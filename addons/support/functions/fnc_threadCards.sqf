#include "script_component.hpp"
/*
 * Author: YonV
 * The ROOT cards an asset takes as a new task inside its own open thread
 * (2026-11-02): a new CAS REQUEST answering FURTHER TASKING?, a new LIFT
 * REQUEST answering HOLD, RTB OR NEXT LIFT?. Read off the provider's
 * "threadCards" declaration (THREAD_CARDS_KEY) for the card the thread was
 * opened with - the same answer on the server, which takes the card into the
 * thread (FUNC(srvThreadCard)), and on the client, whose reader offers it
 * there (jmfsb_tacpad_fnc_threadLegal). Providers register on every machine.
 *
 * A player crew's box (P:) and a box no provider answers take none: nobody
 * there re-tasks on a card. Only cards the deck has are given.
 *
 * Arguments:
 * 0: The asset - its box "B:SUPPORT:<assetId>" or the asset id <STRING>
 * 1: The thread's root card id <STRING>
 *
 * Return Value:
 * Card ids <ARRAY of STRINGs>
 *
 * Example:
 * ["B:SUPPORT:air:0", "cas"] call jmfsb_support_fnc_threadCards
 *
 * Public: Yes
 */

params [["_asset", "", [""]], ["_rootId", "", [""]]];

if (_asset isEqualTo "" || _rootId isEqualTo "") exitWith {[]};

private _head = count SUPPORT_BOX_PREFIX;
if ((toUpper (_asset select [0, _head])) isEqualTo SUPPORT_BOX_PREFIX) then {
    _asset = _asset select [_head];
};

([_asset] call FUNC(provider)) params ["_kind", "_decl"];
if (_kind isEqualTo "") exitWith {[]};

private _pairs = _decl getOrDefault [THREAD_CARDS_KEY, []];
if !(_pairs isEqualType []) exitWith {[]};
private _at = _pairs findIf {_x isEqualType [] && {(_x param [0, ""]) isEqualTo _rootId}};
if (_at < 0) exitWith {[]};

private _cards = (_pairs select _at) param [1, [], [[]]];
_cards select {_x isEqualType "" && {([_x] call EFUNC(messaging,template)) isNotEqualTo createHashMap}}
