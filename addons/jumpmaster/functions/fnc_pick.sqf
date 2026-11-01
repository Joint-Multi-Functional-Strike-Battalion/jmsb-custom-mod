#include "script_component.hpp"
/*
 * Author: JMSB
 * PICK PATH ON MAP: the RED LIGHT point, then the GREEN LIGHT point, pressed
 * onto the host map. The page closes and the map is claimed through the
 * tacpad (EGVAR(tacpad,appMapClaim)) the way TAC//SUPPORT claims it, so the
 * presses are this app's. Right click cancels; it ends itself when the map
 * closes, another app opens, or nothing is pressed for JM_PICK_S. The
 * aircraft flies the line through the two points, red to green.
 *
 * Arguments:
 * 0: Mode - "arm" (start picking), "click" (a map press), "drop" (end) <STRING>
 * 1: Mode arguments - click: [map, button, x, y]; drop: [why] <ARRAY> (optional, default [])
 *
 * Return Value:
 * arm: picking <BOOL>; click: handled <BOOL>; drop: none
 *
 * Example:
 * ["arm"] call jmfsb_jumpmaster_fnc_pick
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
        uiNamespace setVariable [QGVAR(pickUntil), diag_tickTime + JM_PICK_S];
        uiNamespace setVariable [QGVAR(pickStep), 0];
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
        }, JM_PICK_TICK, []] call CBA_fnc_addPerFrameHandler];

        ["Press the map for the RED LIGHT point, then the GREEN LIGHT point. Right click cancels."] call FUNC(say);
        true
    };

    case "click": {
        _args params ["_map", "_button", "_mx", "_my"];
        if ((uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isNotEqualTo CLAIM) exitWith {false};
        private _reopen = {{[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame};
        if (_button isEqualTo MOUSE_CANCEL) exitWith {
            ["drop", ["Pick cancelled."]] call FUNC(pick);
            call _reopen;
            false
        };
        if (_button isNotEqualTo MOUSE_PICK) exitWith {false};

        private _world = _map ctrlMapScreenToWorld [_mx, _my];
        private _pos = [_world select 0, _world select 1, 0];
        if ((uiNamespace getVariable [QGVAR(pickStep), 0]) isEqualTo 0) exitWith {
            GVAR(red) = _pos;
            GVAR(green) = [];
            uiNamespace setVariable [QGVAR(pickStep), 1];
            uiNamespace setVariable [QGVAR(pickUntil), diag_tickTime + JM_PICK_S];
            [format ["RED LIGHT at %1. Now press the GREEN LIGHT point.", [_pos] call EFUNC(maptools,gridText)]] call FUNC(say);
            false
        };
        GVAR(green) = _pos;
        ["drop", [format ["GREEN LIGHT at %1. Path set.", [_pos] call EFUNC(maptools,gridText)]]] call FUNC(pick);
        call _reopen;
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
