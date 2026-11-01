#include "script_component.hpp"
/*
 * Author: JMSB
 * Registers a Zeus (ZEN) custom module that drops a set of Patrol Base Kit items
 * at the placement position, so a player can build a base there.
 * No-op if Zeus Enhanced isn't loaded.
 *
 * Arguments: None
 * Return Value: None
 *
 * Public: No
 */

if (isNil "zen_custom_modules_fnc_register") exitWith {};

private _icon = "\A3\ui_f\data\IGUI\Cfg\simpleTasks\types\meet_ca.paa";

[
    "1st Joint Multi-Functional Strike Battalion",
    "Drop Patrol Base Kits",
    {
        // ZEN passes [position, object-under-cursor] - verified against
        // zen_custom_modules\fnc_init.sqf: `[_position, _attached] call _function`.
        private _pos = _this param [0, [], [[]]];
        if (_pos isEqualTo [] || {count _pos < 2}) then {
            _pos = call zen_common_fnc_getMousePosition;
        };
        if (_pos isEqualTo [] || {count _pos < 2}) exitWith {
            ["Patrol Base", "Could not read a drop position.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
        };

        // BY remoteExec, NOT A CBA SERVER EVENT (review S7): a CBA event
        // carries no sender, so the server could not tell a Zeus from anyone
        // else. A mission that whitelists CfgRemoteExec must list
        // jmfsb_patrol_base_fnc_dropKits, or the drop is silently dropped.
        [_pos] remoteExecCall [QFUNC(dropKits), SERVER_OWNER];
        diag_log text format ["[jmfsb_patrol_base] zeus drop requested at %1", mapGridPosition _pos];
    },
    _icon
] call zen_custom_modules_fnc_register;
