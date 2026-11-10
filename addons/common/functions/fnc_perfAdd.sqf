#include "script_component.hpp"
/*
 * Author: YonV
 * Books one run of a costly tick against its budget (code review R9,
 * 2026-10-31): the RF mesh and the APS watch report how long each run took,
 * and FUNC(perfReport) writes the minute's count, average, worst and the runs
 * over budget to the RPT - so a 40-player test gives real numbers instead of
 * the review's estimates. Cheap enough to call every frame.
 *
 * Arguments:
 * 0: Name <STRING>
 * 1: Time this run took, ms <NUMBER>
 * 2: Budget per run, ms <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["rf.tick", (diag_tickTime - _t0) * 1000, 8] call jmfsb_common_fnc_perfAdd
 *
 * Public: Yes
 */

params [["_name", "", [""]], ["_ms", 0, [0]], ["_budget", 0, [0]]];

if (isNil QGVAR(perf)) then {GVAR(perf) = createHashMap};
(GVAR(perf) getOrDefault [_name, [0, 0, 0, 0, _budget]]) params ["_n", "_sum", "_max", "_over"];
GVAR(perf) set [_name, [_n + 1, _sum + _ms, _max max _ms, _over + parseNumber (_budget > 0 && _ms > _budget), _budget]];
