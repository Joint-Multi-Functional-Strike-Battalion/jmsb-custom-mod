#include "script_component.hpp"
/*
 * Author: JMSB
 * The crate leaves the aircraft: created just behind and below the tail,
 * filled (FUNC(fillCrate)), and hung under a cargo chute that carries the
 * aircraft's own velocity, with the landing watch that comes with it
 * (EFUNC(common,addParachuteToObject)). Signalled once it is down
 * (FUNC(markCrate)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: The load picked for this drop <STRING> (optional, default the module's first)
 * 3: Signal class, "" for none <STRING> (optional, default "")
 *
 * Return Value:
 * The crate <OBJECT>
 *
 * Example:
 * [_logic, _veh, "magazines", "SmokeShellBlue"] call jmfsb_support_air_fnc_releaseCrate
 *
 * Public: No
 */

// Clearance behind the tail and under the belly, m.
#define TAIL_GAP 4
#define BELLY_GAP 4

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_load", "", [""]], ["_signal", "", [""]]];

private _cls = _logic getVariable [QGVAR(crateClass), "B_supplyCrate_F"];
private _at = _veh modelToWorldWorld [0, -((sizeOf typeOf _veh) / 2 + TAIL_GAP), -BELLY_GAP];

private _crate = createVehicle [_cls, [0, 0, 0], [], 0, "CAN_COLLIDE"];
_crate setPosASL _at;
[_crate, _logic, _load] call FUNC(fillCrate);

// The crate rides attached under the chute, so the aircraft's momentum goes
// on the chute - a chute made at rest drops it short of the grid.
private _chute = [_crate] call EFUNC(common,addParachuteToObject);
_chute setVelocity (velocity _veh);
[_crate, _signal] call FUNC(markCrate);

_crate
