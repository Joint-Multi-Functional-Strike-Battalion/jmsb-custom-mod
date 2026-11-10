#include "script_component.hpp"
/*
 * Author: YonV
 * Switches the player's CURRENT group on, if nobody has said otherwise about it.
 *
 * THE TRACKER SWITCH IS A PROPERTY OF THE GROUP. That is right - a group is what
 * gets a marker - but it means the answer follows the group and not the man, so
 * every time a player moves into another group he arrives in one that has never
 * been switched on. His own marker disappears and the tracker looks broken when
 * it is doing exactly what it was told.
 *
 * ONLY WHEN NOBODY HAS DECIDED. A group whose visibility has been set - by a
 * mission init field, by its leader through the map menu, by an admin - keeps
 * that answer. This fills in the blank and nothing else.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_bft_fnc_autoEnable
 *
 * Public: No
 */

if (!hasInterface) exitWith {};

private _group = group player;
if (isNull _group) exitWith {};

// None means none: a mission that wants nobody tracked by default gets that,
// and the leader's menu is still how a group is switched on by hand.
if (GVAR(autoEnable) isEqualTo 0) exitWith {};

// Player only, or everyone. Either way this group has the player in it.
if !(isNil {_group getVariable QGVAR(visible)}) exitWith {};

_group setVariable [QGVAR(visible), true, true];
