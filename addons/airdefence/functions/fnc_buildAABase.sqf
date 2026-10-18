#include "script_component.hpp"
/*
 * Author: JMSB
 * Builds one AA base inside a module's area: the radar at the centre, SAM
 * launchers on an outer ring, AA guns on an inner ring as point defence, and
 * guards standing off the lot.
 *
 * TWO RULES FOR TWO KINDS OF THING. The hardware and its crews stay LIVE and
 * out of ALiVE (FUNC(crewSite)) - profiling static AA deletes it and it came
 * back crewless. The guards are infantry with ground to walk and ARE profiled
 * (FUNC(profileGuards)), so they cost nothing while nobody is near.
 *
 * Every ring is a fraction of the area's radius, and every spot must also fall
 * inside the area itself - an ellipse or rectangle as the mission maker drew it.
 *
 * Arguments:
 * 0: Centre, AGL <ARRAY>
 * 1: Module area [a, b, angle, isRectangle] <ARRAY>
 * 2: Owning side <SIDE>
 * 3: Radar class, "" for none <STRING>
 * 4: Missile launcher classes <ARRAY>
 * 5: How many launchers <NUMBER>
 * 6: AA gun classes <ARRAY>
 * 7: How many guns <NUMBER>
 * 8: Guard groups <NUMBER>
 * 9: Man classes for guards and manned statics <ARRAY>
 *
 * Return Value:
 * It was built <BOOL>
 *
 * Example:
 * [_pos, [300, 300, 0, false], east, "O_Radar_System_02_F", ["O_SAM_System_04_F"], 3, [], 0, 1, _kinds] call jmfsb_airdefence_fnc_buildAABase
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_area", [], [[]]], ["_side", sideUnknown, [sideUnknown]],
        ["_radarCls", "", [""]], ["_missiles", [], [[]]], ["_missileCount", 0, [0]],
        ["_guns", [], [[]]], ["_gunCount", 0, [0]], ["_guards", 0, [0]], ["_kinds", [], [[]]]];

_area params [["_a", 0, [0]], ["_b", 0, [0]], ["_angle", 0, [0]], ["_isRect", false, [false]]];

// An unset or tiny area is lifted to the floor, so the rings never collapse
// onto the radar; the area the spots must fall in is lifted with it.
private _radius = (_a max _b) max AB_RADIUS_MIN;
private _zone = [_pos, _a max AB_RADIUS_MIN, _b max AB_RADIUS_MIN, _angle, _isRect];

// findSite draws on a circle; anything off an ellipse or rectangle is dropped.
private _fnc_ring = {
    params ["_want", "_minR", "_maxR", "_foot", "_sep", "_avoid", "_avoidR"];
    if (_want <= 0) exitWith {[]};
    private _spots = [[], _want, createHashMapFromArray [
        ["centre", _pos],
        ["minRange", _minR],
        ["maxRange", _maxR],
        ["footprint", _foot],
        ["clearRadius", AB_CLEAR],
        ["maxSlope", AB_SLOPE],
        ["separation", _sep],
        ["avoid", _avoid],
        ["avoidRadius", _avoidR]
    ]] call EFUNC(common,findSite);
    _spots select {_x inArea _zone}
};

private _made = [];

// --- the radar, where the module stands ----------------------------------
if (_radarCls isNotEqualTo "") then {
    private _radar = createVehicle [_radarCls, _pos, [], 0, "CAN_COLLIDE"];
    if (isNull _radar) exitWith {
        WARNING_1("AA base: radar '%1' would not create",_radarCls);
    };
    _radar setDir random 360;
    _radar setVectorUp surfaceNormal (getPosATL _radar);
    _made pushBack _radar;
};

// --- launchers, the outer ring --------------------------------------------
private _launchMin = _radius * AB_LAUNCH_INNER;
private _launchSpots = [];
if (_missiles isNotEqualTo []) then {
    _launchSpots = [_missileCount, _launchMin, _radius, AB_LAUNCH_FOOT, AB_LAUNCH_SEP, [_pos], _launchMin] call _fnc_ring;
    if (count _launchSpots < _missileCount) then {
        WARNING_3("AA base at %1: ground for %2 of %3 launchers",mapGridPosition _pos,count _launchSpots,_missileCount);
    };
    {
        private _l = createVehicle [selectRandom _missiles, _x, [], 0, "CAN_COLLIDE"];
        if (isNull _l) then {continue};
        _l setDir (_x getDir _pos);
        _l setVectorUp surfaceNormal (getPosATL _l);
        _made pushBack _l;
    } forEach _launchSpots;
};

// --- guns, the inner ring: point defence for the radar --------------------
if (_guns isNotEqualTo []) then {
    private _gunMin = _radius * AB_GUN_INNER;
    private _gunSpots = [_gunCount, _gunMin, _radius * AB_GUN_OUTER, AB_GUN_FOOT, AB_GUN_SEP,
        [_pos] + _launchSpots, AB_GUN_SEP] call _fnc_ring;
    if (count _gunSpots < _gunCount) then {
        WARNING_3("AA base at %1: ground for %2 of %3 guns",mapGridPosition _pos,count _gunSpots,_gunCount);
    };
    {
        private _g = createVehicle [selectRandom _guns, _x, [], 0, "CAN_COLLIDE"];
        if (isNull _g) then {continue};
        _g setDir (_pos getDir _x);
        _g setVectorUp surfaceNormal (getPosATL _g);
        _made pushBack _g;
    } forEach _gunSpots;
};

if (_made isEqualTo []) exitWith {
    WARNING_1("AA base at %1: no hardware stood up - nothing built",mapGridPosition _pos);
    false
};

// Crewed, kept out of ALiVE, and handed to adsite - the same path a
// battery takes.
[_made, _side, _pos, _kinds] call FUNC(crewSite);

// The rearm pool and the site list, as a battery joins them.
GVAR(hardware) append _made;
// and the rearm loop, which an AA Base alone would otherwise never start
[] call FUNC(rearmLoop);
GVAR(sites) pushBack [+_pos, _side];
missionNamespace setVariable [QGVAR(sites), GVAR(sites), true];

// --- guards, off the hardware and inside the area -------------------------
private _groups = [_pos, _side, _kinds, [], _guards, _radius * AB_GUARD_INNER, _radius, _zone] call FUNC(placeGuards);
if (_groups isNotEqualTo []) then {
    // A frame later, once the men are queryable - profiling an empty group
    // hands ALiVE nothing.
    [{
        [_this] call FUNC(profileGuards);
    }, _groups] call CBA_fnc_execNextFrame;
};

INFO_4("AA base for %1 at %2: %3 piece(s), %4 guard group(s)",_side,mapGridPosition _pos,count _made,count _groups);

true
