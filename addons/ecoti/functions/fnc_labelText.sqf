#include "script_component.hpp"
/*
 * Author: JMSB
 * The text under a target's box this frame, as structured text: the AiTR line
 * (FUNC(targetLabel)) with its range, in the box's colour, and under it the net
 * card for a friendly player on the net (FUNC(targetCard)). Both are settled
 * twice a second; only the range is per frame. Nothing with the AiTR labels
 * setting off.
 *
 * Arguments:
 * 0: Target <OBJECT>
 * 1: Range, metres <NUMBER>
 *
 * Return Value:
 * [structured text, line count] - ["", 0] for none <ARRAY>
 *
 * Example:
 * [_unit, 240] call jmfsb_ecoti_fnc_labelText
 *
 * Public: No
 */

params ["_target", "_dist"];

if (!GVAR(labels)) exitWith {["", 0]};

private _range = if (_dist < LABEL_KM) then {
    format ["%1 m", round _dist]
} else {
    format ["%1 km", (round (_dist / 100)) / 10]
};

(_target getVariable [QGVAR(card), ["", 0]]) params ["_card", "_cardLines"];

[
    format [
        "<t align='center' color='%1'>%2%3%4%5</t>",
        _target getVariable [QGVAR(hex), "#ffffff"],
        _target getVariable [QGVAR(label), ""], LABEL_SEPARATOR, _range, _card
    ],
    1 + _cardLines
]
