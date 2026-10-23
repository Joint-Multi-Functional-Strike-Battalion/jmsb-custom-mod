#include "script_component.hpp"
/*
 * Author: JMSB
 * GO TO's point, picked on the host's own map - the vanilla map or the
 * tablet's screen (IDC_HOST_MAP on both). The board steps aside for it: the
 * app closes so the map is there to click, and the board CLAIMS the map
 * (EGVAR(tacpad,appMapClaim)) the way TAC//SUPPORT does, so the press is a
 * pick and not "close the app" (EFUNC(tacpad,appExits)) and the map tools
 * stand down (jmfsb_maptools_fnc_hasInput).
 *
 *   "arm"    [drone]: closes the app, claims the map, wires the map's press
 *            once per control and starts the watchdog
 *   "click"  [map, button, x, y] from the map's MouseButtonDown: a left press
 *            sends the drone there (EFUNC(devices,uavOrder) "goto", through
 *            the gate again); a right press cancels. Either way the claim is
 *            let go and the board comes back.
 *   "drop"   [reason] lets the claim go, saying why when there is a reason
 *
 * THE WATCHDOG lets go by itself every DRONES_PICK_TICK when nothing was
 * picked in DRONES_PICK_S, the drone is gone, another app took the screen or
 * the claim, or the host closed (the map shut, the tablet put away) - a claim
 * left behind is a map whose clicks never close an app again.
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Drone, for "arm" <OBJECT> (optional, default objNull)
 * 2: Mode arguments <ARRAY> (optional, default [])
 *
 * Return Value:
 * "arm": armed <BOOL>; "click": false (the press is not consumed); "drop": nothing
 *
 * Example:
 * ["arm", _uav] call jmfsb_tacpad_apps_fnc_appDronesPick
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_uav", objNull, [objNull]], ["_args", [], [[]]]];

private _fnc_say = {
    params ["_text", ["_level", "high"]];
    if (_text isEqualTo "") exitWith {};
    ["DRONES", _text, _level] call EFUNC(messaging,notify);
};

switch (_mode) do {
    case "arm": {
        private _display = HOST_DISPLAY;
        private _map = if (isNull _display) then {controlNull} else {_display displayCtrl IDC_HOST_MAP};
        if (isNull _map) exitWith {
            ["No map to pick the point on."] call _fnc_say;
            false
        };

        [] call EFUNC(tacpad,appClose);
        uiNamespace setVariable [QGVAR(dronesGoto), [_uav, diag_tickTime + DRONES_PICK_S, _display]];
        uiNamespace setVariable [QEGVAR(tacpad,appMapClaim), "drones"];

        if !(_map getVariable [QGVAR(dronesPickWired), false]) then {
            _map setVariable [QGVAR(dronesPickWired), true];
            _map ctrlAddEventHandler ["MouseButtonDown", {
                params ["_map", "_button", "_mx", "_my"];
                ["click", objNull, [_map, _button, _mx, _my]] call FUNC(appDronesPick)
            }];
        };

        private _pfh = uiNamespace getVariable [QGVAR(dronesPickPFH), -1];
        if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
        uiNamespace setVariable [QGVAR(dronesPickPFH), [{
            params ["", "_handle"];
            (uiNamespace getVariable [QGVAR(dronesGoto), []]) params [["_uav", objNull], ["_until", 0], ["_display", displayNull]];

            private _why = switch (true) do {
                case (isNull _uav && _until isEqualTo 0): {""};
                case ((uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isNotEqualTo "drones"): {""};
                case ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isNotEqualTo ""): {""};
                case (isNull _display || (HOST_NATIVE && !visibleMap)): {"GO TO cancelled."};
                case (!alive _uav): {"That drone is gone."};
                case (diag_tickTime > _until): {"GO TO timed out - no point picked."};
                default {nil};
            };
            if (isNil "_why") exitWith {};

            [_handle] call CBA_fnc_removePerFrameHandler;
            uiNamespace setVariable [QGVAR(dronesPickPFH), -1];
            ["drop", objNull, [_why]] call FUNC(appDronesPick);
        }, DRONES_PICK_TICK, []] call CBA_fnc_addPerFrameHandler];

        ["GO TO: click the map for the point. Right click cancels.", "normal"] call _fnc_say;
        true
    };

    case "click": {
        _args params ["_map", "_button", "_mx", "_my"];
        if ((uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isNotEqualTo "drones") exitWith {false};
        (uiNamespace getVariable [QGVAR(dronesGoto), []]) params [["_target", objNull]];
        if !(_button in [DRONES_MOUSE_PICK, DRONES_MOUSE_CANCEL]) exitWith {false};

        private _reopen = {
            {["drones", [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        };

        if (_button isEqualTo DRONES_MOUSE_CANCEL) exitWith {
            ["drop", objNull, ["GO TO cancelled."]] call FUNC(appDronesPick);
            call _reopen;
            false
        };

        private _world = _map ctrlMapScreenToWorld [_mx, _my];
        ["drop", objNull, [""]] call FUNC(appDronesPick);
        call _reopen;

        // Through the gate again: the link may have gone while he looked.
        if (isNil QEFUNC(devices,uavOrder) || {(["linked"] call EFUNC(devices,uavControl)) isNotEqualTo _target}) exitWith {
            ["Connect to the drone first."] call _fnc_say;
            false
        };
        ([_target] call EFUNC(devices,uavCan)) params ["_ok", "_why"];
        if (!_ok) exitWith {
            [_why] call _fnc_say;
            false
        };

        private _point = [_world select 0, _world select 1, 0];
        (["goto", _target, [_point, DRONES_ORBIT_RADIUS]] call EFUNC(devices,uavOrder)) params ["_sent", "_refused"];
        if (_sent) then {
            [format ["Flying to %1, then loitering.", mapGridPosition _point], "normal"] call _fnc_say;
        } else {
            [_refused] call _fnc_say;
        };
        false
    };

    case "drop": {
        _args params [["_why", "", [""]]];
        uiNamespace setVariable [QGVAR(dronesGoto), []];
        if ((uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isEqualTo "drones") then {
            uiNamespace setVariable [QEGVAR(tacpad,appMapClaim), ""];
        };
        [_why] call _fnc_say;
    };

    default {
        WARNING_1("appDronesPick: unknown mode '%1'",_mode);
        false
    };
};
