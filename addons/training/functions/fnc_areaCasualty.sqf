#include "script_component.hpp"
/*
 * Author: YonV
 * A trainee down - killed or unconscious - counted against every live training
 * area he is inside (FUNC(areaState)'s after-action casualties). Server only.
 *
 * Arguments:
 * 0: The trainee <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit] call jmfsb_training_fnc_areaCasualty
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isServer || {isNull _unit}) exitWith {};

{
    private _marker = _x # 0;
    if (_unit inArea (_x select [3, 5]) && {(([_marker] call FUNC(areaState)) # 0) isEqualTo "live"}) then {
        [_marker, "casualty"] call FUNC(areaState);
    };
} forEach ([] call FUNC(areas));
