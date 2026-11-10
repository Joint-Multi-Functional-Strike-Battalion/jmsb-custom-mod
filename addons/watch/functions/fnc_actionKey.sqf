#include "script_component.hpp"
/*
 * Author: YonV
 * The ACTION key (numpad 9): the context action on what the player looks at.
 * A target already in one of his profiles comes off; otherwise it goes into
 * the first profile, by order, that he has (gate) and that takes it (accepts).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [] call jmfsb_watch_fnc_actionKey
 *
 * Public: No
 */

// Nothing looked at: an addon's own context action may take it - C2 reports
// "CROSSED PL BLUE" near a measure (GVAR(fallbacks), id -> code -> handled).
private _target = [] call FUNC(lookTarget);
if (isNull _target) exitWith {
    private _done = false;
    {
        if ([] call _y) exitWith {_done = true};
    } forEach GVAR(fallbacks);
    _done
};

// already watched: off
private _done = false;
{
    if ((_y findIf {(_x # 0) isEqualTo _target}) >= 0) exitWith {
        [_x, _target] call FUNC(toggle);
        _done = true;
    };
} forEach GVAR(slots);
if (_done) exitWith {true};

private _id = [_target] call FUNC(profileFor);
if (_id isEqualTo "") exitWith {false};
[_id, _target] call FUNC(toggle);
true
