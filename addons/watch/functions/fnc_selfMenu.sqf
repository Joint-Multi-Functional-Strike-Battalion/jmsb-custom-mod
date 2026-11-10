#include "script_component.hpp"
/*
 * Author: YonV
 * The ACE self-interaction WATCH menu's children: one entry per watched slot,
 * each with the profile's actions in the design's fixed order - REPORT (when
 * the profile has one), PIN / UNPIN (pinned slots skip the auto-clear), CLEAR -
 * then ALL OFF. The walking view takes no mouse, so the per-slot actions live
 * here; the F-keys do the current profile's.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ACE child actions <ARRAY>
 *
 * Example:
 * [] call jmfsb_watch_fnc_selfMenu
 *
 * Public: No
 */

private _out = [];
{
    private _id = _x;
    private _spec = GVAR(profiles) getOrDefault [_id, createHashMap];
    private _row = _spec getOrDefault ["row", {[]}];
    {
        _x params ["_target", "_pinned"];
        if (isNull _target) then {continue};
        private _label = format ["%1 %2: %3", toUpper (_spec getOrDefault ["name", _id]), _forEachIndex + 1, ([_target] call _row) param [0, name _target]];
        private _slot = [format ["%1_%2_%3", QGVAR(slot), _id, _forEachIndex], _label, "", {}, {true}, {
            (_this select 2) params ["_id", "_target", "_pinned"];
            private _spec = GVAR(profiles) getOrDefault [_id, createHashMap];
            private _kids = [];
            if ((_spec getOrDefault ["report", {}]) isNotEqualTo {}) then {
                _kids pushBack [[QGVAR(report), "Report", "", {(_this select 2) params ["_spec", "_target"]; [_target] call (_spec get "report")}, {true}, {}, [_spec, _target]] call ace_interact_menu_fnc_createAction, [], _target];
            };
            _kids pushBack [[QGVAR(pin), ["Pin", "Unpin"] select _pinned, "", {
                (_this select 2) params ["_id", "_target"];
                private _slot = (GVAR(slots) getOrDefault [_id, []]) select {(_x # 0) isEqualTo _target};
                if (_slot isNotEqualTo []) then {(_slot # 0) set [1, !((_slot # 0) # 1)]};
            }, {true}, {}, [_id, _target]] call ace_interact_menu_fnc_createAction, [], _target];
            // the profile's own, in the design's order between pin and clear (map, share)
            {
                _x params ["_label", "_code"];
                _kids pushBack [[format ["%1_%2", QGVAR(act), _forEachIndex], _label, "", {(_this select 2) params ["_code", "_target"]; [_target] call _code}, {true}, {}, [_code, _target]] call ace_interact_menu_fnc_createAction, [], _target];
            } forEach (_spec getOrDefault ["actions", []]);
            _kids pushBack [[QGVAR(clear), "Clear", "", {(_this select 2) params ["_id", "_target"]; [_id, _target] call FUNC(toggle)}, {true}, {}, [_id, _target]] call ace_interact_menu_fnc_createAction, [], _target];
            _kids
        }, [_id, _target, _pinned]] call ace_interact_menu_fnc_createAction;
        _out pushBack [_slot, [], player];
    } forEach _y;
} forEach GVAR(slots);

_out pushBack [[QGVAR(allOff), "All off", "", {[] call FUNC(allOff)}, {true}] call ace_interact_menu_fnc_createAction, [], player];
_out
