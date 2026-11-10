#include "script_component.hpp"
/*
 * Author: YonV
 * Client: keeps a support thread's card for its map pin (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 6.3, build step 8). The card is one of PIN_CARDS
 * (cas, onstation, callforfire, cffpolar, cffshift, hlz, extract, casevac,
 * airdrop, resupply, qrf); filed to an asset's box (B:SUPPORT:<assetId>) it names the asset whose
 * overlay draws while at work, else it is drawn alone (a card to a player
 * crew). The card is read into an order once, here, by the core's own
 * reader (FUNC(readOrder) - it reads only the card and the deck, so it answers
 * on a client too; the LZ security it asks the server for is "" here and is not
 * drawn), so a polar call for fire stays where it was called, not where the
 * observer has walked since.
 *
 * WHO HOLDS ONE: a man the card was pushed to with its body (messaging's
 * onReceive - the people the plain pin marks too), or a man who opened the
 * thread (messaging's cache, read by FUNC(pinTick)). A newer support card in
 * the thread (a NEXT LIFT, a new strike) replaces the one held.
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: The card's message <HASHMAP>
 * 2: The thread's boxes, or the index row's one <ARRAY of STRINGs>
 *
 * Return Value:
 * Held <BOOL>
 *
 * Example:
 * ["T0042", _root, ["B:SUPPORT:cas:0"]] call jmfsb_support_fnc_pinRoot
 *
 * Public: No
 */

params [["_threadId", "", [""]], ["_message", createHashMap, [createHashMap]], ["_boxes", [], [[]]]];

if (_threadId isEqualTo "" || count _message isEqualTo 0) exitWith {false};

private _card = _message getOrDefault ["templateId", ""];
private _head = count SUPPORT_BOX_PREFIX;
private _at = _boxes findIf {_x isEqualType "" && {(toUpper (_x select [0, _head])) isEqualTo SUPPORT_BOX_PREFIX}};
private _assetId = "";
if (_at >= 0) then {_assetId = (_boxes select _at) select [_head]};

// Only a support card is held: a reply, a prompt or a plain message in the
// thread leaves the card held as it is.
private _held = GVAR(pinRoots) getOrDefault [_threadId, []];
if !(_card in PIN_CARDS) exitWith {_held isNotEqualTo []};

// The asset a thread was already known by is kept when this row names none.
if (_assetId isEqualTo "") then {_assetId = _held param [1, ""]};

private _thread = createHashMapFromArray [
    ["rootTemplateId", _card],
    ["issuerUid", _message getOrDefault ["fromUid", ""]]
];
GVAR(pinRoots) set [_threadId, [[_thread, _message] call FUNC(readOrder), _assetId]];

true
