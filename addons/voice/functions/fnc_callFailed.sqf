#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: the server says a call, or part of one, failed: no route on DATA,
 * busy (in another call, or no free slot), no answer, declined, bumped by a
 * FLASH call, dropped with no route, or refused. Notified, the busy tone, and
 * jmfsb_voice_callState [callId, reason]. No route, busy and no answer offer
 * CALL BACK (jmfsb_voice_fnc_callBack).
 *
 * Arguments:
 * 0: Call id <STRING>
 * 1: Reason <STRING>
 * 2: Units it concerns <ARRAY of OBJECTs>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["123_1", "busy", [_unit]] call jmfsb_voice_fnc_callFailed
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_reason", "", [""]], ["_units", [], [[]]]];

private _names = ((_units select {!isNull _x}) apply {name _x}) joinString ", ";
private _text = switch (_reason) do {
    case REASON_NO_ROUTE: {format ["No route on DATA to %1. CALL BACK available.", _names]};
    case REASON_BUSY: {format ["%1: busy. CALL BACK available.", _names]};
    case REASON_NO_ANSWER: {format ["%1: no answer. CALL BACK available.", _names]};
    case REASON_DECLINED: {format ["%1 declined.", _names]};
    case REASON_BUMPED: {"Call ended: a FLASH call took the slot."};
    case REASON_DROPPED: {"Dropped from the call: no route on DATA."};
    default {format ["Call refused: %1", _names]};
};

["CALL", _text] call EFUNC(notify,notify);
["busy", ""] call FUNC(playCue);
[QGVAR(callState), [_callId, _reason]] call CBA_fnc_localEvent;
