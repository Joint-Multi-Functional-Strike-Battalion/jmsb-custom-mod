#include "script_component.hpp"
/*
 * Author: YonV
 * One man rappels from a hovering transport (user, 2026-11-08: "a simplex like
 * repel" - Simplex's idea, no code of it used): out of the cabin onto the rope
 * on his side, RAPPEL_SIDE m out (FUNC(rappelRopes)), and down it at
 * RAPPEL_SPEED m/s under the rope's top as the airframe moves, kept from harm
 * on the way; off it under RAPPEL_FOOT m above what is below him, or put on
 * the ground after RAPPEL_MAX_S s. Called where he is local - a player on his
 * own machine (FUNC(transportStep)).
 *
 * Arguments:
 * 0: The man <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: Side - 0 left, 1 right <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _veh, 0] call jmfsb_support_air_fnc_rappel
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_side", 0, [0]]];

if (!local _unit || {!alive _unit} || {vehicle _unit isNotEqualTo _veh}) exitWith {};

private _offset = [[-RAPPEL_SIDE, RAPPEL_SIDE] select (_side isEqualTo 1), 0, 0];
private _damage = isDamageAllowed _unit;
_unit allowDamage false;
moveOut _unit;
private _top = _veh modelToWorldVisualWorld _offset;
_unit setPosASL (_top vectorAdd [0, 0, -1]);
_unit setDir getDir _veh;

[{
    params ["_args", "_handle"];
    _args params ["_unit", "_veh", "_offset", "_damage", "_started"];
    private _done = !alive _unit || {((getPos _unit) select 2) < RAPPEL_FOOT} || {CBA_missionTime - _started > RAPPEL_MAX_S};
    if (_done) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        if (alive _unit && {((getPos _unit) select 2) >= RAPPEL_FOOT}) then {
            (getPosATL _unit) params ["_px", "_py"];
            _unit setPosATL [_px, _py, 0];
        };
        _unit setVelocity [0, 0, 0];
        _unit allowDamage _damage;
    };
    // down the rope, under its top wherever the airframe drifts
    private _at = getPosASL _unit;
    private _top = [_veh modelToWorldVisualWorld _offset, _at] select (!alive _veh);
    _unit setPosASL [_top select 0, _top select 1, (_at select 2) - RAPPEL_SPEED * diag_deltaTime];
    _unit setVelocity [0, 0, -RAPPEL_SPEED];
}, 0, [_unit, _veh, _offset, _damage, CBA_missionTime]] call CBA_fnc_addPerFrameHandler;
