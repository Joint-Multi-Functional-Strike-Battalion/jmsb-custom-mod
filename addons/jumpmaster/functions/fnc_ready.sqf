#include "script_component.hpp"
/*
 * Author: YonV
 * The readiness check (user, 2026-10-30: "team members must have a halo
 * mask, and parachute"): how many of the stick carry no parachute of the
 * setting's classes, and - HALO and HAHO only, a static line needs none - how
 * many wear no mask of the setting's. Asked by the server at the JUMP
 * REQUEST's receipt (FUNC(srvThread), 2026-11-02): either above 0 is the
 * CANTCO's reason ("2 MEN WITHOUT A PARACHUTE").
 *
 * Arguments:
 * 0: The stick <ARRAY of OBJECTs>
 * 1: Jump type <STRING>
 *
 * Return Value:
 * 0: Men without a parachute <NUMBER>
 * 1: Men without a mask <NUMBER>
 *
 * Example:
 * ([units group player, "HALO"] call jmfsb_jumpmaster_fnc_ready) params ["_noChute", "_noMask"]
 *
 * Public: No
 */

params [["_men", [], [[]]], ["_type", TYPE_HALO, [""]]];

private _masks = [GVAR(maskClasses)] call FUNC(classList);
private _chutes = [GVAR(chuteClasses)] call FUNC(classList);

private _noChute = {!((backpack _x) in _chutes)} count _men;
private _noMask = 0;
if (_type in FREEFALL_TYPES) then {
    _noMask = {!((goggles _x) in _masks)} count _men;
};

[_noChute, _noMask]
