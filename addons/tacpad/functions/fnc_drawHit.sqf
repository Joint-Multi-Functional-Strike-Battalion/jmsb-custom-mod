#include "script_component.hpp"
/*
 * Author: YonV
 * The transparent button that makes a drawn thing pressable, laid over the top
 * of it and carrying the handler.
 *
 * STRUCTURED TEXT EATS THE PRESS. This is the second half of the input story and
 * the one that cost a fortnight: a structured text control takes mouse input -
 * it has to, it can carry links - and it does not raise ButtonClick, so a label
 * lying over a button is a hole in that button. Where a label covered most of a
 * cell, the cell answered only in the margins around it; the settings strip,
 * whose label runs from the gear to the far edge, answered only on the gear.
 * "Only the icon is clickable" is exactly what that looks like.
 *
 * So every label already drawn INSIDE this button's rectangle is given a press
 * handler that fires this button's own handler, with this button as the caller -
 * which is what the handlers all read their data off. Nothing double-fires: one
 * control receives a press, and if the button gets it the label never sees it.
 *
 * It works with no change at any call site because the vocabulary already draws
 * in that order everywhere - fill, frame, text, and the hit last.
 *
 * Arguments:
 * 0: Parent <CONTROL>
 * 1: Position [x, y, w, h], relative to the parent <ARRAY>
 * 2: Called with [control] when clicked <CODE>
 *
 * Return Value:
 * The button, so the caller can hang its own data on it <CONTROL>
 *
 * Example:
 * private _hit = [_body, [0, _y, _w, _h], {...}] call jmfsb_tacpad_fnc_drawHit
 *
 * Public: Yes
 */

params [["_parent", controlNull, [controlNull]], ["_pos", [0, 0, 0, 0], [[]], 4], ["_handler", {}, [{}]]];

if (isNull _parent) exitWith {controlNull};

private _ctrl = (ctrlParent _parent) ctrlCreate [QGVAR(hit), -1, _parent];
_ctrl ctrlSetPosition _pos;
_ctrl ctrlCommit 0;
_ctrl setVariable [QGVAR(hitHandler), _handler];

[_ctrl, _handler] call FUNC(hotspot);

// Labels drawn into this same group THIS FRAME, registered by FUNC(drawText) -
// so this is a handful of controls rather than a walk over every control on the
// display, once per hit. Same group means the same coordinate space, so
// containment is a plain rectangle test with nothing to convert.
_pos params ["_hx", "_hy", "_hw", "_hh"];

{
    if (isNull _x) then {continue};

    // First hit to cover a label owns it. Two buttons over one label would fire
    // twice off one press.
    if (!isNull (_x getVariable [QGVAR(hitCtrl), controlNull])) then {continue};

    (ctrlPosition _x) params ["_lx", "_ly", "_lw", "_lh"];

    // Wholly inside, so a label spanning two cells is never claimed by one of
    // them. A hair of tolerance because a label's box is centred on its line and
    // can be a rounding under the cell it sits in.
    if (_lx < _hx - 1e-4
        || {_ly < _hy - 1e-4}
        || {_lx + _lw > _hx + _hw + 1e-4}
        || {_ly + _lh > _hy + _hh + 1e-4}) then {continue};

    _x setVariable [QGVAR(hitCtrl), _ctrl];
    _x ctrlAddEventHandler ["MouseButtonDown", {
        params ["_label", "_button"];
        if (_button isNotEqualTo 0) exitWith {false};

        private _hit = _label getVariable [QGVAR(hitCtrl), controlNull];
        if (isNull _hit) exitWith {false};

        [_hit] call (_hit getVariable [QGVAR(hitHandler), {}]);
        true
    }];
} forEach (_parent getVariable [QGVAR(labels), []]);

_ctrl
