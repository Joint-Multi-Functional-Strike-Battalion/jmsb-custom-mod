#include "script_component.hpp"
/*
 * Author: YonV
 * Opens the built-in marker card at a point: what the game's own marker dialog
 * offers - icon, text, channel - and a colour, drawn with the tacpad's own
 * vocabulary on whichever host the map is on (user, 2026-11-01: "built in or
 * suggest something better").
 *
 * WHY OUR OWN CARD AND NOT THE GAME'S DIALOG. The engine opens its insert-marker
 * dialog for a double-click on its own map display and nowhere else, and there
 * is no command that opens it at a point. A copy made from script
 * (createDisplay "RscDisplayInsertMarker") is the dialog's controls with no
 * engine behind them: the channel list is filled by the engine, and so is the
 * marker its OK makes. So the card makes the marker itself, through the same
 * player-marker path as everything else (FUNC(mark)) - a marker the game's map
 * then edits and deletes like one it made.
 *
 * The state lives in uiNamespace (QGVAR(cardState)), because the card is
 * rebuilt on every pick and the map control cannot be stored anywhere else.
 * The icon and colour picked last are offered first next time, on the tab
 * that holds the icon (FUNC(markerCardIcons)); size and direction start at
 * normal and north (2026-11-02).
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: World position <ARRAY>
 * 2: The text it opens with <STRING> (optional, default "")
 * 3: The channel it opens on - an engine channel id, or -1 for this player's
 *    map only <NUMBER> (optional, default MARK_CHANNEL)
 * 4: A marker of this player's to change, "" for a new one <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map, _pos, "", currentChannel] call jmfsb_maptools_fnc_markerCard
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

if (isNull _map || count _pos < 2) exitWith {};

private _type = uiNamespace getVariable [QGVAR(cardType), MARK_TYPE];
private _color = uiNamespace getVariable [QGVAR(cardColor), MARK_COLOR];
private _size = CARD_SIZE_NORMAL;
private _dir = 0;

// A MARKER OF HIS OWN opens as it stands: where it is, what it looks like,
// how big and which way it points, what it says and where it went out - the
// channel is the last part of its name, and one on CLEAR's list is a MY MAP
// marker.
if (_edit isNotEqualTo "") then {
    _pos = markerPos _edit;
    _type = markerType _edit;
    _color = markerColor _edit;
    _size = (markerSize _edit) # 0;
    _dir = markerDir _edit;
    _text = markerText _edit;
    _channel = if (_edit in GVAR(marks)) then {
        MARKER_CHANNEL_LOCAL
    } else {
        parseNumber ((_edit splitString "/") param [2, str MARK_CHANNEL])
    };
};

// A channel no marker can go on now - DIRECT, a disabled one, VEHICLE on foot
// - opens on GROUP, and on MY MAP when even that is shut.
private _ids = ([] call FUNC(markerChannels)) apply {_x # 0};
if !(_channel in _ids) then {
    _channel = [MARKER_CHANNEL_LOCAL, MARK_CHANNEL] select (MARK_CHANNEL in _ids);
};

uiNamespace setVariable [QGVAR(cardState), createHashMapFromArray [
    ["map", _map],
    ["pos", [_pos # 0, _pos # 1, 0]],
    ["type", _type],
    ["color", _color],
    ["size", _size],
    ["dir", _dir],
    ["text", _text],
    ["channel", _channel],
    ["edit", _edit]
]];

[] call FUNC(markerCardDraw);
