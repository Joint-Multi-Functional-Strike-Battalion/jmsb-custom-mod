#include "script_component.hpp"
/*
 * Author: YonV
 * THE ONE PLACEMENT PATH (user, 2026-11-01): a double-click on a device's map
 * and a MARK press both come here, and the player's marker system
 * (QGVAR(markerSystem)) says what opens at the point:
 *
 *   Built-in  the marker card (FUNC(markerCard)) - icon, colour, text, channel
 *   ACE       ACE's marker dialog (FUNC(markerAce)), when ace_markers is loaded
 *   ALiVE     ALiVE's Advanced Marker dialog, through jmfsb_adapter_alive only,
 *             when ALiVE is loaded and its Advanced Markers module is in the
 *             mission
 *
 * A system that cannot open - not loaded, no module, no dialog - falls back to
 * the card, so a press always gets the player a marker.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: World position <ARRAY>
 * 2: The text the card opens with <STRING> (optional, default "")
 * 3: The channel the card and ACE's list open on - an engine channel id, or
 *    -1 for this player's map only <NUMBER> (optional, default MARK_CHANNEL)
 * 4: A marker of this player's to change, "" for a new one <STRING> (optional, default "")
 *
 * Return Value:
 * The system that opened: "builtin", "ace", "alive"; "" for none <STRING>
 *
 * Example:
 * [_map, _pos, "", currentChannel] call jmfsb_maptools_fnc_markerOpen
 *
 * Public: No
 */

params [
    ["_map", controlNull, [controlNull]],
    ["_pos", [], [[]]],
    ["_text", "", [""]],
    ["_channel", MARK_CHANNEL, [0]],
    ["_edit", "", [""]]
];

if (isNull _map || count _pos < 2) exitWith {""};

[] call FUNC(markerCardClose);

private _system = GVAR(markerSystem);
private _opened = switch (_system) do {
    case MARKERS_ACE: {[_map, _pos, _channel] call FUNC(markerAce)};
    case MARKERS_ALIVE: {
        if (isNil QEFUNC(adapter_alive,markerOpen)) then {false} else {[_pos] call EFUNC(adapter_alive,markerOpen)}
    };
    default {false};
};
if (_opened) exitWith {_system};

[_map, _pos, _text, _channel, _edit] call FUNC(markerCard);

MARKERS_BUILTIN
