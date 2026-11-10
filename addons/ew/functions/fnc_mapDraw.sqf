#include "script_component.hpp"
/*
 * Author: YonV
 * The EW map layer, on a map control's Draw event - the vanilla map and the
 * device host's map both (FUNC(mapHook)), and the phone's walking-view map
 * (jmfsb_devices_fnc_overlayOpen). From this man's slice only:
 *
 *   fixes      a circle of the fix error and the track's id, class and band
 *              (no DF bearing lines since 2026-11-01, user)
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
    _x params ["_id", "_band", "", "", "", "_fix", "_fixErr"];
    // NO DF BEARING LINES (user, 2026-11-01: "still some faded yellow lines
    // coming from the group to places on the map" - "remove them"). A track
    // shows on the map only once it is fixed; its cuts stay in the EW app.
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
