#include "script_component.hpp"
/*
 * Author: YonV
 * The world panels (hud): for each watched target of a profile that draws one
 * and whose hudOn holds (medical: the AiTR goggles drawing), a panel beside
 * him that moves with him. The full panel within FULL_RANGE; beyond TAG_RANGE,
 * with the shrink setting on, a tag - slot number, state colour, one value;
 * between, name, state and the first value line. Nothing past DRAW_RANGE.
 * Draw3D, this machine only; FUNC(hudDraw) shows them, centred and shaded.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_watch_fnc_draw
 *
 * Public: No
 */

private _panels = [];
{
    private _spec = GVAR(profiles) getOrDefault [_x, createHashMap];
    if (_y isEqualTo [] || {!(_spec getOrDefault ["hud", false])} || {!([_x] call FUNC(hudOn))} || {!([] call (_spec getOrDefault ["hudOn", {true}]))}) then {continue};
    private _row = _spec getOrDefault ["row", {[]}];
    {
        private _target = _x # 0;
        private _dist = player distance _target;
        if (isNull _target || _target isEqualTo player || _dist > DRAW_RANGE) then {continue};
        ([_target] call _row) params [["_name", ""], ["_word", ""], ["_colour", COLOUR_INK], ["_values", []], ["_live", true]];
        private _ink = [COLOUR_GREY, COLOUR_INK] select _live;
        private _lines = switch (true) do {
            case (GVAR(shrink) && _dist > TAG_RANGE): {
                [[format ["%1  %2", _forEachIndex + 1, _values param [0, _word]], _colour]]
            };
            case (_dist > FULL_RANGE): {
                [[format ["%1  %2 - %3", _forEachIndex + 1, _name, _word], _colour], [_values param [0, ""], _ink]]
            };
            default {
                [[format ["%1  %2 - %3", _forEachIndex + 1, _name, _word], _colour]] + (_values apply {[_x, _ink]})
            };
        };
        // the panel's centre on screen; behind the camera or off it, none
        private _screen = worldToScreen (_target modelToWorldVisual ((_target selectionPosition HUD_SELECTION) vectorAdd HUD_SIDE));
        if (_screen isEqualTo []) then {continue};
        // the EKG trace under the full panel (FUNC(trace))
        private _trace = _spec getOrDefault ["trace", {}];
        private _wave = [];
        if (_dist <= FULL_RANGE && {_trace isNotEqualTo {}}) then {
            _wave = [[_target] call _trace] call FUNC(trace);
        };
        _panels pushBack [_screen, _lines, count _lines isEqualTo 1, _wave];
    } forEach _y;
} forEach GVAR(slots);

[_panels] call FUNC(hudDraw);
