#include "script_component.hpp"
/*
 * Author: YonV
 * Turns a slot off, or back on to whatever it was last showing.
 *
 * IT REMEMBERS, WHICH IS THE WHOLE DIFFERENCE FROM CYCLING. Off is on the cycle
 * ring - see FUNC(slotState) - so a player CAN reach it by stepping past the
 * end, but then getting back to the squad list means stepping through the other
 * two. A toggle that dropped you at the front of the ring would be a toggle
 * nobody used twice.
 *
 * Arguments:
 * 0: Slot - HUD_SLOT_LEFT or HUD_SLOT_RIGHT <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [HUD_SLOT_LEFT] call jmfsb_hud_fnc_toggle
 *
 * Public: Yes
 */

params [["_slot", HUD_SLOT_LEFT, [0]]];

([_slot] call FUNC(slotState)) params ["_ring", "_i"];

private _offIndex = _ring findIf {(_x select 0) isEqualTo "off"};
private _key = [QGVAR(last_left), QGVAR(last_right)] select (_slot isEqualTo HUD_SLOT_RIGHT);

private _next = if (_i isEqualTo _offIndex) then {
    // Back on. Whatever it was showing before, or this slot's own default when
    // it has never been on - a slot that came back empty would look broken.
    private _was = profileNamespace getVariable [_key, [4, 3] select (_slot isEqualTo HUD_SLOT_RIGHT)];
    if (!(_was isEqualType 0) || _was isEqualTo _offIndex) then {_was = 0};
    _was
} else {
    profileNamespace setVariable [_key, _i];
    _offIndex
};

GVAR(slots) set [_slot, _next];
profileNamespace setVariable [
    [QGVAR(slot_left), QGVAR(slot_right)] select (_slot isEqualTo HUD_SLOT_RIGHT),
    _next
];
saveProfileNamespace;

[] call FUNC(draw);
