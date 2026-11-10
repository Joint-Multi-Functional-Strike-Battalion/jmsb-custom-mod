#include "script_component.hpp"
/*
 * Author: YonV
 * What a slot can show, and what it is showing.
 *
 * THE LIST IS THE SAME FOR BOTH SLOTS, and OFF is on it. That is the vanilla
 * info panel's own arrangement: cycling is a ring that includes showing nothing,
 * so a player turns a slot off by pressing past the end rather than by hunting
 * for a setting. Both slots offering everything means a left-hander and a
 * right-hander can each have what they want where they want it.
 *
 * A readout whose addon is not loaded stays on the ring and draws its own
 * absence - the suite is assembled from whatever a mission has, and a hole in
 * the ring would renumber every slot the first time a mod was dropped.
 *
 * Arguments:
 * 0: Slot - HUD_SLOT_LEFT or HUD_SLOT_RIGHT <NUMBER>
 *
 * Return Value:
 * 0: The ring, [id, label, drawer] each <ARRAY>
 * 1: Index of what this slot is showing <NUMBER>
 *
 * Example:
 * ([HUD_SLOT_LEFT] call jmfsb_hud_fnc_slotState) params ["_ring", "_i"]
 *
 * Public: No
 */

params [["_slot", HUD_SLOT_LEFT, [0]]];

// ONE FACT PER TILE, and one tile that carries the whole sweep for a player who
// can only spare a slot. The single tiles are drawn big enough to read while
// moving; SCANNER is the handset's own three readings at a size you have to stop
// for, which is the trade a player makes by choosing it.
private _ring = [
    ["drones", "DRONES", FUNC(widgetDrones)],
    ["jamming", "JAMMING", FUNC(widgetJamming)],
    ["radio", "RADIO", FUNC(widgetRadio)],
    ["ew", "SCANNER", FUNC(widgetEw)],
    ["squad", "SQUAD", FUNC(widgetSquad)],
    ["timer", "TIMER", FUNC(widgetTimer)],
    // the vehicle's active protection - charges, the RF emitter, the last
    // intercept. ONLY IN A VEHICLE (user, 2026-08-29: "aps tile should be
    // hidden when not in a vehicle"): the fourth entry is the condition the
    // draw asks before it lays the tile out at all, so on foot the slot is
    // simply empty rather than a box saying NO APS.
    ["aps", "APS", FUNC(widgetAps), { !isNull objectParent player }],
    ["off", "", {}]
];

private _i = (GVAR(slots) param [_slot, 0]) mod (count _ring);
if (_i < 0) then {_i = 0};

[_ring, _i]
