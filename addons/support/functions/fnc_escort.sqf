#include "script_component.hpp"
/*
 * Author: YonV
 * Server: puts ESCORT_COUNT drone escorts in the air with a support aircraft
 * and starts their watch (user, 2026-11-01: "an option for drone escorts, for
 * fix wings fixwing drones drone defined in 3den module, for helos based on
 * security 2 always two wing men, two rotary drones, defined in module";
 * DESIGN_SUPPORT_MESSAGING 1.2). The provider decides whether and which class
 * (EFUNC(support_air,escortLaunch)); the core knows no asset kind - it is
 * handed a lead and a drone class.
 *
 * THE SAME RULES AS THE LEAD. Each escort is made beside it, at its own kind's
 * tactical height (FUNC(flightHeight): nap of the earth for a rotary drone,
 * 4000 m for a fixed-wing one) - STACKED above that (2026-11-05, two MQ-8Bs
 * made at the lead's height flew into each other): escort n flies n times
 * ESCORT_STACK_HELI / _PLANE m higher and is made that far above the lead, so
 * no two of them share a height - and put on the lights watch with the lead's
 * own airfield (FUNC(tactical)) - dark everywhere else. It flies the lead's
 * route, its hold and its way home because it flies with the lead
 * (FUNC(escortTick)), engages what threatens it, and flares for it
 * (FUNC(escortMissile)).
 *
 * A CREW OF THE PLAYERS' SIDE. A drone's crew comes out as the class's own
 * side; it is put in a group of the lead's side, so a drone class of another
 * faction never turns on the aircraft it guards.
 *
 * ALiVE is told to leave them alone, as with every support aircraft
 * (adapter_alive's profileIgnore, only when the adapter is loaded).
 *
 * A lead with live escorts keeps them: a second call adds none.
 *
 * Arguments:
 * 0: The lead aircraft <OBJECT>
 * 1: The escort drone class <STRING>
 * 2: The lead's side <SIDE>
 * 3: The task point - the target, the hold, the LZ, the drop; [] for none <ARRAY>
 *
 * Return Value:
 * The escorts <ARRAY of OBJECTs>
 *
 * Example:
 * [_veh, "B_UAV_02_dynamicLoadout_F", west, _pos] call jmfsb_support_fnc_escort
 *
 * Public: Yes
 */

params [
    ["_lead", objNull, [objNull]],
    ["_cls", "", [""]],
    ["_side", west, [west]],
    ["_point", [], [[]]]
];

if (!isServer || {!alive _lead}) exitWith {[]};

private _have = (_lead getVariable [QGVAR(escorts), []]) select {alive _x};
if (_have isNotEqualTo []) exitWith {_have};

if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {
    WARNING_1("escort class '%1' is not a class in this mission - no escort",_cls);
    []
};

private _heli = _cls isKindOf "Helicopter";
private _wing = [ESCORT_WING_PLANE, ESCORT_WING_HELI] select _heli;
private _trail = [ESCORT_TRAIL_PLANE, ESCORT_TRAIL_HELI] select _heli;

// The lead's own airfield, from its place on the lights watch.
private _field = [];
if (!isNil QGVAR(tactical)) then {
    private _at = GVAR(tactical) findIf {(_x select 0) isEqualTo _lead};
    if (_at > -1) then {_field = (GVAR(tactical) select _at) select 1};
};

private _stack = [ESCORT_STACK_PLANE, ESCORT_STACK_HELI] select _heli;
private _height = [_cls, PHASE_TRANSIT] call FUNC(flightHeight);
// A rotary drone is made no lower than the lead, its stack above that, then
// settles to its own stacked height.
private _madeAt = [_height, _height max ((getPosATL _lead) select 2)] select _heli;
private _dir = getDir _lead;
private _behind = _lead getPos [_trail, _dir + 180];

private _escorts = [];
for "_i" from 0 to (ESCORT_COUNT - 1) do {
    private _sideSign = [-1, 1] select (_i % 2);
    private _at = _behind getPos [_wing * (floor (_i / 2) + 1), _dir + 90 * _sideSign];
    private _above = _stack * (_i + 1);
    private _start = [_at select 0, _at select 1, _madeAt + _above];

    private _veh = createVehicle [_cls, _start, [], 0, "FLY"];
    if (isNull _veh) then {
        WARNING_1("escort '%1' could not be made",_cls);
        continue;
    };
    _veh setDir _dir;
    _veh setPosATL _start;
    _veh setVectorUp [0, 0, 1];
    if (_heli) then {
        _veh setVelocity (velocity _lead);
    } else {
        _veh setVelocityModelSpace [0, ESCORT_PLANE_START * getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed") / ESCORT_KMH_PER_MS, 0];
    };

    private _grp = createGroup [_side, true];
    _grp createVehicleCrew _veh;
    // A UAV that comes out crewless flies nowhere - the CAS drones' fix.
    if (isNull driver _veh) then {createVehicleCrew _veh};
    if ((crew _veh) isEqualTo []) then {
        WARNING_1("escort '%1' could not be crewed",_cls);
        deleteVehicle _veh;
        deleteGroup _grp;
        continue;
    };
    (crew _veh) joinSilent _grp;
    _grp allowFleeing 0;
    _grp setBehaviour "AWARE";
    _grp setCombatMode "YELLOW";

    [_veh] call EFUNC(common,lambsOff);
    [_veh, _field] call FUNC(tactical);
    [_veh, _height + _above] call FUNC(flyAt);
    if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
        [_veh] call EFUNC(adapter_alive,profileIgnore);
    };
    _veh setVariable [QGVAR(escortOf), _lead];
    _escorts pushBack _veh;
};

if (_escorts isEqualTo []) exitWith {[]};

// THE ALARM: a missile fired at the lead or at an escort sets off the flares
// (FUNC(escortMissile)). Once per airframe - a synced lead flies again and
// again. It fires where the aircraft is local, the server for every crew a
// provider makes; the watch's own missile scan is the backstop.
{
    if !(_x getVariable [QGVAR(escortEH), false]) then {
        _x setVariable [QGVAR(escortEH), true];
        _x addEventHandler ["IncomingMissile", {
            params ["_target", "", "_shooter", "_instigator"];
            if (isNull _shooter) then {_shooter = vehicle _instigator};
            [_target, _shooter] call FUNC(escortMissile);
        }];
    };
} forEach ([_lead] + _escorts);

_lead setVariable [QGVAR(escorts), _escorts];
_lead setVariable [QGVAR(escortShooter), nil];

private _st = createHashMapFromArray [
    ["side", _side],
    ["point", _point],
    ["heli", _heli],
    ["phase", "follow"],
    ["home", getPosATL (_escorts select 0)]
];

INFO_3("%1 escort(s) '%2' with '%3'",count _escorts,_cls,typeOf _lead);

[FUNC(escortTick), ESCORT_TICK, [_lead, _escorts, _st]] call CBA_fnc_addPerFrameHandler;

_escorts
