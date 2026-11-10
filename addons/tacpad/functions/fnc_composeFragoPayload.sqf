#include "script_component.hpp"
/*
 * Author: YonV
 * The FRAGO card's payload from the composer (2026-11-09, FUNC(composeFrago)):
 * the order's card in Card.A, the REASON, and for every field of the order
 * that no longer says what it said (FUNC(fragoSame)) its new value - "" for
 * an emptied box, false for an unticked one - and the old one under the key +
 * FRAGO_WAS. A grid picked from a marker takes the marker's name with it. The
 * server writes the old values again from its own copy
 * (EFUNC(messaging,srvSubmit)); these are what the preview reads.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: Payload, [key, value] pairs <ARRAY>
 * 1: How many fields changed <NUMBER>
 *
 * Example:
 * ([] call jmfsb_tacpad_fnc_composeFragoPayload) params ["_payload", "_changed"]
 *
 * Public: No
 */

GVAR(composeFrago) params [["_cardId", "", [""]], ["_was", createHashMap, [createHashMap]]];
if (_cardId isEqualTo "") exitWith {[[], 0]};

private _template = [_cardId] call EFUNC(messaging,template);
private _fields = _template getOrDefault ["fields", createHashMap];

private _payload = [[FRAGO_CARD_KEY, _cardId]];
private _reason = GVAR(composeValues) getOrDefault [FRAGO_REASON_KEY, ""];
if (_reason isEqualType "" && {trim _reason isNotEqualTo ""}) then {_payload pushBack [FRAGO_REASON_KEY, trim _reason]};

private _changed = 0;
{
    private _field = _fields getOrDefault [_x, createHashMap];
    private _now = GVAR(composeValues) getOrDefault [_x, ""];
    private _old = _was getOrDefault [_x, ""];
    if ([_field, _now, _old] call FUNC(fragoSame)) then {continue};

    private _type = _field getOrDefault ["type", "text"];
    if (_type isEqualTo "bool") then {
        _now = _now isEqualTo true;
    } else {
        if (_now isEqualTo false) then {_now = ""};
        if (_type isEqualTo "number" && _now isEqualType "") then {
            if ((trim _now) regexMatch "^-?\d+(\.\d+)?$") then {_now = parseNumber (trim _now)};
        };
    };
    _payload pushBack [_x, _now];
    _payload pushBack [_x + FRAGO_WAS, _old];
    private _marker = GVAR(composeValues) getOrDefault [_x + MARKER_NAME_SUFFIX, ""];
    if (_now isEqualType [] && _marker isEqualType "" && _marker isNotEqualTo "") then {
        _payload pushBack [_x + MARKER_NAME_SUFFIX, _marker];
    };
    _changed = _changed + 1;
} forEach (_template getOrDefault ["order", []]);

[_payload, _changed]
