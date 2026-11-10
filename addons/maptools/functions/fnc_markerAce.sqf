#include "script_component.hpp"
/*
 * Author: YonV
 * Opens ACE's marker dialog at a point, on the display the map is on - the
 * marker system "ACE" (user, 2026-11-01).
 *
 * ACE'S DIALOG IS THE GAME'S, REBUILT. ace_markers replaces the onLoad of the
 * game's insert-marker display (RscDisplayInsertMarker) with its own set-up -
 * icon, colour, angle, scale, timestamp - and reads its map off the display
 * under it at the map's idc, 51, which is the tablet's map idc on purpose.
 * Made from script as a child of the host display, the dialog is ACE's whole
 * dialog over the tablet's map.
 *
 * What the engine does not do for a dialog made from script is done here: the
 * point is put where the press was (FUNC(markerAceInit) - ACE takes it from
 * where the engine would have put the dialog), the channel list is filled
 * when the engine left it empty, and the marker is made on OK
 * (FUNC(markerAceDone)).
 *
 * ACE draws its preview through a Draw handler it hangs once per display idd.
 * The tablet is a new map control each time it opens with the same idd, so a
 * tablet opened again gets the handler from here.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: World position <ARRAY>
 * 2: The channel the list opens on, an engine channel id <NUMBER>
 *
 * Return Value:
 * The dialog opened <BOOL> - false without ace_markers
 *
 * Example:
 * [_map, _pos, currentChannel] call jmfsb_maptools_fnc_markerAce
 *
 * Public: No
 */

params [["_map", controlNull, [controlNull]], ["_pos", [], [[]]], ["_channel", MARK_CHANNEL, [0]]];

if !(MARKERS_HAS_ACE) exitWith {false};

private _display = ctrlParent _map;
if (isNull _display) exitWith {false};

if ((ctrlIDD _display) isNotEqualTo IDD_MAP) then {
    if (((ctrlIDD _display) in (missionNamespace getVariable [ACE_DRAW_IDDS, []])) && !(_map getVariable [QGVAR(aceDraw), false])) then {
        _map ctrlAddEventHandler ["Draw", {call ace_markers_fnc_mapDrawEH}];
    };
    _map setVariable [QGVAR(aceDraw), true];
};

private _dialog = _display createDisplay ACE_INSERT_DISPLAY;
if (isNull _dialog) exitWith {false};

uiNamespace setVariable [QGVAR(aceDialog), _dialog];
uiNamespace setVariable [QGVAR(acePending), [[_pos # 0, _pos # 1, 0], _channel, allMapMarkers]];

_dialog displayAddEventHandler ["Unload", {_this call FUNC(markerAceDone)}];

true
