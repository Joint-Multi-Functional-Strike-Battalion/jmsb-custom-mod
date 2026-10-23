#include "script_component.hpp"
/*
 * Author: JMSB
 * Writes the HACK board's LOG: what changed in the suite's session since the
 * last look - a hack started, crossed a quarter, lost and regained range,
 * finished, or was aborted from the board. The session is jmfsb_hacking's;
 * this only watches it, so the log can never claim a step the suite did not
 * take.
 *
 * GVAR(hackLog) is [[daytime, text, alert], ...], oldest first, HACKAPP_LOG_MAX
 * long; a new hack starts it afresh - it is the log of THE current hack.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_tacpad_apps_fnc_appHackTrack
 *
 * Public: No
 */

private _session = missionNamespace getVariable [QEGVAR(hacking,session), createHashMap];
if (count _session == 0) exitWith {};

private _running = _session getOrDefault ["running", false];
private _device = _session getOrDefault ["device", objNull];
private _progress = _session getOrDefault ["progress", 0];
private _quarter = floor (_progress * HACKAPP_LOG_STEPS);
private _inRange = isNull _device || {[_device, _session] call EFUNC(hacking,tabletInRange)};

(uiNamespace getVariable [QGVAR(hackWas), [false, objNull, 0, true]]) params ["_wasRunning", "_wasDevice", "_wasQuarter", "_wasInRange"];

private _fnc_note = {
    params ["_text", ["_alert", false]];
    GVAR(hackLog) pushBack [dayTime, _text, _alert];
    if (count GVAR(hackLog) > HACKAPP_LOG_MAX) then {GVAR(hackLog) deleteAt 0};
};

private _label = "";
{
    if ((_x select 0) isEqualTo _device) exitWith {_label = _x select 2};
} forEach (missionNamespace getVariable [QEGVAR(hacking,devices), []]);

switch (true) do {
    case (_running && !_wasRunning): {
        GVAR(hackLog) = [];
        [format ["STARTED ON %1", [_label, "TARGET"] select (_label isEqualTo "")]] call _fnc_note;
    };
    case (!_running && _wasRunning): {
        if (uiNamespace getVariable [QGVAR(hackAbort), false]) then {
            ["ABORTED - PROGRESS LOST", true] call _fnc_note;
        } else {
            ["COMPLETE"] call _fnc_note;
        };
        uiNamespace setVariable [QGVAR(hackAbort), false];
    };
    case (_running && !_inRange && _wasInRange): {
        ["OUT OF RANGE - HOLDING", true] call _fnc_note;
    };
    case (_running && _inRange && !_wasInRange): {
        ["BACK IN RANGE"] call _fnc_note;
    };
    case (_running && _quarter > _wasQuarter): {
        [format ["%1%2 THROUGH", round (_quarter / HACKAPP_LOG_STEPS * PERCENT), "%"]] call _fnc_note;
    };
};

uiNamespace setVariable [QGVAR(hackWas), [_running, _device, [0, _quarter] select _running, _inRange]];
