#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_uas_fnc_moduleDroneSwarm

Description:
    A swarm, launched where you place it: two to twelve airframes, either diving
    on the module or circling it.

    IT IS NOT A PATROL AND DOES NOT PRETEND TO BE. FUNC(moduleDronePatrol) keeps
    a standing presence over ground, replaces losses and stands down when nobody
    is near. This is an event: it launches once when the module fires, and what
    it launches is gone when it is gone. Placing one in Zeus is how you drop a
    swarm on somebody now, this minute.

    TWO ACTIONS, and they want different airframes.

      IMPACT   every drone dives on the module's position and detonates. A
               one-way weapon: the counterplay is shooting them down on the way
               in, and each one you hit is one that does not arrive. Any
               airframe will do because the airframe is the warhead.

      CIRCLE   every drone orbits the module at height with its crew and its
               weapons, which is only worth doing with something armed. They are
               left to their own AI once they are up: what a gun drone does with
               a target is the gun drone's business.

    THE AIRFRAME LIST IS A SETTING. QGVAR(swarmClasses) is what a mission may
    field; the module's picker is how you choose from it. A class that is not on
    the list is refused at placement rather than at launch - the person who typed
    it is standing there.

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

private _class = trim (_logic getVariable ["swarmClass", ""]);
// getVariable, not the GVAR. A module function runs between preInit and
// postInit and an Eden-placed module can reach here before the setting's stored
// value has been applied - reading it directly would throw on the one ordering
// that matters. The default is the shipped list.
private _allowedRaw = missionNamespace getVariable [QGVAR(swarmClasses), "O_UAV_01_F,B_UAV_01_F,I_UAV_01_F,B_SwitchBlade_300,B_SwitchBlade_600"];
private _allowed = (_allowedRaw splitString ",") apply {trim _x} select {_x isNotEqualTo ""};

if (_class isEqualTo "") then { _class = _allowed param [0, ""] };

if (_class isEqualTo "" || {!isClass (configFile >> "CfgVehicles" >> _class)}) exitWith {
    WARNING_1("drone swarm: '%1' is not a vehicle class - nothing launched",_class);
    [objNull, "Drone Swarm: no valid airframe"] call BIS_fnc_showCuratorFeedbackMessage;
};

// THE SETTING IS THE WHOLE PERMISSION. A picker that offered every UAV in the
// game and a setting that said which were fielded would disagree the first time
// somebody used the picker, so the setting wins and says so. A class on the
// list or a variant of one (RPT, 2026-10-30: a faction's own Switchblade is
// a kind of the Switchblade mod's, not a different airframe).
if (_allowed isNotEqualTo [] && {_allowed findIf {_class isKindOf _x} < 0}) exitWith {
    WARNING_2("drone swarm: '%1' is not in the available list (%2) - nothing launched",_class,_allowedRaw);
    [objNull, format ["Drone Swarm: %1 is not an available airframe", _class]]
        call BIS_fnc_showCuratorFeedbackMessage;
};

private _count = round ((_logic getVariable ["swarmCount", 4]) max UAS_SWARM_MIN min UAS_SWARM_MAX);
private _action = toLower (_logic getVariable ["swarmAction", "impact"]);
if !(_action in ["impact", "circle"]) then { _action = "impact" };

// WHERE IT COMES FROM. Far enough to be seen, heard and shot at on the way in -
// a swarm that appears on top of its target is not a swarm, it is damage. The
// minimum is held at UAS_SWARM_SPAWN_FLOOR for that reason: somebody typing 50
// into the field has not made a harder swarm, they have removed the fight.
private _spawnMin = ((_logic getVariable ["spawnMin", UAS_SWARM_SPAWN_MIN]) max UAS_SWARM_SPAWN_FLOOR);
private _spawnMax = ((_logic getVariable ["spawnMax", UAS_SWARM_SPAWN_MAX]) max _spawnMin);

private _side = [_logic getVariable ["swarmSide", "east"]] call EFUNC(common,sideFromText);
if (isNil "_side" || {_side isEqualTo sideUnknown}) then { _side = east };

private _at = getPosATL _logic;

// The circle's radius is the module's own area, so a swarm told to orbit is
// drawn the way everything else in this mod is drawn. Never resized is a tight
// orbit, which is what a swarm over one compound looks like.
(_logic getVariable ["objectArea", [0, 0, 0, false, 0]]) params [["_a", 0], ["_b", 0]];
private _radius = (_a max _b) max UAS_SWARM_RADIUS;

INFO_3("drone swarm: %1 x %2, %3",_count,_class,_action);
TRACE_2("swarm spawn band",_spawnMin,_spawnMax);

// LAUNCHED IN ORDER, NOT IN ONE FRAME. Twelve airframes created on one tick is
// twelve vehicles, twelve crews and twelve groups in a single frame, and it
// reads as a stutter rather than as a swarm arriving. One every half second is
// still a swarm and costs nothing.
[{
    params ["_args", "_handle"];
    _args params ["_i", "_count", "_class", "_action", "_side", "_at", "_radius", "_min", "_max"];

    if (_i >= _count) exitWith { [_handle] call CBA_fnc_removePerFrameHandler };
    _args set [0, _i + 1];

    if (_action isEqualTo "impact") then {
        [_class, _side, _at, _min, _max] call FUNC(swarmImpact);
    } else {
        [_class, _side, _at, _radius, _i, _count, _min, _max] call FUNC(swarmCircle);
    };
}, UAS_SWARM_STAGGER, [0, _count, _class, _action, _side, _at, _radius, _spawnMin, _spawnMax]]
    call CBA_fnc_addPerFrameHandler;

nil
