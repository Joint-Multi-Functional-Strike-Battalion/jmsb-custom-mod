#include "script_component.hpp"
/*
 * Author: YonV
 * A double-click on a device's map: place a marker there, through the
 * player's marker system (FUNC(markerOpen)) - the game's map does the same
 * with its own dialog (user, 2026-11-01: "map markers need to be able to
 * place map markers here").
 *
 * WHY THE TABLET NEEDED THIS. The engine opens its marker dialog for a
 * double-click on the game's own map display only. The tablet's screen is a
 * map control in a dialog of jmfsb_devices', and a double-click there reached
 * nothing at all - so no marker could be placed on the tablet.
 *
 * NOT ON THE GAME'S MAP. Display 12 opens the game's own dialog (ACE's when
 * ACE is loaded) without help; a second one from here would stack on it.
 *
 * NOT WHEN THE PRESS IS SOMEBODY ELSE'S: a map tool running takes the presses
 * (MARK makes its own markers), an app open or holding the map
 * (jmfsb_tacpad_appMapClaim) is the app's, and a double-click whose first
 * press closed an app began as the app's way out. Shift, ctrl and alt are the
 * game's own.
 *
 * Over a marker of his own the built-in card opens on that marker, to change
 * or delete it.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: Mouse button <NUMBER>
 * 2: Screen x <NUMBER>
 * 3: Screen y <NUMBER>
 * 4: Shift held <BOOL>
 * 5: Ctrl held <BOOL>
 * 6: Alt held <BOOL>
 *
 * Return Value:
 * The double-click was taken <BOOL>
 *
 * Example:
 * [_map, 0, 0.5, 0.5, false, false, false] call jmfsb_maptools_fnc_mapDblClick
 *
 * Public: No
 */

params ["_map", "_button", "_sx", "_sy", ["_shift", false], ["_ctrl", false], ["_alt", false]];

if (_button isNotEqualTo 0 || {_shift || _ctrl || _alt}) exitWith {false};
if ((ctrlIDD (ctrlParent _map)) isEqualTo IDD_MAP) exitWith {false};
if (GVAR(tool) isNotEqualTo "") exitWith {false};
if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isNotEqualTo "") exitWith {false};
if ((uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isNotEqualTo "") exitWith {false};
if (diag_tickTime - GVAR(closedTime) < DBLCLICK_GRACE) exitWith {false};

private _pos = _map ctrlMapScreenToWorld [_sx, _sy];

// A marker under the cursor: ctrlMapMouseOver names it only when the thing
// under the cursor is a marker, so the name is not read before that is known.
private _edit = "";
(ctrlMapMouseOver _map) params [["_kind", ""], ["_over", ""]];
if (_kind isEqualTo "marker") then {
    if ([_over] call FUNC(markerOwn)) then {
        _edit = _over;
    };
};

// THE GAME'S DEFAULT CHANNEL: the one the player is talking on, as the game's
// dialog picks it; the card falls back to GROUP where no marker can go.
[_map, _pos, "", currentChannel, _edit] call FUNC(markerOpen);

true
