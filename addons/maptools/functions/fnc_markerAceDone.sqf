#include "script_component.hpp"
/*
 * Author: YonV
 * ACE's marker dialog closing, for one FUNC(markerAce) opened. On OK, the
 * marker the engine would have made: through the one marker path,
 * FUNC(mark), with what ACE's dialog holds - icon, colour, point, text (ACE
 * has put its timestamp on the text by now) and the picked channel - and
 * then ACE's own network event, which sets angle and scale on every machine
 * and keeps the marker in ACE's store for players joining later.
 *
 * ACE ALSO LOOKS FOR THE MARKER, a frame after its dialog closes, among the
 * markers made since. Whether it finds this one depends on which of the two
 * unload handlers the engine runs first, so the network event is sent here
 * either way; when ACE does not find it, it says so in the RPT and nothing
 * else happens.
 *
 * A marker the engine made on its own (were a script-made dialog ever to have
 * the engine behind it) would be a second one: next frame, any new marker of
 * this player's that is not this one is deleted.
 *
 * Arguments:
 * 0: The dialog <DISPLAY>
 * 1: Exit code - 1 is OK <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_dialog, 1] call jmfsb_maptools_fnc_markerAceDone
 *
 * Public: No
 */

params [["_dialog", displayNull, [displayNull]], ["_exit", 0, [0]]];

if (_dialog isNotEqualTo (uiNamespace getVariable [QGVAR(aceDialog), displayNull])) exitWith {};

(uiNamespace getVariable [QGVAR(acePending), []]) params [["_pos", []], ["_channel", MARK_CHANNEL], ["_before", []]];
uiNamespace setVariable [QGVAR(aceDialog), displayNull];
uiNamespace setVariable [QGVAR(acePending), []];

if (_exit isNotEqualTo ACE_EXIT_OK) exitWith {};

private _type = missionNamespace getVariable [ACE_MARKER_TYPE, MARK_TYPE];
private _color = missionNamespace getVariable [ACE_MARKER_COLOR, MARK_COLOR];
private _dir = missionNamespace getVariable [ACE_MARKER_DIR, 0];
private _scale = missionNamespace getVariable [ACE_MARKER_SCALE, 1];
private _at = missionNamespace getVariable [ACE_MARKER_POS, []];
if (_at isEqualTo []) then {
    _at = _pos;
};
if (_at isEqualTo []) exitWith {};

// The picked channel, as the list carries it (its data is the channel id);
// a channel no marker can go on now falls back to GROUP.
private _list = _dialog displayCtrl IDC_INSERT_MARKER_CHANNELS;
private _row = lbCurSel _list;
if (_row >= 0) then {
    _channel = parseNumber (_list lbData _row);
};
private _ids = ([] call FUNC(markerChannels)) apply {_x # 0};
if (!(_channel in _ids) || _channel isEqualTo MARKER_CHANNEL_LOCAL) then {
    _channel = MARK_CHANNEL;
};

private _text = ctrlText (_dialog displayCtrl IDC_INSERT_MARKER);
private _marker = [_at, _type, _color, _text, _channel] call FUNC(mark);
if (_marker isEqualTo "") exitWith {};

[ACE_SET_MARKER_EVENT, [_marker, [_type, _color, _at, _dir, _scale]]] call CBA_fnc_globalEvent;

[{
    params ["_before", "_marker"];
    {
        if (_x isNotEqualTo _marker) then {
            if ([_x] call FUNC(markerOwn)) then {
                deleteMarker _x;
            };
        };
    } forEach (allMapMarkers - _before);
}, [_before, _marker]] call CBA_fnc_execNextFrame;
