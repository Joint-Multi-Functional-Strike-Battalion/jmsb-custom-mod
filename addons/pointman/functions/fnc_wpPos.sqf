#include "script_component.hpp"
/*
 * Author: YonV
 * Where a waypoint is now. A fixed one is where it was put; one that FOLLOWS
 * a man (FUNC(follow)) is wherever he is, and the place he was last seen is
 * written back into it - so if he dies or drops out the waypoint stands
 * where he was, not at the map's corner.
 *
 * Arguments:
 * 0: Waypoint [position, label, target] <ARRAY>
 *
 * Return Value:
 * Position [x, y, 0] <ARRAY>
 *
 * Example:
 * [jmfsb_pointman_waypoints select 0] call jmfsb_pointman_fnc_wpPos
 *
 * Public: No
 */

params [["_wp", [], [[]]]];

private _target = _wp param [WP_TARGET, objNull];
if (!isNull _target && {alive _target}) then {
    private _pos = getPosATL _target;
    _pos set [2, 0];
    _wp set [WP_POS, _pos];
};

_wp param [WP_POS, []]
