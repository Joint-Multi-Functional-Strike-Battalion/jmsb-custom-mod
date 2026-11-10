#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_uas_fnc_swarmImpact

Description:
    One drone of an impact swarm: spawned off the target, flown into it, gone.

    THE SAME DIVE THE AMBIENT KAMIKAZE FLIES, deliberately - a straight steering
    loop that writes velocity at the aim point every step, LAMBS turned off on
    the airframe because an AI taking an interest in it would only fight those
    writes. It is written here rather than called from `ambience` because that
    function picks its own target near a player and gates the spawn on a
    module's markers; a swarm has been told where to go.

    SHOT DOWN IS THE COUNTERPLAY AND IT PAYS OUT. A drone that dies on the way
    in detonates nothing - that is one fewer warhead arriving. That is the whole
    reason a swarm is a fight rather than an announcement, and why the count on
    the module matters. What dies is also taken away where it died: the
    Switchblade is a Greyhawk's weight of airframe, and a wreck of it still
    carrying UAS_SWARM_SPEED tumbled through whoever was under it (user,
    2026-11-06: "the remains bounce around and kill folks").

    THE DIVE ENDS IN ONE BURST AND NOTHING ELSE. The airframe is deleted, crew
    and all, before the warhead is created, and the warhead is fused by script -
    so there is no wreck for its own blast to throw and no airframe left alive
    past the aim to be steered back into the ground at 45 m/s. The fuse fires
    on the aim, on a surface or the ground in the next step's travel, or on
    having overshot, because a long frame can carry the airframe through the
    distance window without ever being inside it.

    A SPREAD OF BEARINGS AND DISTANCES, not a queue. Each drone comes from its
    own rolled direction and its own distance inside the module's band, so a
    swarm arrives as a swarm rather than as a line of aircraft down one axis
    that one gunner can work along.

    IT GIVES UP. UAS_SWARM_TIMEOUT and the airframe deletes itself - a drone
    that lost its aim to terrain and is circling a hillside forever is a leak.

Parameters:
    0: Airframe class <STRING>
    1: Side <SIDE>
    2: Target position ATL <ARRAY>
    3: Nearest it may spawn, m <NUMBER>
    4: Furthest it may spawn, m <NUMBER>

Returns:
    Whether it got airborne <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */
params [["_class", "", [""]], ["_side", east, [east]], ["_tgt", [], [[]]],
        ["_min", UAS_SWARM_SPAWN_MIN, [0]], ["_max", UAS_SWARM_SPAWN_MAX, [0]]];

if (!isServer) exitWith {false};
if (_class isEqualTo "" || {_tgt isEqualTo []}) exitWith {false};

// FAR ENOUGH TO BE FOUGHT. Each drone rolls its own distance inside the band and
// its own bearing, so a swarm arrives spread rather than as a line down one axis
// a single gunner can work along - and the transit is the window in which it can
// be shot at. At UAS_SWARM_SPEED, 1500 m is about thirty seconds of somebody
// deciding what to do about it.
private _from = _tgt getPos [_min + random ((_max - _min) max 0), random 360];
_from set [2, 100 + random 80];

private _veh = createVehicle [_class, _from, [], 0, "FLY"];
if (isNull _veh) exitWith {false};

_veh setPosATL _from;
createVehicleCrew _veh;

// THE UAV AI STAYS IN ITS OWN CREW GROUP, and the side is NOT forced onto it.
// FUNC(topUp) learned this the hard way: a UAV's autonomy lives in the crew
// group createVehicleCrew makes, and joining that AI into a group of our own
// leaves an aircraft with nobody flying it - drones fell out of the sky.
//
// So the airframe's own config decides the side, which is why the picker and
// the Side field want to agree. The field is the fallback crew's side for the
// case below, where an airframe - a modded one especially - comes out of
// createVehicleCrew empty on a dedicated server.
if ((crew _veh) isEqualTo []) then {
    private _ai = switch (_side) do {
        case west: {"B_UAV_AI"};
        case independent: {"I_UAV_AI"};
        default {"O_UAV_AI"};
    };
    private _own = getText (configOf _veh >> "crew");
    if (_own isNotEqualTo "" && {isClass (configFile >> "CfgVehicles" >> _own)}) then { _ai = _own };

    private _crewGrp = createGroup [_side, true];
    _crewGrp deleteGroupWhenEmpty true;
    (_crewGrp createUnit [_ai, getPosATL _veh, [], 0, "NONE"]) moveInAny _veh;
};

