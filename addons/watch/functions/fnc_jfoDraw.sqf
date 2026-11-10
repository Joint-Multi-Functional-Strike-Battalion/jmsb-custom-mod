#include "script_component.hpp"
/*
 * Author: YonV
 * The JFO profile (design jfo: "impact areas only for now"; gate isJFO):
 * through the AiTR goggles, every live fire mission of his side as a ring on
 * the ground the size of its sheaf, with the shell and the time to impact -
 * IMPACT once it is due. Read off jmfsb_support_fires' published impact areas.
 * No slots, no device panel. Draw3D, this machine only.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_watch_fnc_jfoDraw
 *
 * Public: No
 */

private _impacts = missionNamespace getVariable [QEGVAR(support_fires,impacts), []];
if (_impacts isEqualTo [] || {!GVAR(hud_jfo)} || {(player getVariable ["isJFO", false]) isNotEqualTo true} || {!([] call FUNC(goggles))}) exitWith {};

{
    _x params ["", "_target", "_radius", "_kind", "_at", "_side"];
    if (_side isNotEqualTo side group player || {(player distance2D _target) > IMPACT_DRAW_RANGE}) then {continue};
    private _step = 360 / IMPACT_RING_SEGMENTS;
    for "_i" from 0 to (IMPACT_RING_SEGMENTS - 1) do {
        private _a = _target getPos [_radius, _i * _step];
        private _b = _target getPos [_radius, (_i + 1) * _step];
        drawLine3D [[_a # 0, _a # 1, IMPACT_LIFT], [_b # 0, _b # 1, IMPACT_LIFT], COLOUR_AMBER];
    };
    private _left = _at - CBA_missionTime;
    drawIcon3D ["", COLOUR_AMBER, [_target # 0, _target # 1, IMPACT_LABEL_UP], 0, 0, 0,
        format ["%1  %2 M  %3", toUpper _kind, round _radius, ["IMPACT", "ETA " + ([_left, "MM:SS"] call BIS_fnc_secondsToString)] select (_left > 0)],
        2, HUD_TEXT_SIZE, HUD_FONT, "center"];
} forEach _impacts;
