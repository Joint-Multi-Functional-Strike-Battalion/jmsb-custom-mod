#include "script_component.hpp"
/*
 * Author: JMSB
 * PICK ON MAP: waypoints pressed onto the host map, in order, one after
 * another (user, 2026-10-30: "an add to keep adding waypoints"). The page
 * closes and the map is claimed through the tacpad (EGVAR(tacpad,appMapClaim))
 * the way TAC//SUPPORT and the drones' GO TO claim it, so the presses are this
 * app's and the map tools stand aside. Left adds a waypoint, right ends and
 * brings the page back; it ends itself when the map closes, another app
 * opens, or nothing is pressed for PM_PICK_S.
 *
 * Arguments:
 * 0: Mode - "arm" (start picking), "click" (a map press), "drop" (end) <STRING>
 * 1: Mode arguments - click: [map, button, x, y]; drop: [why] <ARRAY> (optional, default [])
 *
 * Return Value:
 * arm: picking <BOOL>; click: handled <BOOL>; drop: none
 *
 * Example:
 * ["arm"] call jmfsb_pointman_fnc_pick
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_args", [], [[]]]];

switch (_mode) do {
    case "arm": {
        private _display = HOST_DISPLAY;
        private _map = if (isNull _display) then {controlNull} else {_display displayCtrl IDC_HOST_MAP};
        if (isNull _map) exitWith {
            ["No map to pick on.", "high"] call FUNC(say);
            false
        };

        [] call EFUNC(tacpad,appClose);
        uiNamespace setVariable [QGVAR(pickUntil), diag_tickTime + PM_PICK_S];
        uiNamespace setVariable [QEGVAR(tacpad,appMapClaim), CLAIM];
        [_map] call FUNC(attach);

        if !(_map getVariable [QGVAR(pickWired), false]) then {
            _map setVariable [QGVAR(pickWired), true];
            _map ctrlAddEventHandler ["MouseButtonDown", {
                params ["_map", "_button", "_mx", "_my"];
                ["click", [_map, _button, _mx, _my]] call FUNC(pick)
            }];
        };

        private _pfh = uiNamespace getVariable [QGVAR(pickPfh), -1];
        if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
        uiNamespace setVariable [QGVAR(pickPfh), [{
            params ["", "_handle"];
            private _why = switch (true) do {
                case ((uiNamespace getVariable [QGVAR(pickUntil), 0]) isEqualTo 0): {""};
                case ((uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isNotEqualTo CLAIM): {""};
                case ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isNotEqualTo ""): {""};
                case (isNull HOST_DISPLAY || {HOST_NATIVE && !visibleMap}): {"Pick ended: the map closed."};
                case (diag_tickTime > (uiNamespace getVariable [QGVAR(pickUntil), 0])): {"Pick ended: nothing pressed."};
                default {nil};
            };
            if (isNil "_why") exitWith {};
            [_handle] call CBA_fnc_removePerFrameHandler;
            uiNamespace setVariable [QGVAR(pickPfh), -1];
            ["drop", [_why]] call FUNC(pick);
        }, PM_PICK_TICK, []] call CBA_fnc_addPerFrameHandler];

        ["Press the map to add waypoints, in order. Right click ends."] call FUNC(say);
        true
    };

    case "click": {
        _args params ["_map", "_button", "_mx", "_my"];
        if ((uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isNotEqualTo CLAIM) exitWith {false};
        if (_button isEqualTo MOUSE_CANCEL) exitWith {
            ["drop", ["Pick ended."]] call FUNC(pick);
            {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            false
        };
        if (_button isNotEqualTo MOUSE_PICK) exitWith {false};

        private _i = [_map ctrlMapScreenToWorld [_mx, _my]] call FUNC(add);
        if (_i >= 0) then {
            uiNamespace setVariable [QGVAR(pickUntil), diag_tickTime + PM_PICK_S];
            [format ["WP %1 added at %2.", _i + 1, (GVAR(waypoints) select _i) select WP_LABEL]] call FUNC(say);
        };
        false
    };

    case "drop": {
        _args params [["_why", "", [""]]];
        uiNamespace setVariable [QGVAR(pickUntil), 0];
        if ((uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isEqualTo CLAIM) then {
            uiNamespace setVariable [QEGVAR(tacpad,appMapClaim), ""];
        };
        [_why] call FUNC(say);
    };

    default {
        WARNING_1("pick: unknown mode '%1'",_mode);
        false
    };
};
