#include "script_component.hpp"
/*
 * Author: YonV
 * LOCATE LOGISTICS: where the enemy's supply comes from, on the ladder.
 *
 * LOGCOM's supply network is the list of places it has delivered to, plus
 * the HQ it delivers from. Those are the hubs - hit one and the convoys
 * that keep the objectives fed have nowhere to start from. The adapter
 * reads them straight off ALiVE's network and keeps LOGCOM's own rule for
 * which are still live.
 *
 * Same ladder as everything else - see FUNC(ladderCircle) for the rules.
 *
 * Arguments:
 * 0: Where the hack happened <ARRAY>
 * 1: Asking side <SIDE>
 *
 * Return Value:
 * Anything plotted <BOOL>
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]]];

if (isNil QEFUNC(adapter_alive,logisticsHubs)) exitWith {false};

private _pool = [];
{
    _x params ["_id", "_at", "_hside"];
    if (_hside getFriend _side >= 0.6) then {continue};
    _pool pushBack [_id, _at, _hside];
} forEach (call EFUNC(adapter_alive,logisticsHubs));

if (isNil QGVAR(hubLock)) then { GVAR(hubLock) = createHashMap };
[_pool, _pos, _side, GVAR(hubLock), "hub", "LOGISTICS HUB"] call FUNC(ladderCircle)
