#include "script_component.hpp"
/*
 * Author: YonV
 * Mk388 JAM — area comms/GNSS jammer; enemy UAVs in radius lose their AI link.
 * Comms-mod integration: search for HOOK comments to connect ACRE2/Drongo EW.
 *
 * Arguments:
 * 0: Firer <OBJECT>
 * 1: Impact position <ARRAY>
 * 2: Lifetime in seconds <NUMBER>
 * 3: Jam radius in metres <NUMBER>
 *
 * Return Value:
 * None
 *
 * Public: No
 */
params [
    ["_unit",   objNull, [objNull]],
    ["_pos",    [0,0,0], [[]]],
    ["_life",   900,     [0]],
    ["_radius", 400,     [0]]
];
private _side = side group _unit;
private _j = createVehicle ["Land_PortableLongRangeAntenna_01_sand_F", _pos, [], 0, "CAN_COLLIDE"];
_j setVariable ["jmfsb_fa_grenade_40mm_jammer", true, true];

[{
    params ["_args", "_h"];
    _args params ["_j", "_side", "_radius", "_end"];
    if (isNull _j || {time > _end}) exitWith {
        if (!isNull _j) then { deleteVehicle _j };
        _h call CBA_fnc_removePerFrameHandler;
    };
    {
        if (unitIsUAV _x && {[_side, side group _x] call BIS_fnc_sideIsEnemy}) then {
            if (local _x) then {
                private _uav = _x;
                { _uav disableAI _x } forEach ["MOVE", "TARGET", "AUTOTARGET"];
                _x setVariable ["jmfsb_fa_grenade_40mm_jammed", true];
            } else {
                [_x, ["MOVE","TARGET","AUTOTARGET"]] remoteExec ["jmfsb_fa_grenade_40mm_fnc_jamUAV", _x];
            };
        };
    } forEach (getPos _j nearEntities [["Air","UAV"], _radius]);
    // HOOK: Drongo EW area jam at getPos _j
    if (GVAR(hasDEW)) then {};
    // HOOK: enemy comms jam in radius
    if (GVAR(hasACRE)) then {};
}, 1, [_j, _side, _radius, time + _life]] call CBA_fnc_addPerFrameHandler;

[_unit, "Area Jammer", format ["Active - %1 m bubble", _radius], [1, 0.776, 0.102, 1]] call FUNC(notify);
