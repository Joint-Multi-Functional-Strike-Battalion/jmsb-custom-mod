#include "script_component.hpp"
/*
 * Author: JMSB
 * The ACM Evacuation Zone module. PLACING IT IS THE ENABLE.
 *
 * On the server, every "Check Every" seconds (6 by default), any AI inside the module's area is
 * evacuated the way ACM's "Evacuate patient" action does it
 * (ACM_evacuation_fnc_defineEvacuationPoint): the unit is dropped if somebody
 * is carrying it, removed from the mission, and - if ACM had converted it to
 * a casualty - its side gets the casualty ticket back. A unit in a vehicle is
 * taken out of its seat where the vehicle is local (deleteVehicleCrew), so the
 * vehicle and everyone else in it stay. Players are never evacuated.
 * (user, 2026-10-09: "if an ai enters that zone the evacuate action from acm
 * run on them even if they are in a vehicle")
 *
 * The zone is on everyone's map: a global area marker the shape and size of the
 * module's area, and a medical icon labelled EVAC in its centre. Both follow the
 * module if Zeus moves or resizes it, and go when it is deleted.
 * (user, 2026-10-10: "the acm eva zone make sure the mod places a marker on tha map")
 *
 * Arguments (module standard):
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

#define EVAC_INTERVAL_DEFAULT 6
#define EVAC_INTERVAL_MIN 1
#define EVAC_MARKER_COLOUR "ColorWEST"
#define EVAC_MARKER_ICON "b_med"
#define EVAC_MARKER_TEXT "EVAC"
#define EVAC_MARKER_BRUSH "FDiagonal"

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

private _casualtiesOnly = (_logic getVariable ["who", "all"]) isEqualTo "casualties";
private _interval = (_logic getVariable ["interval", EVAC_INTERVAL_DEFAULT]) max EVAC_INTERVAL_MIN;
private _whoLabel = ["every AI", "casualties only"] select _casualtiesOnly;
INFO_3("ACM evacuation zone at %1, %2, every %3s",mapGridPosition _logic,_whoLabel,_interval);

// the map markers: one per zone, so a counter keeps two zones apart. Every
// command but the last on each marker is Local - the last global one sends
// the whole marker state in one network update
private _index = missionNamespace getVariable [QGVAR(evacZoneCount), 0];
missionNamespace setVariable [QGVAR(evacZoneCount), _index + 1];
private _areaMarker = createMarker [format [QGVAR(evacZone_area_%1), _index], getPosATL _logic];
_areaMarker setMarkerColorLocal EVAC_MARKER_COLOUR;
_areaMarker setMarkerBrushLocal EVAC_MARKER_BRUSH;
// drawn now as well as on every change, or the zone shows no area until the first check
(_logic getVariable ["objectArea", [0, 0, 0, false, -1]]) params ["_a0", "_b0", "_dir0", "_rect0"];
_areaMarker setMarkerShapeLocal (["ELLIPSE", "RECTANGLE"] select _rect0);
_areaMarker setMarkerSizeLocal [_a0, _b0];
_areaMarker setMarkerDir _dir0;
private _iconMarker = createMarker [format [QGVAR(evacZone_icon_%1), _index], getPosATL _logic];
_iconMarker setMarkerTypeLocal EVAC_MARKER_ICON;
_iconMarker setMarkerColorLocal EVAC_MARKER_COLOUR;
_iconMarker setMarkerText EVAC_MARKER_TEXT;

[{
    params ["_args", "_handle"];
    _args params ["_logic", "_casualtiesOnly", "_areaMarker", "_iconMarker", "_lastDrawn"];
    if (isNull _logic) exitWith {
        deleteMarker _areaMarker;
        deleteMarker _iconMarker;
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    // the area as it is now - Zeus may move or resize the module mid-mission
    (_logic getVariable ["objectArea", [0, 0, 0, false, -1]]) params ["_a", "_b", "_dir", "_rect"];
    private _area = [getPosATL _logic, _a, _b, _dir, _rect];

    // redraw the markers only when the area changed - every set is a network message
    if (_area isNotEqualTo _lastDrawn) then {
        _areaMarker setMarkerShapeLocal (["ELLIPSE", "RECTANGLE"] select _rect);
        _areaMarker setMarkerPosLocal (_area select 0);
        _areaMarker setMarkerSizeLocal [_a, _b];
        _areaMarker setMarkerDir _dir;
        _iconMarker setMarkerPos (_area select 0);
        _args set [4, _area];
    };

    {
        private _unit = _x;
        if (isPlayer _unit || {!alive _unit} || {!(_unit inArea _area)}) then {continue};
        private _claimed = _unit getVariable ["ACM_evacuation_casualtyTicketClaimed", false];
        if (_casualtiesOnly && {!(_claimed || {_unit getVariable ["ACE_isUnconscious", false]})}) then {continue};

        // somebody carrying it puts it down first, as ACM's action does
        private _carrier = attachedTo _unit;
        if (!isNull _carrier && {_carrier getVariable ["ace_dragging_isCarrying", false]}) then {
            [_carrier, _unit] remoteExecCall ["ace_dragging_fnc_dropObject_carry", _carrier];
        };

        // the casualty ticket, only for what ACM converted - the same rule as its action
        if (_claimed && {missionNamespace getVariable ["ACM_evacuation_enable", false]}) then {
            [true, _unit getVariable ["ACM_evacuation_CasualtySide", 0]] call ACM_evacuation_fnc_setCasualtyTicket;
        };

        private _veh = objectParent _unit;
        if (isNull _veh) then {
            deleteVehicle _unit;
        } else {
            [_veh, _unit] remoteExecCall ["deleteVehicleCrew", _veh];
        };
        TRACE_2("evacuated",_unit,_veh);
    } forEach allUnits;
}, _interval, [_logic, _casualtiesOnly, _areaMarker, _iconMarker, [getPosATL _logic, _a0, _b0, _dir0, _rect0]]] call CBA_fnc_addPerFrameHandler;
