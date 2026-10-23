#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the rope ACE asks for in a transport that may fast-rope, so the
 * players in its cabin can deploy ropes themselves (ROPE_CLASS, ROPE_STOCK -
 * script_component.hpp says why). Tops the cargo up to ROPE_STOCK rather
 * than adding to it, so it is safe to call at every launch, adoption and
 * FASTROPE order. Never touches the requireRopeItems setting.
 *
 * Only for a module that offers FASTROPE and an airframe that can rope
 * (FUNC(canRope)); anything else is left as it is.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The helicopter <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh] call jmfsb_support_air_fnc_stockRopes
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]]];

if (!isServer || isNull _logic || !alive _veh) exitWith {};
if !(TASK_FASTROPE in (_logic getVariable [QGVAR(allowed), []])) exitWith {};
if !([typeOf _veh] call FUNC(canRope)) exitWith {};

if !(isClass (configFile >> "CfgWeapons" >> ROPE_CLASS)) exitWith {
    WARNING_1("rope item '%1' is not a class - transport not stocked",ROPE_CLASS);
};

private _have = {_x isEqualTo ROPE_CLASS} count itemCargo _veh;
if (_have < ROPE_STOCK) then {
    _veh addItemCargoGlobal [ROPE_CLASS, ROPE_STOCK - _have];
    TRACE_2("ropes stocked",_veh,ROPE_STOCK - _have);
};
