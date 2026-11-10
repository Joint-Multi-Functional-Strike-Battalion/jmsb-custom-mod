#include "script_component.hpp"
/*
 * Author: YonV
 * Opens ALiVE's Advanced Marker dialog at a point: the marker system "ALiVE"
 * of jmfsb_maptools (user, 2026-11-01), for a double-click on a device's map
 * and a MAP TOOLS MARK press. Client side.
 *
 * ALiVE OPENS IT ITSELF ON THE GAME'S MAP ONLY: a ctrl+alt press on display 12
 * (its sys_marker checks the display by name and says "Add Marker Not
 * Available" anywhere else). The dialog reads its point from uiNamespace
 * (ALiVE_SYS_marker_pos) and whether it is editing from ALiVE_SYS_marker_edit,
 * so both are set here and the dialog is opened over whatever is open - the
 * tablet's dialog included. ALiVE's own OK makes and stores the marker.
 *
 * A NEW MARKER ONLY. ALiVE finds a marker to edit by measuring against the
 * game's map's zoom; changing or deleting one stays ALiVE's own ctrl+alt
 * press on the game's map - or a MARK press on it (FUNC(markerRemove)).
 *
 * Arguments:
 * 0: World position <ARRAY>
 *
 * Return Value:
 * The dialog opened <BOOL> - false when the mission has no ALiVE Advanced
 * Markers module (there is nothing to store the marker in)
 *
 * Example:
 * [_pos] call jmfsb_adapter_alive_fnc_markerOpen
 *
 * Public: Yes
 */

// ALiVE's Advanced Marker dialog (sys_marker, data\ui\main.hpp).
#define ALIVE_MARKER_DIALOG "RscDisplayALiVEAdvancedMarker"

params [["_pos", [], [[]]]];

if (!hasInterface) exitWith {false};
if (count _pos < 2) exitWith {false};
if (isNil "ALiVE_SYS_marker") exitWith {false};
if (isNil "ALiVE_fnc_markerOnLoad") exitWith {false};

uiNamespace setVariable ["ALiVE_SYS_marker_pos", [_pos # 0, _pos # 1, 0]];
uiNamespace setVariable ["ALiVE_SYS_marker_edit", false];

createDialog ALIVE_MARKER_DIALOG
