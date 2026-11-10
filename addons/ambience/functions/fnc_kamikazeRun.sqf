#include "script_component.hpp"
/*
 * Author: YonV
 * One kamikaze run: a real drone appears a few hundred metres out, flies a
 * straight dive at the building and detonates on arrival.
 *
 * REAL AND KILLABLE, which is the whole point of doing this with an
 * aircraft instead of a spawned explosion: it is heard coming, it can be
 * seen against the sky, and anything that shoots it down has genuinely
 * stopped the strike - a dead drone detonates nothing. Steering is a
 * velocity write per tick, the missile treatment - the UAV's own AI never
 * gets a vote on where it is going.
 *
 * THE DIVE ENDS IN ONE BURST AND NOTHING ELSE, the same end as the swarm's
 * dive (uas swarmImpact). A dead airframe keeps its speed, and left to the
 * engine it tumbled through whoever was under it (user, 2026-11-06: "the
 * remains bounce around and kill folks"): it is stopped and taken away where
 * it died, crew with it. The fuse fires on the aim, on a surface or the
 * ground in the next step's travel, or on having overshot - a long frame can
 * carry the airframe through the distance window - and the airframe is
 * deleted, crew and all, before the warhead is fused by script.
 *
 * The spawn point is gated like every module spawn: re-rolled until it is
 * inside the module's markers, and the run is skipped when no bearing is -
 * the war stays inside the line even while approaching from outside would
 * be prettier.
 *
 * Arguments:
 * 0: Building position ATL <ARRAY>
 * 1: Drone classname <STRING>
 * 2: Speed in m/s <NUMBER>
 * 3: The module's markers, for the spawn gate <ARRAY>
 *
 * Return Value:
 * The run is airborne <BOOL>
 *
 * Public: No
 */

params [["_tgt", [], [[]]], ["_cls", "", [""]], ["_speed", 40, [0]], ["_markers", [], [[]]]];

if (_tgt isEqualTo [] || _cls isEqualTo "") exitWith {false};

// A few hundred metres out on a random bearing, high enough to be seen.
// Re-rolled against the gate; no compliant bearing, no run.
private _from = [];
for "_i" from 1 to 8 do {
    private _try = _tgt getPos [350 + random 250, random 360];
    if ([sideUnknown, _try, "ambient kamikaze spawn", _markers] call EFUNC(common,taorGate)) exitWith {
        _from = _try;
    };
};
if (_from isEqualTo []) exitWith {
    INFO("kamikaze run skipped - no spawn bearing inside the markers");
    false
};
_from set [2, 120 + random 60];

private _veh = createVehicle [_cls, _from, [], 0, "FLY"];
if (isNull _veh) exitWith {false};
_veh setPosATL _from;
createVehicleCrew _veh;
(group _veh) deleteGroupWhenEmpty true;

// The run is a straight dive on a steering loop - LAMBS taking an interest
// in it would only fight the velocity writes.
[_veh] call EFUNC(common,lambsOff);

// The neighbourhood hears the motor before the dive.
["FPV", "One-way drone inbound", _tgt, 400, 2] call EFUNC(common,alert);
INFO_2("kamikaze away: %1 -> grid %2",_cls,mapGridPosition _tgt);

// Aim just above the ground floor so the dive terminates on the walls,
// not the roof line's far side.
private _aim = +_tgt;
_aim set [2, 2];

[{
    params ["_args", "_handle"];
    _args params ["_veh", "_aim", "_speed", "_until"];

    if (isNull _veh) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    // Shot down or fell apart: the strike died with it - that is the
    // counterplay paying out. Nothing detonates, and the wreck does not fly
    // on at _speed into whoever is under it: stopped and taken away where it
    // died, crew with it. Hidden counts as dead - a modded airframe's own
    // loop may have hidden it with its warhead already fired.
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

    // THE FUSE, FOUR WAYS - the distance alone left airframes alive past the
    // aim, ramming the ground at _speed. Inside AMB_KAM_FUSE of the aim; a
    // surface in the next step's travel (the airframe's own crew come back as
    // hits and are not one); the ground in that travel or already under the
    // airframe (checked on its own, not left to the scan); or moving
    // away from the aim inside AMB_KAM_TERMINAL - a long frame carried it
    // through the window.
    private _hereASL = getPosASL _veh;
    private _ahead = _hereASL vectorAdd (_dir vectorMultiply (_speed * AMB_KAM_STEP * 2 + AMB_KAM_FUSE));
    private _crew = crew _veh;
    private _wall = ((lineIntersectsSurfaces [_hereASL, _ahead, _veh, objNull, true, AMB_KAM_SCAN_HITS, "GEOM", "FIRE"]) findIf {
        private _obj = _x select 2;
        !(_obj in _crew) && {(vehicle _obj) isNotEqualTo _veh} && {(attachedTo _obj) isNotEqualTo _veh}
    }) >= 0;
    private _ground = (_here select 2) < AMB_KAM_DECK || {(getTerrainHeightASL _ahead) > (_ahead select 2)};
    private _past = _gap < AMB_KAM_TERMINAL && {((velocity _veh) vectorDotProduct _dir) < 0};

    if (_gap < AMB_KAM_FUSE || _wall || _ground || _past) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        // The airframe goes before the bang, crew with it - no wreck for the
        // blast to throw - and the shell is fused by script a frame later,
        // flying the dive's line meanwhile so one with a wall in front of it
        // bursts on the wall.
        {_veh deleteVehicleCrew _x} forEach (crew _veh);
        deleteVehicle _veh;
        private _shell = createVehicle ["Sh_122mm_AMOS", _here, [], 0, "CAN_COLLIDE"];
        _shell setVelocity (_dir vectorMultiply _speed);
        [{if (!isNull _this) then {triggerAmmo _this}}, _shell] call CBA_fnc_execNextFrame;
    };

    _veh setVelocity (_dir vectorMultiply _speed);
    _veh setVectorDir _dir;
}, AMB_KAM_STEP, [_veh, _aim, _speed, CBA_missionTime + AMB_KAM_TIMEOUT]] call CBA_fnc_addPerFrameHandler;

true
