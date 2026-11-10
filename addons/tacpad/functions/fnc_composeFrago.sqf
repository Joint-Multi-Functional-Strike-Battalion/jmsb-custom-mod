#include "script_component.hpp"
/*
 * Author: YonV
 * FRAGO in a thread (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09: "it opens
 * the thread's current tasking template with the last values filled in. You
 * change what changes; the card it makes shows only the changed lines, old
 * value and new. One added line: reason, optional."). The composer opens on
 * the thread's current order (EFUNC(messaging,currentOrder) over the cached
 * bodies - the last tasking card with every FRAGO since laid over), its values
 * in; GVAR(composeFrago) holds [card id, the values it opened with], which
 * FUNC(composeCard) marks the changed lines against and FUNC(composeSend)
 * turns into the FRAGO card's payload (FUNC(composeFragoPayload)). Every
 * opener of the FRAGO card ends here (FUNC(composeOpen), the picker).
 *
 * Arguments:
 * 0: Thread id <STRING>
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * ["T0004"] call jmfsb_tacpad_fnc_composeFrago
 *
 * Public: No
 */

params [["_threadId", "", [""]]];

if (_threadId isEqualTo "" || isNil QEFUNC(messaging,currentOrder)) exitWith {false};

private _cached = (missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [_threadId, []];
private _bodies = (_cached param [1, []]) apply {
    if (_x isEqualType []) then {createHashMapFromArray _x} else {_x}
};
([_bodies] call EFUNC(messaging,currentOrder)) params ["_cardId", "_payload"];
if (_cardId isEqualTo "") exitWith {
    ["FRAGO", FRAGO_NO_ORDER, "high"] call EFUNC(messaging,notify);
    false
};

private _opened = [_threadId, _cardId, false, "", _payload] call FUNC(composeOpen);
if (!_opened) exitWith {false};

GVAR(composeFrago) = [_cardId, createHashMapFromArray _payload];
GVAR(composeNote) = format [FRAGO_NOTE, _threadId];
true
