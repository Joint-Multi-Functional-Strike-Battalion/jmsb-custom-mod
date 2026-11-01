#include "script_component.hpp"
/*
 * Author: JMSB
 * The driver's ACE self-interaction on every artillery carrier (every vehicle
 * class with GVAR(weapons)[]): ARTILLERY > Pre-deploy (mark spot), Deploy gun,
 * Pack gun, Clear spot - each shown only when it can be done
 * (FUNC(canAct)). ACE is needed for the menu; without it there is none.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_artydeploy_fnc_addActions
 *
 * Public: No
 */

if (isNil "ace_interact_menu_fnc_createAction") exitWith {};

private _classes = (QUOTE(isArray (_x >> QQGVAR(weapons))) configClasses (configFile >> "CfgVehicles")) apply {configName _x};
if (_classes isEqualTo []) exitWith {};

private _menu = [
    QGVAR(menu), "Artillery", ACTION_ICON, {},
    {params ["_target", "_player"]; driver _target isEqualTo _player}
] call ace_interact_menu_fnc_createAction;

private _steps = [
    [ACT_PRE, "Pre-deploy (mark spot)", {params ["_target", "_player"]; [_target, _player] remoteExecCall [QFUNC(preDeploy), SERVER_OWNER]}],
    [ACT_DEPLOY, "Deploy gun", {params ["_target", "_player"]; [_target, _player] call FUNC(deployStart)}],
    [ACT_PACK, "Pack gun", {params ["_target", "_player"]; [_target, _player] call FUNC(undeployStart)}],
    [ACT_CLEAR, "Clear spot", {params ["_target", "_player"]; [_target, _player] remoteExecCall [QFUNC(clearSpot), SERVER_OWNER]}]
];

{
    private _cls = _x;
    [_cls, 1, ["ACE_SelfActions"], _menu] call ace_interact_menu_fnc_addActionToClass;
    {
        _x params ["_step", "_title", "_code"];
        private _action = [
            format ["%1_%2", QGVAR(step), _step], _title, ACTION_ICON, _code,
            {params ["_target", "_player", "_step"]; [_target, _player, _step] call FUNC(canAct)},
            {}, _step
        ] call ace_interact_menu_fnc_createAction;
        [_cls, 1, ["ACE_SelfActions", QGVAR(menu)], _action] call ace_interact_menu_fnc_addActionToClass;
    } forEach _steps;
} forEach _classes;
