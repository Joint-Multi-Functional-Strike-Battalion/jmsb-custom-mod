#include "script_component.hpp"

// ON THE SUPPORT PAGE, AS A PROVIDER OF THE SUPPORT CORE. Registered on EVERY
// machine: the page is drawn on the client and reads its rows locally.
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["tasks", FUNC(tasks)],
    ["sitrep", FUNC(sitrep)],
    ["available", FUNC(assetAvailable)],
    ["preview", FUNC(preview)],
    ["overlay", FUNC(overlay)],
    ["types", call FUNC(typeList)]
]] call EFUNC(support,registerProvider);

// THE SERVER FIRES. An order accepted on a client lands here, and so does a
// recall.
if (isServer) then {
    [QGVAR(request), {_this call FUNC(request)}] call CBA_fnc_addEventHandler;
    [QGVAR(abort), {_this call FUNC(abort)}] call CBA_fnc_addEventHandler;
};

if (!hasInterface) exitWith {};

// WHAT THE OBSERVER HEARS: shot, splash, rounds complete, on station, lost.
// Sent to the man who asked, or to the asset's whole side when he is gone.
[QGVAR(say), {
    params [["_logic", objNull, [objNull]], ["_text", "", [""]], ["_priority", "normal", [""]]];
    if (isNull _logic || _text isEqualTo "") exitWith {};
    if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};
    ["SUPPORT", format ["%1 %2", _logic getVariable [QGVAR(callsign), "FIRES"], _text], _priority] call EFUNC(messaging,notify);
}] call CBA_fnc_addEventHandler;

// THE TARGET ON THE MAP while a mission runs (FUNC(mark) / FUNC(unmark)):
// local markers, drawn only for the asset's side, one icon and one area per
// asset - a new mission of the same asset replaces them.
[QGVAR(mark), {
    params [["_id", -1, [0]], ["_side", sideUnknown, [sideUnknown]], ["_pos", [], [[]]], ["_text", "", [""]], ["_radius", 0, [0]]];
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
}] call CBA_fnc_addEventHandler;

[QGVAR(unmark), {
    params [["_id", -1, [0]]];
    deleteMarkerLocal format ["%1_mark_%2", QUOTE(ADDON), _id];
    deleteMarkerLocal format ["%1_area_%2", QUOTE(ADDON), _id];
}] call CBA_fnc_addEventHandler;