(group _veh) deleteGroupWhenEmpty true;

[_veh] call EFUNC(common,lambsOff);

// Aimed just off the deck so the dive terminates on what is standing there
// rather than sailing over the far side of a roof line.
private _aim = +_tgt;
_aim set [2, 2];

[{
    params ["_args", "_handle"];
    _args params ["_veh", "_aim", "_until"];

    if (isNull _veh) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    // SHOT DOWN OR FELL APART ON THE WAY IN. Nothing detonates - that is the
    // counterplay - but a dead airframe keeps its speed, and left to the
    // engine it tumbles through whoever is under it. Stopped and taken away
    // where it died, crew with it. Hidden counts as dead: on a hosted game the
    // Switchblade's own loop hides an airframe whose warhead it has already
    // fired, and ours must not steer that ghost on to a second bang.
    if (!alive _veh || {isObjectHidden _veh}) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        _veh setVelocity [0, 0, 0];
        {_veh deleteVehicleCrew _x} forEach (crew _veh);
        deleteVehicle _veh;
    };

    if (CBA_missionTime > _until) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        {_veh deleteVehicleCrew _x} forEach (crew _veh);
        deleteVehicle _veh;
    };

    private _here = getPosATL _veh;
    private _dir = _here vectorFromTo _aim;
    private _gap = _here distance _aim;

    // THE FUSE, FOUR WAYS, because the distance alone left airframes alive past
    // the aim. (1) Inside UAS_SWARM_FUSE of it. (2) A wall, roof, tree or
    // somebody inside the next step's travel - the warhead goes on contact
    // instead of the airframe ramming it, bouncing off and flying on. The
    // airframe's own crew come back as hits and are not a wall. (3) The ground
    // inside that travel, or already under it - checked on its own rather than
    // left to the scan. (4) In the last UAS_SWARM_TERMINAL m and moving away: a
    // long frame carried it through the window.
    private _hereASL = getPosASL _veh;
    private _ahead = _hereASL vectorAdd (_dir vectorMultiply UAS_SWARM_REACH);
    private _crew = crew _veh;
    private _wall = ((lineIntersectsSurfaces [_hereASL, _ahead, _veh, objNull, true, UAS_SWARM_SCAN_HITS, "GEOM", "FIRE"]) findIf {
        private _obj = _x select 2;
        !(_obj in _crew) && {(vehicle _obj) isNotEqualTo _veh} && {(attachedTo _obj) isNotEqualTo _veh}
    }) >= 0;
    private _ground = (_here select 2) < UAS_SWARM_DECK || {(getTerrainHeightASL _ahead) > (_ahead select 2)};
    private _past = _gap < UAS_SWARM_TERMINAL && {((velocity _veh) vectorDotProduct _dir) < 0};

    if (_gap < UAS_SWARM_FUSE || _wall || _ground || _past) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        // The airframe goes before the bang, crew with it: no wreck for the
        // blast to throw, no invisible UAV crew left standing in it.
        {_veh deleteVehicleCrew _x} forEach (crew _veh);
        deleteVehicle _veh;
        // On the dive's line at the dive's speed, so a shell with a wall in
        // front of it bursts on the wall; fused by script a frame later for
        // the one with nothing in front of it.
        private _shell = createVehicle [UAS_SWARM_WARHEAD, _here, [], 0, "CAN_COLLIDE"];
        _shell setVelocity (_dir vectorMultiply UAS_SWARM_SPEED);
        [{if (!isNull _this) then {triggerAmmo _this}}, _shell] call CBA_fnc_execNextFrame;
    };

    _veh setVelocity (_dir vectorMultiply UAS_SWARM_SPEED);
    _veh setVectorDir _dir;
}, UAS_SWARM_STEP, [_veh, _aim, CBA_missionTime + UAS_SWARM_TIMEOUT]] call CBA_fnc_addPerFrameHandler;

true
