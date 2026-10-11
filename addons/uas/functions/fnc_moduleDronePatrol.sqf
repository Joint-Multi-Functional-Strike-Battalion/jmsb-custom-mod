#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_uas_fnc_moduleDronePatrol

Description:
    One patrol zone: ground a side flies drones over, drawn where you put it.

    WHAT THIS REPLACED. In jmfsb, patrols orbited each ALiVE commander's own
    objectives - the module said how many airframes and the simulation said
    where. There are no commanders and no objective lists, so the where had
    nothing to read from. A zone is that answer: an area module, sized in Eden
    or Zeus, saying "this side patrols here".

    IT IS SIMPLER THAN WHAT IT REPLACED, on purpose. The old planner had to
    decide whether a side patrolled its own ground or the enemy's, then gate
    every objective through EFUNC(common,taorGate) because an attacker's
    objective list reached into enemy territory - and green patrols orbiting
    inside the red TAOR is what happened when a commander declared no markers.
    A placed zone IS the declaration. There is nothing to gate.

    NOBODY NEAR, NOTHING FLYING - unchanged, and the reason the rest of the
    addon is worth keeping. A zone with no player within UAS_PLAYER_RANGE is not
    patrolled, and FUNC(standDown) retires the ones whose audience has left. An
    empty map costs nothing.

    THE AREA IS THE ORBIT GROUND, not a spawn box. Drones loiter over it; where
    the airframe first appears is FUNC(topUp)'s business and is a stand-off
    position outside it.

Parameters:
    0: The module logic <OBJECT>
    1: Synchronised units <ARRAY>
    2: Activated <BOOL>

Returns:
    None

Author:
    YonV
---------------------------------------------------------------------------- */
params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

// THE ENEMY'S, WORKED OUT (D59): no Side box on the module any more - the
// patrol flies for whoever is hostile to the players (EFUNC(common,enemySide)).
private _side = call EFUNC(common,enemySide);

// EDEN'S OWN AREA, the same [a, b, angle, isRectangle, height] every other area
// module in this mod reads - see EFUNC(modules,moduleHealArea). A module never
// resized has no area at all, which is a zone of nothing; the default is the
// radius a patrol wanders anyway, so an unsized module is one orbit.
(_logic getVariable ["objectArea", [0, 0, 0, false, 0]]) params [["_a", 0], ["_b", 0]];
private _radius = (_a max _b) max UAS_ORBIT_RADIUS;

// THE AIRFRAME, HOW MANY, AND WHETHER IT SHOOTS - all this module's, because
// one module is one patrol. An empty class falls back to a UAV belonging to the
// side, which is what FUNC(factionUav) is for; a count of zero is a module
// placed and switched off rather than deleted.
private _class = trim (_logic getVariable ["droneClass", ""]);
if (_class isNotEqualTo "" && {!isClass (configFile >> "CfgVehicles" >> _class)}) then {
    WARNING_1("drone patrol: '%1' is not a vehicle class - falling back to the side's own",_class);
    _class = "";
};

private _count = round ((_logic getVariable ["droneCount", 1]) max 0);

// ARTILLERY ON DETECTION. A drone that sees somebody already reports it down
// the reaction path; this makes the report land as shells. Off by default,
// because it turns overflight from a thing you hide from into a thing that
// kills you, and that is a decision about a mission rather than a default.
private _arty = [
    [_logic getVariable ["artyOnDetect", false]] call {
        params ["_v"]; if (_v isEqualType 0) then {_v > 0} else {_v isEqualTo true}
    },
    round ((_logic getVariable ["artyRounds", 6]) max 1),
    (_logic getVariable ["artyScatter", 100]) max 10,
    (_logic getVariable ["artyCooldown", 300]) max 30
];

private _zones = missionNamespace getVariable [QGVAR(zones), []];
_zones pushBack [_side, getPosATL _logic, _radius, _class, _count, _arty];
missionNamespace setVariable [QGVAR(zones), _zones];

INFO_3("drone patrol: %1, %2 airframe(s) over %3",_side,_count,mapGridPosition _logic);

// ONE SYSTEM, HOWEVER MANY ZONES. The planner walks every zone on one clock -
// twelve zones do not mean twelve schedulers, and a zone placed by Zeus an hour
// in joins the walk on the next beat rather than starting a second one.
if (!GVAR(moduleUp)) then {
    GVAR(moduleUp) = true;
    [] call FUNC(start);
};

nil
