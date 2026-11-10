#include "script_component.hpp"
/*
 * Author: YonV
 * One man out of the aircraft, on the machine he is local to (by remoteExec
 * from the server at the green light, or his own JUMP): out of his seat or off
 * the hull, put just behind and below the tail with the aircraft's own
 * velocity - the way support_air's jumpers and drop crates leave - so he
 * never meets the airframe. HALO and HAHO: he falls free and opens his own
 * canopy. Static line: the line pulls his round canopy STATIC_OPEN_DELAY
 * after exit (support_air's chuteTick).
 *
 * The server's call (FUNC(srvTick), FUNC(srvEnd)) comes by remoteExec to the
 * man and only the server's word is taken; his own JUMP calls it locally
 * (review S7: it was the `jumpOut` CBA event, which any client could raise to
 * throw anyone out of anything).
 *
 * Arguments:
 * 0: The man <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: Jump type <STRING>
 *
 * Return Value:
 * Out <BOOL>
 *
 * Example:
 * [player, _veh, "STATIC"] call jmfsb_jumpmaster_fnc_jump
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_type", TYPE_HALO, [""]]];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("jump: refused - not from the server (machine %1)",remoteExecutedOwner);
    false
};
if (!alive _unit || {isNull _veh} || {!local _unit}) exitWith {false};
private _standing = attachedTo _unit isEqualTo _veh;
if (!_standing && {vehicle _unit isNotEqualTo _veh}) exitWith {false};

private _at = _veh modelToWorldWorld [random [-EXIT_SIDE, 0, EXIT_SIDE], -((sizeOf typeOf _veh) / 2 + EXIT_TAIL_GAP), -EXIT_BELLY_GAP];
private _vel = velocity _veh;

_unit setVariable [QGVAR(mayJump), false];
private _id = _unit getVariable [QGVAR(action), -1];
if (_id >= 0) then {
    _unit removeAction _id;
    _unit setVariable [QGVAR(action), -1];
};

if (_standing) then {
    detach _unit;
} else {
    unassignVehicle _unit;
    moveOut _unit;
};
_unit setPosASL _at;
_unit setDir getDir _veh;
_unit setVelocity _vel;

if (_type isEqualTo TYPE_STATIC) then {
    [EFUNC(support_air,chuteTick), CHUTE_TICK, [_unit, objNull, CBA_missionTime + STATIC_OPEN_DELAY]] call CBA_fnc_addPerFrameHandler;
};

if (_unit isEqualTo (call CBA_fnc_currentUnit)) then {
    [format ["Out at %1 m.", round ((getPosATL _unit) select 2)]] call FUNC(say);
    // the phone's ALT readout for the fall, off again on the ground
    [true] call FUNC(altWatch);
};
true
