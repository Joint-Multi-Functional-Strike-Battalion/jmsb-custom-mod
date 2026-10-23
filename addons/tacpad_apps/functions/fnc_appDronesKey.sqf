#include "script_component.hpp"
/*
 * Author: JMSB
 * What the DRONES board's rows say, as one string. The board redraws only when
 * this changes; continuous values (quality, battery) are stepped to tenths so
 * a drone burning fuel does not rebuild the buttons under a press every two
 * seconds. The feed's own HUD is not in it - FUNC(appDronesCamera) rewrites
 * that in place.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Key <STRING>
 *
 * Example:
 * private _key = [] call jmfsb_tacpad_apps_fnc_appDronesKey
 *
 * Public: No
 */

private _rows = ([] call FUNC(appDronesData)) apply {
    _x params ["_uav", "_name", "_word", "_q", "_batt", "_task", "_mine", "_op", "_can", "", "_why", "_lasing", "_laser", "_mode"];
    [netId _uav, _word, round (_q * DRONES_KEY_STEPS), round (_batt * DRONES_KEY_STEPS), _task, _mine, _op, _can, _why, _lasing, _laser, _mode]
};

private _enemy = if (isNil QEFUNC(hacking,scannerRead) || {!([player] call EFUNC(hacking,hasScanner))}) then {[]} else {
    private _read = [] call EFUNC(hacking,scannerRead);
    [_read param [0, 0], round ((_read param [1, -1]) / DRONES_KEY_RANGE_M), round ((_read param [2, -1]) / DRONES_KEY_BRG_DEG), _read param [7, ""]]
};

str [
    _rows,
    _enemy,
    uiNamespace getVariable [QGVAR(dronesTab), ""],
    netId (uiNamespace getVariable [QGVAR(dronesPick), objNull])
]
