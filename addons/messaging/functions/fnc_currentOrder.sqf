#include "script_component.hpp"
/*
 * Author: YonV
 * A thread's current order (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09):
 * the last tasking card filed in it - a root or both card that moves a thread
 * into a state, the root itself or a starter filed into the thread since -
 * with every FRAGO filed after it laid over its values. One answer on the
 * server (FUNC(srvSubmit) checks a FRAGO against it, the support core hands
 * the merged order to the asset) and on the client (the composer opens a
 * FRAGO on it; the reader offers a thread's commands by its card).
 *
 * Arguments:
 * 0: The thread's messages, in order <ARRAY of HASHMAPs>
 *
 * Return Value:
 * [card id, payload as [key, value] pairs, the tasking message] - ["", [],
 * empty] when the thread has no order <ARRAY>
 *
 * Example:
 * ([_messages] call jmfsb_messaging_fnc_currentOrder) params ["_cardId", "_payload"]
 *
 * Public: Yes
 */

params [["_messages", [], [[]]]];

private _cardId = "";
private _values = createHashMap;
private _tasking = createHashMap;

{
    if !(_x isEqualType createHashMap) then {continue};
    private _id = _x getOrDefault ["templateId", ""];
    private _payload = _x getOrDefault ["payload", []];

    if (_id isEqualTo FRAGO_ID) then {
        private _frago = createHashMapFromArray _payload;
        if ((_frago getOrDefault [FRAGO_CARD_KEY, ""]) isNotEqualTo _cardId || _cardId isEqualTo "") then {continue};
        {
            if (_x in [FRAGO_CARD_KEY, FRAGO_REASON_KEY]) then {continue};
            if ((_x find FRAGO_WAS) >= 0) then {continue};
            private _new = _y;
            // An emptied line is a line taken off the order.
            if (_new in ["", false]) then {
                _values deleteAt _x;
            } else {
                _values set [_x, _new];
            };
        } forEach _frago;
        continue;
    };

    private _template = [_id] call FUNC(template);
    if (_template isEqualTo createHashMap) then {continue};
    if !((_template get "kind") in [KIND_ROOT, KIND_BOTH]) then {continue};
    if ((_template get "transitionsTo") isEqualTo "") then {continue};
    _cardId = _id;
    _values = createHashMapFromArray _payload;
    _tasking = _x;
} forEach _messages;

[_cardId, _values toArray false, _tasking]
