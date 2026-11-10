#include "script_component.hpp"
/*
 * Author: YonV
 * Adds a target to a profile's slots, or takes it off if it is there. A full
 * profile says so through the notification row and adds nothing. Several
 * players may watch the same target; each list is the player's own.
 *
 * A slot is [target, pinned, lost since, added at] - lost since is -1 while
 * the target is in reach (FUNC(tick)). The profile's onAdd / onRemove run
 * with the target (recon tells the server about its contacts).
 *
 * Arguments:
 * 0: Profile id <STRING>
 * 1: Target <OBJECT>
 *
 * Return Value:
 * Now watched <BOOL>
 *
 * Example:
 * ["medical", cursorObject] call jmfsb_watch_fnc_toggle
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_target", objNull, [objNull]]];

if (isNull _target || {!(_id in GVAR(profiles))}) exitWith {false};

private _slots = GVAR(slots) getOrDefault [_id, []];
private _spec = GVAR(profiles) get _id;
private _at = _slots findIf {(_x # 0) isEqualTo _target};
if (_at >= 0) exitWith {
    _slots deleteAt _at;
    [_target] call (_spec getOrDefault ["onRemove", {}]);
    false
};

private _max = _spec getOrDefault ["slots", SLOTS_PER_PROFILE];
if (count _slots >= _max) exitWith {
    [NOTE_TITLE, format ["%1: %2 slots full - clear one first.", toUpper (_spec getOrDefault ["name", _id]), _max], NOTE_COLOUR] call EFUNC(notify,notify);
    false
};

_slots pushBack [_target, false, -1, CBA_missionTime];
GVAR(slots) set [_id, _slots];
GVAR(current) = _id;
[_target] call (_spec getOrDefault ["onAdd", {}]);
true
