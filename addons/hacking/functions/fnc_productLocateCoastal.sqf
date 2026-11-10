#include "script_component.hpp"
/*
 * Author: YonV
 * LOCATE ANTI-SHIP: the coastal batteries themselves.
 *
 * JMSB spawns these rather than reading them off ALiVE (new.md section 1.2),
 * so the pool is the addon's own registry rather than an adapter call. A
 * mission running without the anti-ship module gets an empty pool and this
 * product is never offered - see FUNC(intelOptions).
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

private _pool = (missionNamespace getVariable [QEGVAR(antiship,batteries), []]) select {
    (_x select 2) getFriend _side < 0.6
};

if (isNil QGVAR(coastalLock)) then { GVAR(coastalLock) = createHashMap };

[_pool, _pos, _side, GVAR(coastalLock), "coastal", "COASTAL BATTERY"] call FUNC(ladderCircle)
