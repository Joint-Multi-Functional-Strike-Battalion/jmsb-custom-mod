#include "script_component.hpp"
/*
 * Author: JMSB
 * The readiness check (user, 2026-10-30: "team members must have a halo
 * mask, and parachute"): every living man of the player's group, whether he
 * wears a mask of the setting's classes (HALO and HAHO only - a static line
 * needs none) and carries a parachute of the setting's classes.
 *
 * Arguments:
 * 0: Jump type <STRING>
 *
 * Return Value:
 * 0: Rows, [unit, name, mask ok, chute ok] each <ARRAY>
 * 1: Everyone ready, and there is someone <BOOL>
 * 2: How many are not <NUMBER>
 *
 * Example:
 * (["HALO"] call jmfsb_jumpmaster_fnc_ready) params ["_rows", "_ready", "_missing"]
 *
 * Public: No
 */

params [["_type", TYPE_HALO, [""]]];

private _masks = [GVAR(maskClasses)] call FUNC(classList);
private _chutes = [GVAR(chuteClasses)] call FUNC(classList);
private _needMask = _type in FREEFALL_TYPES;

private _rows = ((units group (call CBA_fnc_currentUnit)) select {alive _x}) apply {
    [_x, name _x, !_needMask || {(goggles _x) in _masks}, (backpack _x) in _chutes]
};
private _missing = {!(_x select 2) || {!(_x select 3)}} count _rows;

[_rows, _rows isNotEqualTo [] && _missing isEqualTo 0, _missing]
