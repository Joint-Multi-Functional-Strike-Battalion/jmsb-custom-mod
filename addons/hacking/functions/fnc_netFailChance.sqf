#include "script_component.hpp"
/*
 * Author: YonV
 * How likely THIS net break is to be noticed, given how many the operator has
 * already done recently.
 *
 * ONE NET IS A BREAK-IN; SIX IS A PATTERN. A flat chance made the right play
 * obvious and boring - sit in a treeline and work every group that walks past,
 * because the seventh costs exactly what the first did. Each break inside the
 * window adds a step, so a section that keeps pulling is eventually caught by
 * arithmetic rather than by luck.
 *
 * IT DECAYS RATHER THAN ACCUMULATING FOR EVER. The point is to price farming,
 * not to retire an operator: a step is shed for every window that passes
 * quietly, so a patient section is forgiven and an impatient one is not.
 *
 * Kept client-side, per player, because that is where the roll is made - see
 * FUNC(hackComplete). It is not a security boundary; a player who wants to lie
 * about their own detection chance can already lie about everything else.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Chance out of 100 <NUMBER>
 *
 * Example:
 * private _fail = [] call jmfsb_hacking_fnc_netFailChance
 *
 * Public: No
 */

private _base = missionNamespace getVariable [QGVAR(rh_fail_chance), RH_FAIL_DEF];
private _step = GVAR(netFailStep);
private _window = GVAR(netFailWindow) max 1;

// The times the operator has broken a net, newest last. Anything older than the
// window has been forgotten by the people who would have noticed.
private _now = CBA_missionTime;
private _hist = (missionNamespace getVariable [QGVAR(netHistory), []]) select {
    (_now - _x) < _window
};
GVAR(netHistory) = _hist;

(_base + (_step * count _hist)) min 95
