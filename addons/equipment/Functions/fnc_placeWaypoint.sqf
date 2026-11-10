#include "script_component.hpp"
/*
 * Author: YonV
 * Drops a personal waypoint on whatever the Vector is looking at.
 *
 * PERSONAL MEANS LOCAL, AND THAT IS THE WHOLE POINT OF IT BESIDE THE TARGET
 * MARKER. The target marker is a report - it goes to everybody and it stays.
 * This is a note to yourself: nobody else sees it, it costs the section's map
 * nothing, and you can drop one on every corner of a route without filling
 * their screen with your working.
 *
 * ONE AT A TIME. A man navigating has one place he is going to. Dropping a
 * second moves the first rather than adding to it, which also means the key
 * never needs a delete of its own.
 *
 * AIMING AT IT AGAIN CLEARS IT. Within fifteen metres counts as the same place -
 * a toggle a man can actually hit through a rangefinder at four hundred metres.
 * Pressing with nothing in view clears it too, which is the fallback for a
 * waypoint set somewhere you can no longer see.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * call jmfsb_equipment_fnc_placeWaypoint
 */

if (!GVAR(waypointEnabled)) exitWith {false};
if (isNull ACE_player || {!alive ACE_player}) exitWith {false};
if !(currentWeapon ACE_player in [QGVAR(Vector_Designator), QGVAR(Vector_Designator_NVG)]) exitWith {false};

private _marker = QGVAR(waypoint);
private _existing = markerShape _marker isNotEqualTo "";

([] call FUNC(vectorTarget)) params ["_posASL", "_range"];

if (_posASL isEqualTo []) exitWith {
    if (_existing) then {
        deleteMarkerLocal _marker;
        ["Vector", "Waypoint cleared.", [0.871, 0.361, 0.188, 1]] call EFUNC(notify,notify);
    } else {
        ["Vector", "No target.", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify);
    };
    true
};

private _at = ASLToAGL _posASL;

// The same place again is the toggle - see the note above.
if (_existing && {(getMarkerPos _marker) distance2D _at < 15}) exitWith {
    deleteMarkerLocal _marker;
    ["Vector", "Waypoint cleared.", [0.871, 0.361, 0.188, 1]] call EFUNC(notify,notify);
    true
};

if (!_existing) then {
    createMarkerLocal [_marker, _at];
} else {
    _marker setMarkerPosLocal _at;
};

_marker setMarkerTypeLocal GVAR(waypointType);
_marker setMarkerColorLocal GVAR(waypointColor);

// Range and bearing, because a waypoint you cannot call out is a waypoint you
// cannot share by voice - which is the only way this one gets shared at all.
private _bearing = round (ACE_player getDir _at);
_marker setMarkerTextLocal format ["WP %1m / %2", _range, [_bearing, 3] call CBA_fnc_formatNumber];

["Vector", format ["Waypoint: %1 m, bearing %2", _range, [_bearing, 3] call CBA_fnc_formatNumber], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);

true
