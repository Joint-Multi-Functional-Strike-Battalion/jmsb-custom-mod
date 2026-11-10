#include "script_component.hpp"
/*
 * Author: YonV
 * The watch on a transport helicopter while it is out, every AIR_TICK
 * seconds. A new order (the module's serial moved on) is planned first
 * (FUNC(transportPlan)); then the current one is flown:
 *
 *   "transit"  flying the legs - each VIA point, the final approach point -
 *              and then to the point. On final, a requested landing signal
 *              is looked for round the LZ and landed on when seen. A
 *              PARADROP climbs out of nap of the earth to its jump height
 *              on the final leg (EFUNC(support,approachHeight), 2026-11-01).
 *              Arrived: FUNC(transportArrive) starts whatever the task does
 *              there
 *   anything after that is FUNC(transportStep)'s - landing, waiting on the
 *              ground, roping, casting, jumping, carrying a load, holding
 *
 * The first order is planned at the launch (FUNC(transportLaunch)). Each leg
 * is an order on the airframe itself, given again while it is idle short of
 * the point (FUNC(moveTo), FUNC(heliOrder) - Simplex's way, 2026-11-05); the
 * legs are stepped here by distance.
 *
 * Home ends the watch: a synced helicopter is shut down, repaired, refuelled,
 * re-armed and re-crewed on its stand; a class one is removed once it is
 * empty.
 *
 * AN AIRFRAME THAT CANNOT FLY - pilot dead, too shot up to move - is written
 * off once that has held for FAULT_GRACE seconds (FUNC(writeOff);
 * FUNC(flightFault) says why), or it would hold the asset for ever - lost, a
 * respawn used (user, 2026-11-02). A synced one is counted lost
 * like a wreck, so the module's Respawn Delay replaces it on its stand
 * (FUNC(lost), FUNC(respawn)) the way Simplex replaces a stuck vehicle. A
 * rotor wrecked before it left its airfield, nothing having hit it, is
 * repaired once instead (FUNC(rotorRepair), 2026-11-02).
 *
 * Arguments:
 * 0: [logic, helicopter, state] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(transportTick), 1, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

// Fuel share at which the helicopter goes home whatever it was told.
#define BINGO_FUEL 0.15

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_logic", "_veh", "_st"];

if (isNull _logic) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_veh] call FUNC(sweep);
};

if (!alive _veh) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_logic] call FUNC(finish);
};

// CANNOT FLY: written off once that has held FAULT_GRACE s, counted lost (the
// respawn count) and let go of - never swept here, players may be aboard
// (FUNC(writeOff)). While the grace runs nothing new is flown: a re-plan
// needs a pilot.
private _writeOff = [_logic, _veh, _st] call FUNC(writeOff);
if (_writeOff isEqualTo WRITE_OFF_DONE) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_logic] call FUNC(finish);
};
if (_writeOff isEqualTo WRITE_OFF_PENDING) exitWith {};

private _serial = _logic getVariable [QGVAR(serial), 0];
if (_serial isNotEqualTo (_st get "serial")) then {
    _st set ["serial", _serial];
    [_logic, _veh, _st, _logic getVariable [QGVAR(order), []]] call FUNC(transportPlan);
};

private _task = _st getOrDefault ["task", TASK_HOME];
private _target = _st getOrDefault ["target", getPosATL _veh];
private _requester = _st getOrDefault ["requester", objNull];

if (fuel _veh < BINGO_FUEL && _task isNotEqualTo TASK_HOME) exitWith {
    [_logic, _st, "bingo fuel, returning to base"] call FUNC(transportHome);
};

// A LIFT TASKED BY MESSAGE (step 7, 2026-11-01): what it says and asks on the
// way, and holding short of an LZ whose status is not known.
if ([_logic, _veh, _st] call FUNC(liftTick)) exitWith {};

if ((_st get "phase") isNotEqualTo "transit") exitWith {
    [_logic, _veh, _st, _handle] call FUNC(transportStep);
};

// THE LEGS FIRST, in order.
private _legs = _st getOrDefault ["legs", []];
if (_legs isNotEqualTo []) exitWith {
    if (_veh distance2D (_legs select 0) > ARRIVE_RING) exitWith {};
    _legs deleteAt 0;
    [_veh, _legs param [0, _target], _st getOrDefault ["speed", "NORMAL"]] call FUNC(moveTo);
};

// ON FINAL, THE SIGNAL. Looked for once, from SIGNAL_LOOK out: seen, it is
// the new LZ; not seen, the grid stands. A lift tasked by message has its
// mark verified by the caller instead and lands only when cleared
// (FUNC(liftTick), user 2026-11-02).
private _signal = _st getOrDefault ["signal", SIGNAL_NONE];
if (_signal isNotEqualTo SIGNAL_NONE && {!(_st getOrDefault ["signalLooked", false])} && {_veh distance2D _target < SIGNAL_LOOK}) then {
    _st set ["signalLooked", true];
    private _seen = [_target, _signal] call FUNC(findSignal);
    if (_seen isEqualTo []) then {
        [_logic, format ["no %1 seen at %2, landing on the grid", toLower (SIGNAL_WORDS select _signal), mapGridPosition _target], "normal", _requester] call FUNC(say);
    } else {
        _target = _seen;
        _st set ["target", _seen];
        [_veh, _seen, _st getOrDefault ["speed", "NORMAL"]] call FUNC(moveTo);
        [_logic, format ["visual on your signal at %1, landing on it", mapGridPosition _seen], "high", _requester] call FUNC(say);
    };
};

// THE JUMP HEIGHT, LATE: nap of the earth until the climb to it (2026-11-01).
if (_task isEqualTo TASK_PARADROP) then {
    [_veh, [_veh, _st getOrDefault ["height", TASK_HEIGHT_NONE], _veh distance2D _target] call EFUNC(support,approachHeight)] call EFUNC(support,flyAt);
};

// TAKEN EARLY, BEFORE THE AI'S BRAKING FLARE (user, 2026-11-08: "make sure
// helos and vtol do not do a large rise to slow down"): a helicopter or VTOL
// whose arrival is the flight control's is taken HELI_TAKE_RING m out and
// braked in level (FUNC(heliFrame)) - unless the lift's circle and clearance
// come first (FUNC(liftTick)), which needs it at ARRIVE_RING.
private _liftJob = _logic getVariable [QGVAR(liftJob), createHashMap];
// A MOVE's LAND circles for its clearance too (2026-11-09, FUNC(liftMove)).
private _moveLand = count _liftJob > 0 && {(_liftJob getOrDefault ["step", ""]) isEqualTo JOB_MOVE} && _task isEqualTo TASK_LAND_OFF;
private _circled = _moveLand || {count _liftJob > 0 && {_task in LZ_CLEAR_TASKS} && {!((_liftJob getOrDefault ["safePickup", false]) && _task isEqualTo TASK_LIFT)}};
private _early = !_circled && {_task in HELI_TAKE_TASKS} && {[_veh] call EFUNC(support,isRotary)};
private _ring = switch (true) do {
    case (_task isEqualTo TASK_PARADROP): {PARADROP_LEAD + (speed _veh / 3.6) * count (fullCrew [_veh, "cargo"])};
    // A VTOL is taken further out, still a plane at speed - before its
    // hand-over to helicopter mode (VTOL_PLANE_RANGE), where the AI brakes
    // it to a crawl (user, 2026-11-08: "vtol landing for pick up was way to
    // slow").
    case (_early): {[HELI_TAKE_RING, VTOL_TAKE_RING] select (_veh isKindOf "VTOL_Base_F")};
    default {ARRIVE_RING};
};
if (_veh distance2D _target > _ring) exitWith {};

[_logic, _veh, _st] call FUNC(transportArrive);
