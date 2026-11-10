#include "script_component.hpp"
/*
 * Author: YonV
 * MANPAD teams for one asymmetric commander.
 *
 * A guerrilla does not field a battery. Two or three men with a launcher,
 * placed off the objective where they can see the approach, is both what an
 * insurgency actually does and the thing players can plausibly hunt - a radar
 * site would be a fortress they have no answer to.
 *
 * They do NOT need open ground. A shooter wants cover; only the sky above him
 * has to be clear, and there is no way to stand under a tree and still be
 * usable to a pilot's eye anyway.
 *
 * Arguments:
 * 0: The side <SIDE>
 * 1: Its objectives, biggest first <ARRAY>
 * 2: Its TAOR markers <ARRAY>
 * 3: Markers never to build on <ARRAY>
 * 4: [radar, launchers, manpad, mag] <ARRAY>
 * 5: The commander's faction, for who mans the teams <STRING>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_side", sideUnknown, [sideUnknown]], ["_objs", [], [[]]],
        ["_taor", [], [[]]], ["_black", [], [[]]], ["_kit", [], [[]]],
        ["_faction", "", [""]]];

_kit params ["", "", "_weapon", "_mag", ["_men", []]];

if (_weapon isEqualTo "") exitWith {
    WARNING_1("side %1 has no MANPAD launcher available - no teams",_side);
};

private _want = round GVAR(teamsPerSide);
if (_want <= 0) exitWith {};

// The mission's named man classes win; the faction's own men otherwise.
private _kinds = if (_men isNotEqualTo []) then {_men} else {
    [_faction, _side] call FUNC(factionMen)
};

// Spread over the objectives rather than stacked on the biggest few: the point
// is that a corridor is covered, not that one town is impassable.
private _made = 0;
private _placedTeams = [];

for "_i" from 0 to (_want - 1) do {
    private _obj = _objs select (_i mod count _objs);
    _obj params ["", "_pos"];

    private _spots = [[], 1, createHashMapFromArray [
        ["centre", _pos],
        ["minRange", AD_TEAM_MIN_R],
        ["maxRange", AD_TEAM_MAX_R],
        ["footprint", 3],
        ["clearRadius", 3],
        ["separation", 300],
        ["avoid", _placedTeams],
        ["avoidRadius", 300],
        ["blacklist", _black]
    ]] call EFUNC(common,findSite);

    if (_spots isEqualTo []) then {continue};

    private _at = _spots select 0;
    if (_taor isNotEqualTo [] && {(_taor findIf {_at inArea _x}) < 0}) then {continue};

    if !([_at, _side, _weapon, _mag, _kinds] call FUNC(buildTeam)) then {continue};

    _placedTeams pushBack _at;
    _made = _made + 1;
};

INFO_2("side %1: %2 MANPAD team(s)",_side,_made);
