#include "script_component.hpp"
/*
 * Author: YonV
 * The contact a shooter should act on, or [] if none is worth acting on.
 *
 * Every consumer that wants "the best target near me" was going to write this
 * loop, and they would have written it four different ways. Scoring lives
 * here so a mortar, a drone and a director all agree on what "best" means:
 * confidence first, then how tightly it is fixed, then how close it is.
 *
 * Arguments:
 * 0: Owning side <SIDE>
 * 1: Position to judge distance from <ARRAY>
 * 2: Reach, m - contacts beyond it are none of the caller's business <NUMBER>
 * 3: Least confidence <NUMBER> (optional, default 0.35 - anything staler is a
 *    search problem, not a shooting one)
 * 4: Greatest error, m <NUMBER> (optional, 0 = no limit)
 *
 * Return Value:
 * [id, targetSide, pos, error, confidence, age, sources, object], or [] <ARRAY>
 *
 * Example:
 * [east, getPosATL _gun, 8000, 0.5, 200] call jmfsb_common_fnc_contactBest
 */

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_from", [], [[]]],
    ["_reach", 0, [0]],
    ["_minConf", 0.35, [0]],
    ["_maxError", 0, [0]]
];

if (_from isEqualTo [] || _reach <= 0) exitWith {[]};

private _best = [];
private _bestScore = -1;

{
    _x params ["", "", "_pos", "_error", "_conf"];
    private _d = _pos distance2D _from;
    if (_d > _reach) then {continue};

    // confidence dominates, a tight fix is worth having, near beats far
    private _score = _conf
        + (1 - ((_error / 500) min 1)) * 0.5
        + (1 - (_d / _reach)) * 0.25;

    if (_score > _bestScore) then {
        _bestScore = _score;
        _best = _x;
    };
} forEach ([_side, _minConf, _maxError] call FUNC(contactGet));

_best
