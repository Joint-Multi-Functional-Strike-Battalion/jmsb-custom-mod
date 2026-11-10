#include "script_component.hpp"
/*
 * Author: YonV
 * Moves a slot on to the next readout, and remembers it.
 *
 * The ring includes OFF - see FUNC(slotState) - so pressing past the end is how
 * a slot is emptied, which is one key rather than a key and a setting.
 *
 * Arguments:
 * 0: Slot - HUD_SLOT_LEFT or HUD_SLOT_RIGHT <NUMBER>
 * 1: Direction, -1 to go back <NUMBER> (optional, default 1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [HUD_SLOT_LEFT] call jmfsb_hud_fnc_cycle
 *
 * Public: Yes
 */

params [["_slot", HUD_SLOT_LEFT, [0]], ["_dir", 1, [0]]];

([_slot] call FUNC(slotState)) params ["_ring", "_i"];

private _next = (_i + _dir) mod (count _ring);
if (_next < 0) then {_next = _next + count _ring};

GVAR(slots) set [_slot, _next];

// Kept across missions: a player who has put the squad list on the left has said
// something about how they play, not about this mission.
profileNamespace setVariable [
    [QGVAR(slot_left), QGVAR(slot_right)] select (_slot isEqualTo HUD_SLOT_RIGHT),
    _next
];
saveProfileNamespace;

[] call FUNC(draw);
