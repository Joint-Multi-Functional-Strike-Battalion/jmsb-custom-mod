#include "script_component.hpp"
/*
 * Author: YonV
 * Mk380 NR-P — deploys a data-link relay that extends the network in a 5 km radius.
 * Comms-mod integration: search for HOOK comments to connect ACRE2.
 *
 * Arguments:
 * 0: Firer <OBJECT>
 * 1: Deploy position <ARRAY>
 * 2: Lifetime in seconds <NUMBER>
 * 3: Link radius in metres <NUMBER>
 *
 * Return Value:
 * None
 *
 * Public: No
 */
params [
    ["_unit",   objNull, [objNull]],
    ["_pos",    [0,0,0], [[]]],
    ["_life",   1800,    [0]],
    ["_radius", 5000,    [0]]
];
private _obj = createVehicle ["Land_TripodScreen_01_dual_v1_F", _pos, [], 0, "CAN_COLLIDE"];
_obj setVariable ["jmfsb_fa_grenade_40mm_relay", true, true];
GVAR(relays) pushBack _obj;

// HOOK: spawn ACRE2 relay (acre_api_fnc_*) here
if (GVAR(hasACRE)) then {};

[_unit, "NR-P Relay", format ["Online - %1 m link radius", _radius], [0.4, 0.702, 0.4, 1]] call FUNC(notify);
[{ params ["_o"]; if (!isNull _o) then { deleteVehicle _o } }, [_obj], _life] call CBA_fnc_waitAndExecute;
