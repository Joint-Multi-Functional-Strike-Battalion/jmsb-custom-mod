#include "script_component.hpp"
/*
 * Author: YonV
 * The map markers a grid field can be filled from, nearest first.
 *
 * A location on a report is nearly always somewhere already marked - the LZ, the
 * objective, the rally - and typing a grid off the map by hand is where a digit
 * gets dropped. This is the list behind the MARKER button.
 *
 * ONLY PLAYER-PLACED MARKERS are offered - the user's rule for every marker
 * list in the suite. Editor zones, TAOR areas, module art and the suite's
 * own jmfsb_* overlays are all out wholesale by the same test.
 *
 * Arguments:
 * 0: Maximum returned <NUMBER> (optional, default 12)
 *
 * Return Value:
 * [[label, position], ...] <ARRAY>
 *
 * Example:
 * [8] call jmfsb_tacpad_fnc_markerGrids
 *
 * Public: No
 */

params [["_limit", 12, [0]]];

private _at = getPosATL player;
private _found = [];

{
    private _name = _x;

    // ONLY MARKERS A PLAYER PLACED - the engine names every one of them
    // "_USER_DEFINED #...". Editor zones, module art and the suite's own
    // overlays are out wholesale (the user's rule), and other sides' pen
    // work never reaches this client's marker list to begin with. No
    // colour filtering: a mate marking a contact in red is exactly the
    // marker a report wants.
    if ((_name select [0, 13]) isNotEqualTo "_USER_DEFINED") then {continue};

    // A zone a player drew and labelled TAOR is still a zone.
    if ("taor" in toLower markerText _name) then {continue};

    private _pos = getMarkerPos _name;
    if (_pos isEqualTo [0, 0, 0]) then {continue};

    private _label = markerText _name;
    if (_label isEqualTo "") then {_label = "PLACED MARKER"};

    _found pushBack [_at distance2D _pos, _label, _pos];
} forEach allMapMarkers;

_found sort true;

(_found apply {[_x # 1, _x # 2]}) select [0, _limit]
