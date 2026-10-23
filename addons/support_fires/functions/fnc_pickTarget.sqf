#include "script_component.hpp"
/*
 * Author: JMSB
 * The best target a loitering munition can see inside its search area, by
 * the module's strike rules - enemy side only.
 *
 *   vehicles - crewed enemy cars, armour, static weapons and boats; the
 *              dearest (config cost) first
 *   infantry - enemy men on foot; the one standing in the biggest group
 *              first, so one munition takes the most men it can
 *   both     - either, and any vehicle outranks any group of men
 *
 * Ties go to the target nearest the requested point. A target another
 * munition of the same launch has already claimed is left to it. The
 * munition must be able to see it.
 *
 * Arguments:
 * 0: The munition <OBJECT>
 * 1: Area centre <ARRAY>
 * 2: Search radius (m) <NUMBER>
 * 3: Strike rule, RULE_* <NUMBER>
 * 4: Enemy side <SIDE>
 * 5: Claimed targets <ARRAY>
 *
 * Return Value:
 * The target, objNull for none <OBJECT>
 *
 * Example:
 * [_uav, _pos, 400, 0, east, []] call jmfsb_support_fires_fnc_pickTarget
 *
 * Public: No
 */

params ["_uav", "_center", "_radius", "_rule", "_enemy", "_claimed"];

private _kinds = [];
if (_rule isNotEqualTo RULE_INFANTRY) then {_kinds append LM_VEHICLE_KINDS};
if (_rule isNotEqualTo RULE_VEHICLES) then {_kinds pushBack "CAManBase"};

private _eye = getPosASL _uav;
private _best = objNull;
private _score = -1;

{
    private _t = _x;
    private _isMan = _t isKindOf "CAManBase";
    private _sideOf = [side _t, side group _t] select _isMan;
    if (
        alive _t
        && _sideOf isEqualTo _enemy
        && {!(_t in _claimed)}
        && {!_isMan || {isNull objectParent _t}}
        && {([_uav, "VIEW", _t] checkVisibility [_eye, aimPos _t]) >= LM_VISIBLE}
    ) then {
        private _s = if (_isMan) then {
            count ((_t nearEntities ["CAManBase", LM_CLUSTER]) select {alive _x && {(side group _x) isEqualTo _enemy}})
        } else {
            // a vehicle's cost runs to thousands; a group of men never does
            1 + getNumber (configOf _t >> "cost")
        };
        if (_s > _score || {_s isEqualTo _score && {(_t distance2D _center) < (_best distance2D _center)}}) then {
            _best = _t;
            _score = _s;
        };
    };
} forEach (_center nearEntities [_kinds, _radius]);

_best
