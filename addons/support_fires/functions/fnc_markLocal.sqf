#include "script_component.hpp"
/*
 * Author: YonV
 * Draws a mission's target as local markers, only for the asset's side: one
 * icon and one area per asset, a new mission of the same asset replacing
 * them. Sent by the server (FUNC(mark)) by remoteExec, JIP included, and
 * taken only from it (review S7: as a CBA event any client could draw or
 * move a target on another side's map).
 *
 * Arguments:
 * 0: The asset's id <NUMBER>
 * 1: The asset's side <SIDE>
 * 2: Target position <ARRAY>
 * 3: Marker text <STRING>
 * 4: Area radius (m), 0 for none <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [0, west, _pos, "THUNDER", 100] remoteExecCall ["jmfsb_support_fires_fnc_markLocal", 0, "jmfsb_support_fires_mark_0"]
 *
 * Public: No
 */

params [["_id", -1, [0]], ["_side", sideUnknown, [sideUnknown]], ["_pos", [], [[]]], ["_text", "", [""]], ["_radius", 0, [0]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("markLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};

private _icon = format ["%1_mark_%2", QUOTE(ADDON), _id];
private _area = format ["%1_area_%2", QUOTE(ADDON), _id];
deleteMarkerLocal _icon;
deleteMarkerLocal _area;
if (_side isNotEqualTo (side group player) || {_pos isEqualTo []}) exitWith {};

createMarkerLocal [_icon, _pos];
_icon setMarkerTypeLocal MARK_ICON;
_icon setMarkerColorLocal MARK_COLOR;
_icon setMarkerAlphaLocal MARK_ALPHA;
_icon setMarkerTextLocal _text;
if (_radius > 0) then {
    createMarkerLocal [_area, _pos];
    _area setMarkerShapeLocal "ELLIPSE";
    _area setMarkerBrushLocal MARK_AREA_BRUSH;
    _area setMarkerColorLocal MARK_COLOR;
    _area setMarkerSizeLocal [_radius, _radius];
};
