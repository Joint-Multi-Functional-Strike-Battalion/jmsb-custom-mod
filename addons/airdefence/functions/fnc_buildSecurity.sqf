#include "script_component.hpp"
/*
 * Author: JMSB
 * Infantry guarding one battery.
 *
 * They stand OFF the hardware, not on it - a ring out from the radar rather
 * than a huddle around it. A player who has found the site should still have to
 * deal with somebody before walking onto it, and guards standing between the
 * launchers would just be killed by whatever kills the launchers.
 *
 * Kept live and out of ALiVE, like the battery they guard - see below.
 *
 * Arguments:
 * 0: The battery's position <ARRAY>
 * 1: The side <SIDE>
 * 2: Man classes to draw from <ARRAY>
 * 3: Markers never to place on <ARRAY>
 *
 * Return Value:
 * How many groups were made <NUMBER>
 *
 * Example:
 * [_pos, east, _kinds, _black] call jmfsb_airdefence_fnc_buildSecurity
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]],
        ["_kinds", [], [[]]], ["_black", [], [[]]]];

private _want = round GVAR(security);
if (_want <= 0) exitWith {0};

// Two is the ceiling on purpose. This is a temporary system standing in for
// ALiVE's own, and a battery is not meant to become a garrison a section has to
// assault - it is meant to be defended enough that walking on is not free.
_want = _want min AD_SEC_GROUPS_MAX;

private _groups = [_pos, _side, _kinds, _black, _want, AD_SEC_MIN_R, AD_SEC_MAX_R] call FUNC(placeGuards);

if (_groups isEqualTo []) exitWith {0};

[{
    params ["_groups", "_side", "_pos"];

    private _live = _groups select {!isNull _x};
    if (_live isEqualTo []) exitWith {};

    // NOT PROFILED - see the note in FUNC(crewSite). Guards handed to
    // ALiVE's runtime profiler are deleted by it, and a site whose guards
    // vanished is the same empty site the user photographed. They stay live
    // and say so to ALiVE rather than only to the log.
    {[_x] call EFUNC(adapter_alive,profileIgnore)} forEach _live;

    INFO_2("%1 security group(s) on the battery at %2",count _live,mapGridPosition _pos);
}, [_groups, _side, _pos]] call CBA_fnc_execNextFrame;

count _groups
