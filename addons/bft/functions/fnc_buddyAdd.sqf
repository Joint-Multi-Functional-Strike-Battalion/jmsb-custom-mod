#include "script_component.hpp"
/*
 * Author: YonV
 * The buddy pick (user, 2026-11-05: "buddy is picked with ace interact"):
 * ACE interaction on a man of your own group - BUDDY UP pairs you
 * (FUNC(buddySet)), END BUDDY PAIR on your buddy ends it. Added to CAManBase
 * with inheritance, as FUNC(settingsAdd), so it survives respawn and unit
 * switching. The star then marks him in the devices' squad list and beside
 * his icon on every map (FUNC(drawMembers)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_bft_fnc_buddyAdd
 *
 * Public: No
 */

if (!hasInterface || GVAR(buddyAdded)) exitWith {};
GVAR(buddyAdded) = true;

private _pair = [
    QGVAR(buddyUp),
    "Buddy up",
    BUDDY_STAR,
    {
        params ["_target", "_player"];
        [_player, _target] call FUNC(buddySet);
    },
    {
        params ["_target", "_player"];
        alive _target
        && _target isNotEqualTo _player
        && {group _target isEqualTo group _player}
        && {([_player] call FUNC(buddyOf)) isNotEqualTo _target}
    }
] call ace_interact_menu_fnc_createAction;
["CAManBase", 0, ["ACE_MainActions"], _pair, true] call ace_interact_menu_fnc_addActionToClass;

private _end = [
    QGVAR(buddyEnd),
    "End buddy pair",
    BUDDY_STAR,
    {
        params ["", "_player"];
        [_player, objNull] call FUNC(buddySet);
    },
    {
        params ["_target", "_player"];
        ([_player] call FUNC(buddyOf)) isEqualTo _target
    }
] call ace_interact_menu_fnc_createAction;
["CAManBase", 0, ["ACE_MainActions"], _end, true] call ace_interact_menu_fnc_addActionToClass;
