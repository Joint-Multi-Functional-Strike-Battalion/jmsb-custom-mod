#include "script_component.hpp"
/*
 * Author: YonV
 * Radar-and-launcher batteries for one conventional commander.
 *
 * OPEN GROUND, AND ONLY OPEN GROUND. A radar in a wood sees nothing and a
 * launcher in a street is a decoration, so the clear radius is deliberately
 * large and the slope limit tight. If a map cannot satisfy that, the site is
 * skipped and said so - a battery standing in a hedge is worse than none.
 *
 * IN THE TAOR, AND ONLY THE TAOR. The site is checked after it is chosen, not
 * just the objective it grew from: findSite searches a ring around a centre,
 * so an objective near a boundary will happily offer ground on the far side of
 * it.
 *
 * Arguments:
 * 0: The side <SIDE>
 * 1: Its objectives, biggest first <ARRAY>
 * 2: Its TAOR markers <ARRAY>
 * 3: Markers never to build on <ARRAY>
 * 4: [radar, launchers, manpad, mag] <ARRAY>
 * 5: Sites already placed this run, to stand clear of <ARRAY>
 * 6: The commander's faction, for who mans the guards <STRING>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_side", sideUnknown, [sideUnknown]], ["_objs", [], [[]]],
        ["_taor", [], [[]]], ["_black", [], [[]]],
        ["_kit", [], [[]]], ["_placed", [], [[]]], ["_faction", "", [""]]];

_kit params ["_radar", "_launchers"];

if (_radar isEqualTo "" || {_launchers isEqualTo []}) exitWith {
    WARNING_1("side %1 has no radar or launcher class available - no batteries",_side);
};

private _want = round GVAR(sitesPerSide);
if (_want <= 0) exitWith {};

private _clear = 6 max GVAR(openGround);
private _built = 0;

// Who mans the guards, if any are asked for. Resolved once per side rather
// than per site - it is a sweep of every class in the mission.
private _kinds = [];
if (GVAR(security) > 0) then {
    _kinds = [_faction, _side] call FUNC(factionMen);
};

{
    if (_built >= _want) exitWith {};
    _x params ["", "_pos", "_size"];

    private _spots = [[], 1, createHashMapFromArray [
        ["centre", _pos],
        // Off the objective itself: a battery sits where it can see, not in
        // the middle of the thing everyone is already fighting over.
        ["minRange", 200],
        ["maxRange", (_size max 600) min 1500],
        ["footprint", 12],
        ["clearRadius", _clear],
        // A radar wants to be level. Anything steep and it stares at a hill.
        ["maxSlope", 0.10],
        ["separation", GVAR(spacing)],
        ["avoid", _placed],
        ["avoidRadius", GVAR(spacing)],
        ["blacklist", _black]
    ]] call EFUNC(common,findSite);

    if (_spots isEqualTo []) then {
        TRACE_2("no open ground for a battery",_side,mapGridPosition _pos);
        continue;
    };

    private _at = _spots select 0;

    if (_taor isNotEqualTo [] && {(_taor findIf {_at inArea _x}) < 0}) then {
        TRACE_2("battery spot fell outside its own TAOR - skipped",_side,mapGridPosition _at);
        continue;
    };

    if !([_at, _side, _kit, _taor, _black, _kinds] call FUNC(buildBattery)) then {continue};

    _placed pushBack _at;
    _built = _built + 1;
} forEach _objs;

INFO_2("side %1: %2 air-defence batter(y/ies)",_side,_built);
