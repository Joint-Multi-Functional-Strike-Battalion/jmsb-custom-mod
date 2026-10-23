#include "script_component.hpp"
/*
 * Author: JMSB
 * One static-line jumper's descent, every CHUTE_TICK seconds: open his canopy
 * when the line pulls it, and let him go on the ground.
 *
 * Opening: NonSteerable_Parachute_F, STATIC_OPEN_DELAY after exit - vanilla,
 * created at the man, and he is put in its seat. A round canopy is not
 * steered; the stick lands where the pass put it. On the ground the engine
 * takes him out of it; the empty canopy is cleared up a little later.
 *
 * Arguments:
 * 0: [unit, canopy, opening time] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(chuteTick), 0.1, [_unit, objNull, CBA_missionTime + 1]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

// Horizontal speed kept from the aircraft when the canopy opens.
#define OPEN_CARRY 0.3
// Sink the canopy starts with, m/s.
#define OPEN_SINK -4
// Seconds before an empty canopy is removed.
#define CHUTE_CLEANUP 15
// Height above the ground under which a man with no canopy is down.
#define FREE_DOWN 1.5

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_unit", "_chute", "_openAt"];

private _fnc_down = {
    [_handle] call CBA_fnc_removePerFrameHandler;
    if (!isNull _unit) then {
        _unit allowDamage true;
        _unit setVariable [QGVAR(landed), true, true];
    };
    if (!isNull _chute) then {
        [{deleteVehicle _this}, _chute, CHUTE_CLEANUP] call CBA_fnc_waitAndExecute;
    };
};

if (!alive _unit) exitWith {call _fnc_down};

if (isNull _chute) exitWith {
    if (((getPos _unit) select 2) < FREE_DOWN || {isTouchingGround _unit}) exitWith {call _fnc_down};
    if (CBA_missionTime < _openAt) exitWith {};

    private _vel = velocity _unit;
    _chute = createVehicle [CHUTE_ROUND, [0, 0, 0], [], 0, "CAN_COLLIDE"];
    _chute setPosASL (getPosASL _unit);
    _chute setDir (getDir _unit);
    _unit moveInDriver _chute;
    _chute setVelocity [(_vel select 0) * OPEN_CARRY, (_vel select 1) * OPEN_CARRY, OPEN_SINK];
    _args set [1, _chute];
};

// Out of the canopy - the engine does that on the ground - or it is gone.
if (!alive _chute || {vehicle _unit isNotEqualTo _chute}) exitWith {call _fnc_down};
