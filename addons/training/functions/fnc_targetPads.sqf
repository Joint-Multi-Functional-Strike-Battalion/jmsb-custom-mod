#include "..\script_component.hpp"
/*
 * Author: YonV
 * Target vehicles or men on pads, with a Reset targets entry on the
 * controller. The server puts one of each class on its pad at start; Reset
 * replaces any that are damaged or gone. Targets are locked, empty, unarmed
 * and warm on thermals.
 *
 * Call from the controller's init field. Pads (any object - an invisible
 * helipad is usual) and classes pair up by index. Pads can be objects or
 * their variable names.
 *
 * Arguments:
 * 0: Controller <OBJECT>
 * 1: Pads <ARRAY>
 * 2: Classes, one per pad <ARRAY>
 *
 * Return Value: None
 *
 * Example:
 * [this, [pad_1, pad_2], ["O_MBT_02_cannon_F", "O_APC_Tracked_02_cannon_F"]] call jmfsb_training_fnc_targetPads
 *
 * Public: Yes
 */

params [["_ctrl", objNull, [objNull]], ["_pads", [], [[]]], ["_classes", [], [[]]]];

if (isNull _ctrl || {_pads isEqualTo []}) exitWith {
    WARNING_1("targetPads: nothing to do on %1",_ctrl);
};
if (count _pads != count _classes) exitWith {
    WARNING_3("targetPads: %1 has %2 pads but %3 classes",_ctrl,count _pads,count _classes);
};

_ctrl setVariable [QGVAR(pads), [_pads, _classes]];

if (isServer) then {
    [{
        params ["_pads", "_classes"];
        {
            private _pad = [_x] call FUNC(resolve);
            if (!isNull _pad) then {
                [_classes select _forEachIndex, _pad] call FUNC(spawnPadTarget);
            };
        } forEach _pads;
    }, [_pads, _classes]] call CBA_fnc_execNextFrame;
};

if (!hasInterface) exitWith {};
if (!isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {};

private _action = [QGVAR(resetPads), "Reset targets", PAD_ICON, {
    params ["_target"];
    [QGVAR(resetPads), [_target]] call CBA_fnc_serverEvent;
    [NOTE_TITLE, "Damaged targets are being replaced.", NOTE_INFO] call EFUNC(notify,notify);
}, {true}] call ace_interact_menu_fnc_createAction;
[_ctrl, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
