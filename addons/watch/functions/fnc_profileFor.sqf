#include "script_component.hpp"
/*
 * Author: YonV
 * The profile the action key would add a target to: the first, by order, that
 * the player has (its gate) and that takes the target (its accepts).
 *
 * Arguments:
 * 0: Target <OBJECT>
 *
 * Return Value:
 * Profile id, "" for none <STRING>
 *
 * Example:
 * [cursorObject] call jmfsb_watch_fnc_profileFor
 *
 * Public: No
 */

params [["_target", objNull, [objNull]]];

if (isNull _target) exitWith {""};

private _order = (keys GVAR(profiles)) apply {[(GVAR(profiles) get _x) getOrDefault ["order", 0], _x]};
_order sort true;
private _hit = "";
{
    private _spec = GVAR(profiles) get (_x # 1);
    if ([player] call (_spec getOrDefault ["gate", {false}]) && {[_target] call (_spec getOrDefault ["accepts", {false}])}) exitWith {
        _hit = _x # 1;
    };
} forEach _order;
_hit
