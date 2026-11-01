#include "script_component.hpp"
/*
 * Author: JMSB
 * Once a minute (XEH_postInit), while Log tick timings is on: one RPT line
 * per timed tick (FUNC(perfAdd)) - runs, average and worst ms, the budget and
 * how many runs went over it - then starts the next minute afresh (R9).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_common_fnc_perfReport
 *
 * Public: No
 */

if (isNil QGVAR(perf) || {count GVAR(perf) isEqualTo 0}) exitWith {};
if (GVAR(perfLog)) then {
    {
        _y params ["_n", "_sum", "_max", "_over", "_budget"];
        INFO_6("perf %1: %2 runs, avg %3 ms, worst %4 ms, budget %5 ms, over %6",_x,_n,(_sum / (_n max 1)) toFixed 2,_max toFixed 2,_budget,_over);
    } forEach GVAR(perf);
};
GVAR(perf) = createHashMap;
