#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a marker on the map: the one place every jmfsb map marker is made - the
 * marker card's PLACE, ACE's dialog opened on a device's map, and anything that
 * calls this with a point alone, which gets MARK's old drop: a dot labelled
 * with the ten-digit grid and the time.
 *
 * THE GAME'S OWN MARKER PATH, not a new one. It is made through
 * EFUNC(common,createPlayerMarker), so it is an ordinary player marker - named
 * the way the engine names them, owned by this player, on its channel - which
 * the vanilla map deletes and edits like any other, and which TAC//MSG's
 * MAP MARKER list (EFUNC(tacpad,markerGrids)) offers like any other.
 *
 * MY MAP (MARKER_CHANNEL_LOCAL) keeps it local: filed on the group channel and
 * never sent, so CLEAR can take it back. Any other channel sends it: the last
 * setter is the global one, which is what puts a local marker out on its
 * channel - only the players on that channel see it.
 *
 * Arguments:
 * 0: World position <ARRAY>
 * 1: Marker type, a CfgMarkers class <STRING> (optional, default MARK_TYPE)
 * 2: Marker colour, a CfgMarkerColors class <STRING> (optional, default MARK_COLOR)
 * 3: Text <STRING> (optional, default the grid and the time)
 * 4: Channel - an engine channel id, or -1 for this player's map only <NUMBER>
 *    (optional, default the group channel when QGVAR(markShare) is on, else -1)
 * 5: Size, markerSize on both axes <NUMBER> (optional, default 1) - the card's
 *    S / M / L (2026-11-02)
 * 6: Direction, degrees <NUMBER> (optional, default 0)
 *
 * Return Value:
 * The marker, "" when none was made <STRING>
 *
 * Example:
 * [getPosATL player] call jmfsb_maptools_fnc_mark
 * [_pos, "o_inf", "ColorRed", "ENEMY SECTION", 1] call jmfsb_maptools_fnc_mark
 *
 * Public: Yes
 */

params [
    ["_pos", [], [[]]],
    ["_type", MARK_TYPE, [""]],
    ["_color", MARK_COLOR, [""]],
    ["_text", nil, [""]],
    ["_channel", nil, [0]],
    ["_size", CARD_SIZE_NORMAL, [0]],
    ["_dir", 0, [0]]
];

if (count _pos < 2) exitWith {""};

if (isNil "_text") then {
    _text = [_pos] call FUNC(markLabel);
};
if (isNil "_channel") then {
    _channel = [MARKER_CHANNEL_LOCAL, MARK_CHANNEL] select GVAR(markShare);
};

private _local = _channel isEqualTo MARKER_CHANNEL_LOCAL;

private _marker = [[_pos # 0, _pos # 1, 0], [_channel, MARK_CHANNEL] select _local] call EFUNC(common,createPlayerMarker);
if (_marker isEqualTo "") exitWith {""};

_marker setMarkerShapeLocal "ICON";
_marker setMarkerTypeLocal _type;
_marker setMarkerColorLocal _color;
_marker setMarkerSizeLocal [_size, _size];
_marker setMarkerDirLocal _dir;

if (_local) then {
    _marker setMarkerTextLocal _text;
    GVAR(marks) pushBack _marker;
} else {
    _marker setMarkerText _text;
};

_marker
