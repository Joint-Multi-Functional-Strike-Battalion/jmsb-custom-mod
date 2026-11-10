#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the aircraft files one card of its own in the thread its sortie flies
 * for, as itself (2026-11-01, DESIGN_SUPPORT_MESSAGING step 7) - WHEELS UP,
 * WHEELS DOWN - with an optional text. Through the support core
 * (EFUNC(support,fileCard)), queued in order with its state replies. Nothing
 * for a sortie no thread was filed for (the board's), and a deck without the
 * card says so in the RPT there.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Card id <STRING>
 * 2: Its text <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "wheelsup", "TO 045 782"] call jmfsb_support_air_fnc_threadCard
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_cardId", "", [""]], ["_text", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
private _threadId = _logic getVariable [QGVAR(sortieThread), ""];
if (_threadId isEqualTo "") exitWith {};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _threadId,
    _cardId,
    [[], [[CARD_TEXT_KEY, _text]]] select (_text isNotEqualTo ""),
    _logic getVariable [QGVAR(callsign), "AIR"]
] call EFUNC(support,fileCard);
