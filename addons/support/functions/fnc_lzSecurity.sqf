#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the LZ security the asset's request card gives - the `hlz` card's
 * Line 4 (GREEN / YELLOW / RED), or any card's line that is labelled SECURITY
 * and ticked the same way (the casevac's). It decides a helicopter's drone
 * escorts (DESIGN_SUPPORT_MESSAGING 1.2, user, 2026-11-01: "for helos based on
 * security") and, RED, a hot LZ (step 7, 5.3: the helicopter waits for the
 * issuer's CONFIRM).
 *
 * WHICH CARD: the message given (step 7, 2026-11-01: the card reader,
 * FUNC(readOrder), asks for the card it reads), else the root of the asset's
 * open thread - the one a JTAC filed to its box in TAC//MSG. Read off
 * the messaging store on the server, by the field's own word and its line's
 * label, never by a fixed key: the deck is mission / PAC data.
 *
 * THE 9-LINE CASEVAC'S N / P / E / X (2026-11-09, ticks; or a mission deck's
 * security choice): N reads GREEN, P YELLOW, E and X RED (LZ_SECURITY_CHOICES,
 * by the tick's letter or the choice's first letter) - X, armed escort
 * required, is escorted as RED is.
 *
 * Arguments:
 * 0: The asset id, "" with a message <STRING>
 * 1: The card to read <HASHMAP> (optional, default: the open thread's root)
 *
 * Return Value:
 * "GREEN", "YELLOW" or "RED"; "" when the asset has no open thread, its card
 * has no security line, or nothing on it is ticked <STRING>
 *
 * Example:
 * ["air:2"] call jmfsb_support_fnc_lzSecurity
 *
 * Public: Yes
 */

params [["_assetId", "", [""]], ["_message", createHashMap, [createHashMap]]];

if (!isServer) exitWith {""};

private _cardId = _message getOrDefault ["templateId", ""];
if (count _message isEqualTo 0) then {
    private _threadId = (localNamespace getVariable [QGVAR(threads), createHashMap]) getOrDefault [_assetId, ""];
    if (_threadId isEqualTo "") exitWith {};
    private _thread = (missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap]) getOrDefault [_threadId, createHashMap];
    // The thread's current order (2026-11-09) - a CASEVAC filed into a TIC,
    // an INSERTION after its PICKUP - not only its first card.
    _message = [_thread] call FUNC(threadOrder);
    _cardId = _message getOrDefault ["templateId", _thread getOrDefault ["rootTemplateId", ""]];
};
if (count _message isEqualTo 0) exitWith {""};

private _fields = ([_cardId] call EFUNC(messaging,template)) getOrDefault ["fields", createHashMap];
private _values = createHashMapFromArray (_message getOrDefault ["payload", []]);

private _word = "";
{
    private _field = _y;
    if !(LZ_SECURITY_WORD in toUpper (_field getOrDefault ["lineLabel", ""])) then {continue};
    private _type = _field getOrDefault ["type", ""];
    private _value = _values getOrDefault [_x, false];
    if (_type isEqualTo "choice" && _value isEqualType "") then {
        private _letter = toUpper ((trim _value) select [0, 1]);
        private _at = LZ_SECURITY_CHOICES findIf {(_x select 0) isEqualTo _letter};
        if (_at >= 0) exitWith {_word = (LZ_SECURITY_CHOICES select _at) select 1};
    };
    if (_word isNotEqualTo "") exitWith {};
    if (_type isNotEqualTo "bool") then {continue};
    if (_value isNotEqualTo true) then {continue};
    private _prefix = toUpper trim (_field getOrDefault ["prefix", ""]);
    if (_prefix in LZ_SECURITY_WORDS) exitWith {_word = _prefix};
    // The 9-line's N / P / E / X ticks (2026-11-09), by their letter.
    private _letterAt = LZ_SECURITY_CHOICES findIf {(_x select 0) isEqualTo _prefix};
    if (_letterAt >= 0) exitWith {_word = (LZ_SECURITY_CHOICES select _letterAt) select 1};
} forEach _fields;

_word
