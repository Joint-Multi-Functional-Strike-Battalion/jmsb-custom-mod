#include "script_component.hpp"
/*
 * Author: YonV
 * Mk383 EMP-M — kinetic EW burst; soft-kills UAVs and blinds optics in radius.
 * Comms-mod integration: search for HOOK comments to connect ACRE2/Drongo EW.
 *
 * Arguments:
 * 0: Firer <OBJECT>
 * 1: Impact position <ARRAY>
 * 2: Effect duration in seconds <NUMBER>
 * 3: Effect radius in metres <NUMBER>
 *
 * Return Value:
 * None
 *
 * Public: No
 */
params [
    ["_unit",   objNull, [objNull]],
    ["_pos",    [0,0,0], [[]]],
    ["_dur",    8,       [0]],
    ["_radius", 60,      [0]]
];
// Soft-kill EW burst — no kinetic explosion; the round is delivered by chute.

{
    if (unitIsUAV _x) then {
        if (local _x) then {
            _x setDamage 0.9;
        } else {
            [_x, 0.9] remoteExec ["setDamage", _x];
        };
    };
} forEach (_pos nearEntities [["Air", "UAV"], _radius]);

{
    if (local _x && {hasInterface}) then {
        "dynamicBlur" ppEffectEnable true;
        "dynamicBlur" ppEffectAdjust [6]; "dynamicBlur" ppEffectCommit 0.1;
        [{ "dynamicBlur" ppEffectAdjust [0]; "dynamicBlur" ppEffectCommit 1.5 }, [], _dur] call CBA_fnc_waitAndExecute;
        ["EMP", "Systems disrupted.", [1, 0.776, 0.102, 1]] call EFUNC(notify,notify);
    };
    // HOOK: Drongo EW jam call on _x here
    if (GVAR(hasDEW)) then {};
    // HOOK: comms jam on _x here
    if (GVAR(hasACRE)) then {};
} forEach (
    (_pos nearEntities [["Man"], _radius]) select {
        [side group _unit, side group _x] call BIS_fnc_sideIsEnemy
    }
);
