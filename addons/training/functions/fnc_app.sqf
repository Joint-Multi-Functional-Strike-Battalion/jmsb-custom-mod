#include "script_component.hpp"
/*
 * Author: YonV
 * TAC//TRAINING (user, 2026-11-07): the trainer's app on the training server,
 * for the Trainer skill and Sergeant and up (FUNC(access)). Three tabs:
 *
 *     PATIENTS        casualties on the stretchers for the medics to treat -
 *                     a preset or wound by wound (FUNC(appPatients))
 *     TRAINING AREAS  the ta_* areas: what each one is, the enemy to put in
 *                     it, what is happening there, and the after-action
 *                     numbers (FUNC(appAreas))
 *     VEHICLE RANGES  moving targets with no ammo, edge to edge and back
 *                     (FUNC(appVehicles))
 *
 * It redraws itself every APP_REFRESH seconds while open, through the
 * appAlive / appIdle pair every live app uses.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["training", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

([_display, "TRAINING", APP_W, APP_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

if !([player] call FUNC(access)) exitWith {
    ([] call EFUNC(tacpad,theme)) params ["", "", "_accent"];
    private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
    [_body, [PAD * HOST_W, PAD * HOST_H, (ctrlPosition _body) # 2, _rowH * 2],
        "TRAINERS AND SERGEANTS UP, ON THE TRAINING SERVER", _accent, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
};

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _w = (ctrlPosition _body) # 2;
private _tab = uiNamespace getVariable [QGVAR(tab), TAB_MEDICAL];
[_body, [0, 0, _w, _rowH], TRAINING_TABS, _tab, QGVAR(tab), APP_ID] call EFUNC(tacpad_apps,appPageTabs);

switch (_tab) do {
    case TAB_AREAS: {[_body, _rowH + PAD * HOST_H] call FUNC(appAreas)};
    case TAB_VEHICLES: {[_body, _rowH + PAD * HOST_H] call FUNC(appVehicles)};
    default {[_body, _rowH + PAD * HOST_H] call FUNC(appPatients)};
};

if (GVAR(pfh) >= 0) then {
    [GVAR(pfh)] call CBA_fnc_removePerFrameHandler;
    GVAR(pfh) = -1;
};
GVAR(pfh) = [{
    params ["", "_handle"];
    if !([APP_ID] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        GVAR(pfh) = -1;
    };
    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    [APP_ID] call EFUNC(tacpad,openApp);
}, APP_REFRESH, []] call CBA_fnc_addPerFrameHandler;
