#include "script_component.hpp"
/*
 * Author: YonV
 * A press on a map with a tool running - the one place a click becomes a
 * measurement. Left button only, and never with a modifier held: shift, ctrl
 * and alt clicks are the game's own (waypoints, drawn lines).
 *
 *   RULER       the first press anchors; a second press, or the release of a
 *               drag (FUNC(mouseUp)), is the other end
 *   PROTRACTOR  places the centre; the arm follows the cursor until the next
 *               press locks it; the press after that places a new centre
 *   MARK        opens the player's marker system here (FUNC(markerOpen)),
 *               grid and time as the text; on a marker of his own, deletes
 *               it (FUNC(markerDelete))
 *   VIEWSHED    works out line of sight from here (FUNC(viewshedStart))
 *   ROUTE       adds a waypoint
 *   RINGS       places the rings' centre
 *   LOS         the first press is where you look from; the second where
 *               you look to (FUNC(losCheck))
 *   GRID        reads, takes no press
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
 * The press was a tool's <BOOL>
 *
 * Example:
 * [_map, 0, 0.5, 0.5, false, false, false] call jmfsb_maptools_fnc_mouseDown
 *
 * Public: No
 */

params ["_map", "_button", "_sx", "_sy", ["_shift", false], ["_ctrl", false], ["_alt", false]];

if (_button isNotEqualTo 0 || {_shift || _ctrl || _alt}) exitWith {false};
if !([] call FUNC(hasInput)) exitWith {false};

private _pos = _map ctrlMapScreenToWorld [_sx, _sy];
uiNamespace setVariable [QGVAR(pressMap), controlNull];

switch (GVAR(tool)) do {
    case TOOL_RULER: {
        if (GVAR(anchor) isEqualTo []) then {
            GVAR(anchor) = _pos;
            GVAR(ruler) = [];
            uiNamespace setVariable [QGVAR(pressMap), _map];
        } else {
            GVAR(ruler) = [GVAR(anchor), _pos];
            GVAR(anchor) = [];
        };
    };
    case TOOL_PROTRACTOR: {
        GVAR(protractor) params [["_centre", []], ["_arm", -1]];
        GVAR(protractor) = if (_centre isNotEqualTo [] && _arm < 0) then {
            [_centre, _centre getDir _pos]
        } else {
            [_pos, -1]
        };
    };
    // ONE PLACEMENT PATH WITH THE DOUBLE-CLICK (user, 2026-11-01): the
    // player's marker system opens at the press - the card, ACE's dialog or
    // ALiVE's - so a MARK is a real marker on the channel he picks. A press
    // on a marker of his own deletes it, as the game's map does on Delete.
    case TOOL_MARK: {
        (ctrlMapMouseOver _map) params [["_kind", ""], ["_over", ""]];
        private _deleted = false;
        if (_kind isEqualTo "marker") then {
            _deleted = [_over] call FUNC(markerDelete);
        };
        if (!_deleted) then {
            [_map, _pos, [_pos] call FUNC(markLabel), [MARKER_CHANNEL_LOCAL, MARK_CHANNEL] select GVAR(markShare)] call FUNC(markerOpen);
        };
    };
    case TOOL_VIEWSHED: {
        [_pos] call FUNC(viewshedStart);
    };
    case TOOL_ROUTE: {
        GVAR(route) pushBack _pos;
    };
    case TOOL_RINGS: {
        GVAR(rings) = _pos;
    };
    case TOOL_LOS: {
        if (GVAR(losFrom) isEqualTo []) then {
            GVAR(losFrom) = _pos;
            GVAR(los) = [];
        } else {
            GVAR(los) = [GVAR(losFrom), _pos] + ([GVAR(losFrom), _pos] call FUNC(losCheck));
            GVAR(losFrom) = [];
        };
    };
    default {};
};

true
