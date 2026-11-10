#include "..\script_component.hpp"
/*
 * Author: YonV
 * An instructor's target board: the controller gets a Targets menu with
 * All up, All down and one entry per group, which raises that group. The
 * targets start down, and a hit target stays down until the instructor
 * raises it again. For lanes where the instructor picks what pops - the MG
 * range - rather than a scored run (JMSB - Shooting Range).
 *
 * Call from the controller's init field. Targets can be objects or their
 * variable names; names are looked up when used, so init order does not
 * matter.
 *
 * Arguments:
 * 0: Controller <OBJECT>
 * 1: Groups - [label, [targets]] each <ARRAY>
 *
 * Return Value: None
 *
 * Example:
 * [this, [["Left 1", ["mg_t1", "mg_t2"]], ["Far", ["mg_t9"]]]] call jmfsb_range_fnc_targetGroups
 *
 * Public: Yes
 */

params [["_ctrl", objNull, [objNull]], ["_groups", [], [[]]]];

if (isNull _ctrl || {_groups isEqualTo []}) exitWith {
    WARNING_1("targetGroups: nothing to do on %1",_ctrl);
};

private _all = [];
private _entries = [];
{
    _x params [["_label", "", [""]], ["_targets", [], [[]]]];
    {_all pushBackUnique _x} forEach _targets;
    _entries pushBack [_forEachIndex, _label, _targets, TARGET_UP];
} forEach _groups;

// Down to start, once, by the server - not again for each player who joins.
if (isServer) then {
    [{
        {
            private _target = [_x] call FUNC(resolve);
            if (!isNull _target) then {
                _target setVariable [QGVAR(stayDown), true, true];
                [_target, TARGET_DOWN] call FUNC(setTarget);
            };
        } forEach _this;
    }, _all] call CBA_fnc_execNextFrame;
};

if (!hasInterface) exitWith {};
if (!isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {};

private _fnc_set = {
    params ["", "", "_args"];
    _args params ["_targets", "_state"];
    {
        private _target = [_x] call FUNC(resolve);
        if (!isNull _target) then {
            _target setVariable [QGVAR(stayDown), true, true];
            [_target, _state] call FUNC(setTarget);
        };
    } forEach _targets;
};

private _root = [QGVAR(groups), "Targets", ACE_ICON, {}, {true}] call ace_interact_menu_fnc_createAction;
[_ctrl, 0, ["ACE_MainActions"], _root] call ace_interact_menu_fnc_addActionToObject;
private _path = ["ACE_MainActions", QGVAR(groups)];

{
    _x params ["_id", "_label", "_targets", "_state"];
    private _action = [format [QGVAR(groups_%1), _id], _label, "", _fnc_set, {true}, {}, [_targets, _state]] call ace_interact_menu_fnc_createAction;
    [_ctrl, 0, _path, _action] call ace_interact_menu_fnc_addActionToObject;
} forEach ([["up", "All up", _all, TARGET_UP], ["down", "All down", _all, TARGET_DOWN]] + _entries);
