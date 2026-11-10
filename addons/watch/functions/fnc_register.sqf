#include "script_component.hpp"
/*
 * Author: YonV
 * Registers a watch profile (docs/DESIGN_WATCH_HUD.json). Other addons call it
 * for theirs - jmfsb_medic registers "medical". The core keeps the slots, the
 * keys, the panels and the clearing; a profile says only what is its own:
 *
 *     name      shown on the panel header
 *     slots     how many targets (default SLOTS_PER_PROFILE)
 *     gate      {params ["_unit"]; bool} - who has it
 *     accepts   {params ["_target"]; bool} - what the action key may add
 *     row       {params ["_target"]; [name, state word, colour, [line 2, line 3], live]}
 *     hud       true to draw the world panel from row
 *     report    {params ["_target"]} - what the REPORT key does (optional)
 *     share     {params ["_target"]} - what the SHARE key does (optional;
 *               FUNC(slotShare) puts it on players near)
 *     order     sort order; the action key asks profiles in this order
 *
 * Arguments:
 * 0: Profile id <STRING>
 * 1: Spec <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["medical", _spec] call jmfsb_watch_fnc_register
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_spec", createHashMap, [createHashMap]]];

if (_id isEqualTo "") exitWith {};
GVAR(profiles) set [_id, _spec];
if !(_id in GVAR(slots)) then {GVAR(slots) set [_id, []]};
