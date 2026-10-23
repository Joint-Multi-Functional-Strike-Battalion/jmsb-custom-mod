#include "script_component.hpp"
/*
 * Author: JMSB
 * The EW map layer, on a map control's Draw event - the vanilla map and the
 * device host's map both (FUNC(mapHook)). From this man's slice only:
 *
 *   DF lines   every fresh cut of his side, from the sensor along the
 *              bearing, with its error wedge
 *   fixes      a circle of the fix error and the track's id, class and band
 *   jammers    his side's own jammers, so nobody DFs a friend
 *
 * Off when the OVERVIEW tab's MAP LAYER is off.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * _map ctrlAddEventHandler ["Draw", {_this call jmfsb_ew_fnc_mapDraw}]
 *
 * Public: No
 */

params [["_map", controlNull, [controlNull]]];

if (!GVAR(mapLayer) || {GVAR(mine) isEqualTo []}) exitWith {};

private _isr = (GVAR(mine) param [4, []]) param [3, false];

{
    _x params ["_id", "_band", "", "", "", "_fix", "_fixErr", "", "", "_cuts"];
    {
        _x params ["_at", "_brg", "_err"];
        private _from = _at + [0];
        private _to = _from vectorAdd [DF_LINE_M * sin _brg, DF_LINE_M * cos _brg, 0];
        _map drawLine [_from, _to, COLOUR_CUT];
        {
            _map drawLine [_from, _from vectorAdd [DF_LINE_M * sin _x, DF_LINE_M * cos _x, 0], COLOUR_CUT_EDGE];
        } forEach [_brg - _err, _brg + _err];
    } forEach _cuts;

    if (_fix isNotEqualTo []) then {
        _map drawEllipse [_fix, _fixErr max SLICE_GRID_M, _fixErr max SLICE_GRID_M, 0, COLOUR_FIX, ""];
        _map drawIcon [
            GVAR(iconFix), COLOUR_FIX, _fix, MAP_ICON_PX, MAP_ICON_PX, 0,
            format ["%1 %2 %3", _id, [_x, _isr] call FUNC(classShown), _band],
            1, MAP_TEXT_SIZE, "PuristaMedium", "right"
        ];
    };
} forEach (GVAR(mine) param [1, []]);

{
    _x params ["_pos", "_mode", "_on", ["_devId", ""]];
    if (!_on) then {continue};
    _map drawIcon [GVAR(iconJam), COLOUR_OWN_JAM, _pos, MAP_ICON_PX, MAP_ICON_PX, 0, format ["%1 %2", _devId, toUpper _mode], 1, MAP_TEXT_SIZE, "PuristaMedium", "right"];
} forEach (GVAR(mine) param [9, []]);
