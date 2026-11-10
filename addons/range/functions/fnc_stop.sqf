#include "..\script_component.hpp"
/*
 * Author: YonV
 * Stops a range: frees it. The shooter's run sees that on its next tick,
 * stands the targets back up and keeps no score.
 *
 * Arguments:
 * 0: Range (the module logic) <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_range", objNull, [objNull]]];

if (isNull _range) exitWith {};

private _run = _range getVariable [QGVAR(run), []];
_range setVariable [QGVAR(run), [], true];

// A shooter who has gone leaves no run to tidy up - stand the targets here.
if (_run isNotEqualTo [] && {isNull (_run select 0) || {!alive (_run select 0)}}) then {
    {[_x, TARGET_UP] call FUNC(setTarget)} forEach ((_range getVariable [QGVAR(cfg), createHashMap]) getOrDefault ["targets", []]);
};
