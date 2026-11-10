#include "script_component.hpp"
/*
 * Author: YonV
 * SHOW ON MAP for a training area: the app closes, the tablet's map pans to
 * the area, and the area and its patrol ring are drawn for PREVIEW_TIME
 * seconds - on this machine only, since the training areas themselves stay
 * hidden from the trainees. A vehicle range (FUNC(vehRanges)) too, with an
 * arrow for the way its vehicles drive first.
 *
 * Arguments:
 * 0: Area or range key <STRING>
 * 1: Patrol radius past the edge, m <NUMBER>
 * 2: Heading of the first leg, a range only (optional, default -1: none) <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ta_city_north", 200] call jmfsb_training_fnc_showArea
 *
 * Public: No
 */

params [["_marker", "", [""]], ["_patrolOut", 0, [0]], ["_heading", -1, [0]]];

private _all = ([] call FUNC(areas)) + ([] call FUNC(vehRanges));
private _area = _all param [_all findIf {(_x # 0) isEqualTo _marker}, []];
if (_area isEqualTo []) exitWith {};
_area params ["", "_type", "_name", "_centre", "_a", "_b", "_angle", "_rect"];

{deleteMarkerLocal _x} forEach GVAR(previewMarkers);
GVAR(previewMarkers) = [];

private _outline = createMarkerLocal [format ["%1_area", QGVAR(preview)], _centre];
_outline setMarkerShapeLocal (["ELLIPSE", "RECTANGLE"] select _rect);
_outline setMarkerSizeLocal [_a, _b];
_outline setMarkerDirLocal _angle;
_outline setMarkerBrushLocal "Border";
_outline setMarkerColorLocal PREVIEW_COLOUR;
GVAR(previewMarkers) pushBack _outline;

private _label = createMarkerLocal [format ["%1_label", QGVAR(preview)], _centre];
_label setMarkerTypeLocal "mil_dot";
_label setMarkerColorLocal PREVIEW_COLOUR;
_label setMarkerTextLocal format ["%1 (%2)", toUpper _name, toUpper _type];
GVAR(previewMarkers) pushBack _label;

if (_heading >= 0) then {
    private _arrow = createMarkerLocal [format ["%1_arrow", QGVAR(preview)], _centre];
    _arrow setMarkerTypeLocal "mil_arrow";
    _arrow setMarkerDirLocal _heading;
    _arrow setMarkerColorLocal PREVIEW_COLOUR;
    GVAR(previewMarkers) pushBack _arrow;
};

if (_patrolOut > 0 && _type isNotEqualTo "cqb") then {
    private _ring = createMarkerLocal [format ["%1_ring", QGVAR(preview)], _centre];
    _ring setMarkerShapeLocal "ELLIPSE";
    private _r = (_a max _b) + _patrolOut;
    _ring setMarkerSizeLocal [_r, _r];
    _ring setMarkerBrushLocal "Border";
    _ring setMarkerColorLocal PREVIEW_COLOUR;
    _ring setMarkerAlphaLocal RING_ALPHA;
    GVAR(previewMarkers) pushBack _ring;
};

[{
    params ["_made"];
    {deleteMarkerLocal _x} forEach (_made select {_x in GVAR(previewMarkers)});
    GVAR(previewMarkers) = GVAR(previewMarkers) - _made;
}, [+GVAR(previewMarkers)], PREVIEW_TIME] call CBA_fnc_waitAndExecute;

[] call EFUNC(tacpad,appClose);
private _display = HOST_DISPLAY;
if (isNull _display) exitWith {};
private _maps = (allControls _display) select {ctrlType _x isEqualTo MAP_CTRL_TYPE};
private _map = _maps param [0, controlNull];
if (isNull _map) exitWith {};
ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [MAP_ANIM_TIME, ctrlMapScale _map, _centre];
ctrlMapAnimCommit _map;
