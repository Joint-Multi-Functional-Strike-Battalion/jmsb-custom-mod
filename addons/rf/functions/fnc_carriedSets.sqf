#include "script_component.hpp"
/*
 * Author: JMSB
 * The radio sets a man carries, as RF sees them (FUNC(itemProfile)): the set in
 * his radio slot. What a voice adapter registers as his nodes. No radio mod is
 * asked.
 *
 * NO MAN PACKS UNDER GAME VOICE (user, 2026-10-21: "for game voip no
 * manpacks, tfar and acre yes they can have them"). Nothing on his back is a
 * radio here: range away from the bases comes from base stations, vehicles
 * and the mesh of handhelds. TFAR's and ACRE's adapters read their own long
 * range sets, man packs included.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [[kind "sr" | "lr", class, profile], ...] <ARRAY>
 *
 * Example:
 * [player] call jmfsb_rf_fnc_carriedSets // [["sr", "jmfsb_mpu5", "handheld"]]
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};

private _out = [];
{
    private _profile = [_x] call FUNC(itemProfile);
    if (_profile isNotEqualTo "") exitWith {_out pushBack [SET_KIND_SR, _x, _profile]};
} forEach assignedItems _unit;

_out
