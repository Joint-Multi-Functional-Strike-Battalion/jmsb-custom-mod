#include "script_component.hpp"
/*
 * Author: JMSB
 * Builds one battery: a radar, and launchers set back from it.
 *
 * Everything is crewed and PROFILED. An uncrewed static is scenery - a SAM
 * with nobody on it never fires - and an unprofiled one is a live AI sitting
 * on the server for the whole mission whether anybody is near it or not.
 *
 * The site is recorded by POSITION, not by object. Profiling deletes the
 * hardware and ALiVE makes new objects when a player comes near, so anything
 * holding object references would be pointing at deleted vehicles within
 * minutes. A site is a place.
 *
 * Arguments:
 * 0: Where <ARRAY>
 * 1: Owning side <SIDE>
 * 2: [radar, launchers, manpad, mag] <ARRAY>
 * 3: The side's TAOR markers <ARRAY>
 * 4: Markers never to build on <ARRAY>
 * 5: Man classes for the security groups <ARRAY>
 *
 * Return Value:
 * It was built <BOOL>
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]], ["_kit", [], [[]]],
        ["_taor", [], [[]]], ["_black", [], [[]]], ["_kinds", [], [[]]]];

_kit params ["_radarCls", "_launchers"];

// The common pre-spawn gate, against the markers the planner handed over -
// whatever upstream computed, nothing of this side's stands up outside them.
// FALSE, not nothing - the planner negates this return, and `!nil` is a
// type error that killed the whole side's planning loop on first refusal.
if (!([_side, _pos, "AA battery", _taor, _black] call EFUNC(common,taorGate))) exitWith {false};

if (_pos isEqualTo [] || _radarCls isEqualTo "") exitWith {false};

private _made = [];

private _radar = createVehicle [_radarCls, _pos, [], 0, "CAN_COLLIDE"];
if (isNull _radar) exitWith {
    WARNING_1("radar '%1' would not create",_radarCls);
    false
};
_radar setDir random 360;
_radar setVectorUp surfaceNormal (getPosATL _radar);
_made pushBack _radar;

// Launchers stand off the radar, on their own patch of open ground.
private _clear = 6 max GVAR(openGround);
private _spots = [[], round GVAR(launchers), createHashMapFromArray [
    ["centre", _pos],
    ["minRange", AD_LAUNCH_MIN],
    ["maxRange", AD_LAUNCH_MAX],
    ["footprint", 10],
    ["clearRadius", _clear],
    ["maxSlope", 0.12],
    ["separation", 60],
    ["avoid", [_pos]],
    ["avoidRadius", AD_LAUNCH_MIN],
    ["blacklist", _black]
]] call EFUNC(common,findSite);

// The launchers reach up to AD_LAUNCH_MAX from the radar, so a battery legally
// inside the TAOR can still throw hardware over the boundary. Same rule.
if (_taor isNotEqualTo []) then {
    _spots = _spots select {
        private _spot = _x;
        (_taor findIf {_spot inArea _x}) > -1
    };
};

{
    private _cls = selectRandom _launchers;
    private _l = createVehicle [_cls, _x, [], 0, "CAN_COLLIDE"];
    if (isNull _l) then {continue};
    _l setDir (_x getDir _pos);
    _l setVectorUp surfaceNormal (getPosATL _l);
    _made pushBack _l;
} forEach _spots;

// Crew it, keep it out of ALiVE and hand it to adsite - FUNC(crewSite) carries
// the drone-turret and profiling lessons this battery was built on.
[_made, _side, _pos, _kinds] call FUNC(crewSite);

// Guards, if the mission asked for any. Their own faction's men, so they look
// like the force that owns the site.
[_pos, _side, _kinds, _black] call FUNC(buildSecurity);

// The pieces themselves join the rearm pool - a battery that goes silent
// after its first salvo is a one-round site nobody meant to build.
GVAR(hardware) append _made;

// Place, not objects - see the docblock.
GVAR(sites) pushBack [+_pos, _side];
missionNamespace setVariable [QGVAR(sites), GVAR(sites), true];

true
