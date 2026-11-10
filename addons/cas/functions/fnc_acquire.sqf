#include "script_component.hpp"
/*
 * Author: YonV
 * TERMINAL GUIDANCE: what the drone is actually going to hit, as opposed to
 * the grid it was sent to.
 *
 * THE GRID IS AN AREA, NOT A POINT. A ten-figure grid off a map click is
 * accurate to the pixel the man clicked, which over 4 km of run-in is a
 * building either side of the one he meant. So the request carries the grid
 * and the aircraft looks, on the way in, for somebody telling it better:
 *
 *   LASER first. A spot is unambiguous, it is aimed by a man who can see the
 *   target, and it is the only one of the three that can track something
 *   moving. Own side's spots only - an enemy designator is a trap.
 *
 *   SMOKE second. Every rifleman has it, it needs no equipment and no
 *   training, and it is what actually gets used when the JTAC is a section
 *   commander with a radio. Any colour: asking a man under fire to find the
 *   right grenade is asking for the strike to go in on nothing.
 *
 *   THE GRID LAST, unchanged. No spot and no smoke is not a failure - it is a
 *   map-grid strike, which is what was ordered, and it goes in.
 *
 * SEARCH RADIUS 0 TURNS THE WHOLE THING OFF, and the grid is final. A mission
 * that wants map-grid bombing and nothing cleverer sets that and gets it.
 *
 * Arguments:
 * 0: The requested grid <ARRAY> - ATL
 * 1: Search radius in metres <NUMBER>
 * 2: The side asking <SIDE>
 *
 * Return Value:
 * 0: Aim point <ARRAY> - ATL
 * 1: What is guiding it <STRING> - "laser", "smoke" or "grid"
 * 2: The object to track, objNull for a fixed point <OBJECT>
 *
 * Public: No
 */

params [["_grid", [], [[]]], ["_radius", 0, [0]], ["_side", west, [west]]];

if (_grid isEqualTo [] || _radius <= 0) exitWith {[_grid, "grid", objNull]};

// The engine spawns one of these per designator, per side, and they are the
// same objects a Darter's laser or a soldier's designator produce - so this
// sees ACE designators, vanilla ones and vehicle pods without knowing which.
private _laserType = ["LaserTargetE", "LaserTargetW"] select ([_side, west] call BIS_fnc_sideIsFriendly);
private _spots = (_grid nearObjects [_laserType, _radius]) select {alive _x};

// Independent designates for itself; the two-sided engine class above has no
// third entry, so a GUER spot is found by looking for either and checking who
// owns it.
if (_side isEqualTo independent) then {
    _spots = ((_grid nearObjects ["LaserTargetW", _radius]) + (_grid nearObjects ["LaserTargetE", _radius]))
        select {alive _x};
};

if (_spots isNotEqualTo []) exitWith {
    private _spot = [_spots, _grid] call FUNC(nearestTo);
    [getPosATL _spot, "laser", _spot]
};

// SMOKE IS THE SHELL IN THE AIR, NOT THE GRENADE IN A POCKET. The thrown
// object stops existing once it has burnt; while it is burning it is a
// SmokeShell in the world, which is exactly the window a strike wants.
private _smoke = (_grid nearObjects ["SmokeShell", _radius]) select {alive _x};

if (_smoke isNotEqualTo []) exitWith {
    [getPosATL ([_smoke, _grid] call FUNC(nearestTo)), "smoke", objNull]
};

[_grid, "grid", objNull]
