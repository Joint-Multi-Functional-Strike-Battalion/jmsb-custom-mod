#include "script_component.hpp"
/*
 * Author: YonV
 * Places a map marker at the point the player is aiming at through one of the
 * [JMSB] Vector Designators. Marker type, colour and lifetime come from CBA settings.
 * Called from the CBA keybind added in initKeybinds.inc.sqf.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * call jmfsb_equipment_fnc_placeTargetMarker
 */

if (!GVAR(markerEnabled)) exitWith {false};
if (isNull ACE_player || {!alive ACE_player}) exitWith {false};
if !(currentWeapon ACE_player in VECTOR_DESIGNATORS) exitWith {false};

// THE RAYCAST IS SHARED with the personal waypoint - see FUNC(vectorTarget).
// Two copies of a line-of-sight test are two copies that can disagree about what
// the target is, one taking a building face and the other the ground behind it.
([] call FUNC(vectorTarget)) params ["_posASL", "_distance"];

if (_posASL isEqualTo []) exitWith {
    ["Vector", "No target.", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify);
    true
};

GVAR(markerIndex) = GVAR(markerIndex) + 1;
private _markerName = format [QGVAR(marker_%1_%2), clientOwner, GVAR(markerIndex)];

private _marker = createMarker [_markerName, ASLToAGL _posASL];
_marker setMarkerTypeLocal GVAR(markerType);
_marker setMarkerColorLocal GVAR(markerColor);
_marker setMarkerText format ["%1 (%2m)", name ACE_player, _distance]; // last update global to broadcast the full marker

if (GVAR(markerDuration) > 0) then {
    [{deleteMarker _this}, _marker, GVAR(markerDuration)] call CBA_fnc_waitAndExecute;
};

// In-world 3D marker name on every client (each client checks its own
// setting). By the server, which names the sender itself (review R1: the
// marker3D CBA event let any client put any text anywhere on every screen).
if (GVAR(marker3DDuration) > 0) then {
    [_posASL, _distance, GVAR(markerColor)] remoteExecCall [QFUNC(srvMarker3D), SERVER_OWNER];
};

["Vector", format ["Marker placed: %1 m", _distance], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);

true
