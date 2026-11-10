#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a thread's current order as the support core reads it (2026-11-09,
 * docs/DESIGN_MESSAGE_TEMPLATES.md): the last tasking card filed in it with
 * every FRAGO since laid over (EFUNC(messaging,currentOrder)) - the root of a
 * plain request thread; the CAS REQUEST filed into a TIC; the INSERTION filed
 * after the PICKUP. Returned as a message the readers take as they take a
 * root (FUNC(readOrder), FUNC(lzSecurity), FUNC(observer)): the tasking
 * message with the merged payload.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 *
 * Return Value:
 * The order message, empty when the thread has none <HASHMAP>
 *
 * Example:
 * private _order = [_thread] call jmfsb_support_fnc_threadOrder
 *
 * Public: Yes
 */

params [["_thread", createHashMap, [createHashMap]]];

private _store = missionNamespace getVariable [QEGVAR(messaging,messages), createHashMap];
private _bodies = (_thread getOrDefault ["messages", []]) apply {_store getOrDefault [_x, createHashMap]};
([_bodies] call EFUNC(messaging,currentOrder)) params ["_cardId", "_payload", "_tasking"];
if (_cardId isEqualTo "") exitWith {createHashMap};

private _order = +_tasking;
_order set ["templateId", _cardId];
_order set ["payload", _payload];
_order
