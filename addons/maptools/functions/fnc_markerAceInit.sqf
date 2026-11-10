#include "script_component.hpp"
/*
 * Author: YonV
 * ACE's marker dialog has set itself up (its ace_markers_editingMarker event):
 * for a dialog FUNC(markerAce) opened, puts right what the engine would have.
 *
 *   THE POINT. ACE takes it from the middle of the dialog's marker picture,
 *   which the engine moves under the cursor on its own map; a dialog made
 *   from script has the picture where its config left it. The press is the
 *   point - unless ACE is editing a marker, which keeps its own place.
 *
 *   THE CHANNELS. The engine fills the list, not ACE; one made from script
 *   may come up empty. Filled here as the engine would, by the engine's own
 *   channel names, which is how ACE matches them.
 *
 * Arguments:
 * 0: The marker ACE is editing, "" for a new one <STRING>
 * 1: The dialog <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["", _dialog] call jmfsb_maptools_fnc_markerAceInit
 *
 * Public: No
 */

params [["_editing", "", [""]], ["_dialog", displayNull, [displayNull]]];

if (isNull _dialog) exitWith {};
if (_dialog isNotEqualTo (uiNamespace getVariable [QGVAR(aceDialog), displayNull])) exitWith {};

(uiNamespace getVariable [QGVAR(acePending), []]) params [["_pos", []], ["_channel", MARK_CHANNEL]];

if (_editing isEqualTo "" && _pos isNotEqualTo []) then {
    missionNamespace setVariable [ACE_MARKER_POS, _pos];
};

if (!isMultiplayer) exitWith {};

private _list = _dialog displayCtrl IDC_INSERT_MARKER_CHANNELS;
if (lbSize _list > 0) exitWith {};

{
    _x params ["_id"];
    if (_id isNotEqualTo MARKER_CHANNEL_LOCAL) then {
        private _row = _list lbAdd localize (MARKER_CHANNEL_STRINGS # _id);
        _list lbSetData [_row, str _id];
        if (_id isEqualTo _channel) then {
            _list lbSetCurSel _row;
        };
    };
} forEach ([] call FUNC(markerChannels));

if (lbCurSel _list < 0 && lbSize _list > 0) then {
    _list lbSetCurSel 0;
};
