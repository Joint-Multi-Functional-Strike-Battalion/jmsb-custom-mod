#include "script_component.hpp"
/*
 * Author: YonV
 * Server: one of the jump aircraft's milestones in the run's thread, as the
 * aircraft (EFUNC(support,fileCard); 2026-11-02) - WHEELS UP, RED LIGHT,
 * GREEN LIGHT - GO, STICK OUT, INBOUND - with its detail line. The support
 * core files nothing for a thread that is over, or whose issuer is gone.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: Card id <STRING>
 * 2: Detail, "" none <STRING>
 * 3: FLASH <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st, "redlight", "PASS 1 OF 2 - STAND BY", true] call jmfsb_jumpmaster_fnc_threadCard
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_cardId", "", [""]], ["_text", "", [""]], ["_flash", false, [false]]];

if (!isServer) exitWith {};

[
    _st getOrDefault ["assetId", ""],
    _st getOrDefault ["thread", ""],
    _cardId,
    [[], [[CARD_TEXT_KEY, _text]]] select (_text isNotEqualTo ""),
    _st getOrDefault ["callsign", JUMP_CALLSIGN],
    ["", PRIORITY_FLASH] select _flash
] call EFUNC(support,fileCard);
