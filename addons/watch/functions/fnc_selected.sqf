#include "script_component.hpp"
/*
 * Author: YonV
 * The slot the device's F-keys act on in a profile (user, 2026-11-08: "use
 * the arrow keys to select them then f keys"): the one the arrows last picked
 * (FUNC(button)), held inside the slots there are - the first when none was
 * picked, the last when the picked one was taken off.
 *
 * Arguments:
 * 0: Profile id <STRING>
 *
 * Return Value:
 * Slot index, -1 with no slots <NUMBER>
 *
 * Example:
 * ["medical"] call jmfsb_watch_fnc_selected
 *
 * Public: No
 */

params [["_id", "", [""]]];

private _count = count (GVAR(slots) getOrDefault [_id, []]);
if (_count isEqualTo 0) exitWith {-1};
((GVAR(selected) getOrDefault [_id, 0]) max 0) min (_count - 1)
