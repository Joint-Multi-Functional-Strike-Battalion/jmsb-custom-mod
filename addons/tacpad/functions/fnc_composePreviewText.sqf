#include "script_component.hpp"
/*
 * Author: YonV
 * What the composer's MESSAGE PREVIEW reads: the card rendered off the values
 * the form holds, through the renderer every reader uses
 * (EFUNC(messaging,render)). A FRAGO (2026-11-09) previews the FRAGO card it
 * will send - only the changed lines, old and new (FUNC(composeFragoPayload)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The preview, plain text <STRING>
 *
 * Example:
 * private _text = [] call jmfsb_tacpad_fnc_composePreviewText
 *
 * Public: No
 */

if (GVAR(composeFrago) isNotEqualTo []) exitWith {
    ([] call FUNC(composeFragoPayload)) params ["_payload", "_changed"];
    if (_changed isEqualTo 0) exitWith {FRAGO_NOTHING};
    [FRAGO_ID, _payload, false] call EFUNC(messaging,render)
};

[GVAR(composeTemplate), GVAR(composeValues) toArray false, false] call EFUNC(messaging,render)
