#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This function creates a staging zone and saves it to a mission name space.
 * The zone can be OBJECT, MARKER or POSITION ARRAY
 * Every zone also gets a radio base station with a satellite uplink at its
 * centre, made once by the server whoever adds the zone (FUNC(stagingUplink),
 * setting "Staging zone satellite uplink").
 *
 * Arguments:
 * 0: Zone <OBJECT/STRING/ARRAY>
 * 1: Zone Size <NUMBER/STRING> (Optional) [Default; 12]
 *
 * Return:
 * Nothing
 *
 * Example:
 * [this] call jmfsb_mission_fnc_addStagingZone
 * [this, 3] call jmfsb_mission_fnc_addStagingZone
 * ["zone_staging", 12] call jmfsb_mission_fnc_addStagingZone
 * ["respawn_west", 12] call jmfsb_mission_fnc_addStagingZone
 * [[10,25,0], 12] call jmfsb_mission_fnc_addStagingZone
 * ["ShapedZoneMarker", "RECTANGLE"] call jmfsb_mission_fnc_addStagingZone
 * ["ShapedZoneMarker", "ELLIPSE"] call jmfsb_mission_fnc_addStagingZone
 * 
 * Public: Yes
 */

params [
    ["_zone", objNull, [objNull, "", []]],
    ["_size", 12, [0, ""]]
];

private _stagingZones = missionNamespace getVariable [QEGVAR(Staging,Zones), []];

// Position or Icon zone
if (_zone isEqualType []) exitWith {
    INFO("Staging","Creating postion type staging zone (Icon marker or Set position)");
    private _zoneSize = if (_size isEqualType 0) then {[_size,_size]} else {SHOW_CHAT_WARNING("Staging","Zone size <STRING> not valid for position type zones. Setting zone size to 12");[12, 12]};
    private _zonePos = _zone;
    private _zoneType = [];

    private _stagingZone = createMarkerLocal [format["YMF_staging_zone_%1", count _stagingZones], _zonePos];
    _stagingZone setMarkerShapeLocal "ELLIPSE";
    _stagingZone setMarkerSizeLocal _zoneSize;
    _stagingZone setMarkerBrushLocal "Border";
    _stagingZone setMarkerColorLocal "ColorOrange";

    _stagingZones append [[_stagingZone, _zoneSize, _zoneType]];
    missionNamespace setVariable [QEGVAR(Staging,Zones), _stagingZones];
    [_zonePos] call FUNC(stagingUplink);
};

// Shape marker zone
if (_zone isEqualType "") exitWith {
    INFO("Staging","Creating shape marker type staging zone");
    private _zoneSize = if (_size isEqualType 0) then {[_size, _size]} else {getMarkerSize _zone};
    private _zoneShape = _size;
    private _zonePos = markerPos _zone;
    private _zoneDir = markerDir _zone;
    private _zoneType = "";

    private _stagingZone = createMarkerLocal [format["YMF_staging_zone_%1", count _stagingZones], _zonePos];
    _stagingZone setMarkerShapeLocal _zoneShape;
    _stagingZone setMarkerSizeLocal _zoneSize;
    _stagingZone setMarkerDirLocal _zoneDir;
    _stagingZone setMarkerBrushLocal "Border";
    _stagingZone setMarkerColorLocal "ColorOrange";

    _stagingZones append [[_stagingZone, _zoneSize, _zoneType]];
    missionNamespace setVariable [QEGVAR(Staging,Zones), _stagingZones];
    [_zonePos] call FUNC(stagingUplink);
};

// Object type zone
if (_zone isEqualType objNull) exitWith {
    INFO("Staging","Creating vehicle type staging zone");
    private _zoneSize = if (_size isEqualType 0) then {[_size,_size]} else {SHOW_CHAT_WARNING("Staging","Zone size <STRING> not valid for position type zones. Setting zone size to 12");[12, 12]};
    private _zoneType = objNull;
    private _stagingZone = _zone;

    _stagingZones append [[_stagingZone, _zoneSize, _zoneType]];
    missionNamespace setVariable [QEGVAR(Staging,Zones), _stagingZones];
    [_zone] call FUNC(stagingUplink);
};

// EVERY BRANCH ABOVE exitWith-s. Reaching this line means _zone was none of
// the three supported types, so nothing was created and nothing can be.
ERROR_1("Staging","Staging zone %1 not created - unsupported zone type.",_zone);
