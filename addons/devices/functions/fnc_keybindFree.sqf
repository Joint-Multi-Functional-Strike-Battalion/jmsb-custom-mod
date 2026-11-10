#include "script_component.hpp"
/*
 * Author: YonV
 * FREES THE DEVICE ARROW KEYS (user, 2026-11-08: numpad 0 and . also fired
 * ACE and CBA weapon keybinds - CBA's manual reticle night switch is numpad 0
 * by default). Run once every addon has registered its keybinds: any other
 * addon's bind that sits on a key the device LEFT / RIGHT buttons
 * (KEYBIND_FREE_BUTTONS) are bound to, AND IS STILL THAT ADDON'S OWN DEFAULT,
 * is taken off - live (CBA's key handlers) and in the profile, so it stays
 * off. A bind the player set to something else himself is never touched;
 * CONTROLS > CONFIGURE ADDONS puts one back.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Binds taken off <NUMBER>
 *
 * Example:
 * [] call jmfsb_devices_fnc_keybindFree
 *
 * Public: No
 */

// a CBA namespace (a location), as CBA's own CONFIGURE ADDONS reads it
private _actions = missionNamespace getVariable CBA_KEYBIND_ACTIONS;
if (isNil "_actions") exitWith {0};

// the keys the device arrows are bound to now - the player's rebind included
private _ours = [];
{
    private _info = _actions getVariable [toLower format ["%1$%2_%3", JMFSB_CATEGORY, QGVAR(button), _x], []];
    _ours append ((_info param [2, []]) select {_x isEqualType [] && {(_x param [0, 0]) > DIK_ESCAPE}});
} forEach KEYBIND_FREE_BUTTONS;
if (_ours isEqualTo []) exitWith {0};

private _registry = profileNamespace getVariable [CBA_KEYBIND_REGISTRY, []];
private _prefix = toLower format ["%1$", JMFSB_CATEGORY];
private _freed = [];
{
    private _action = _x;
    if ((_action find _prefix) isEqualTo 0) then {continue};
    private _info = _actions getVariable [_action, []];
    if !(_info isEqualType [] && {count _info > 5}) then {continue};
    _info params ["_name", "", ["_keybinds", [], [[]]], ["_default", []], ["_downCode", {}], ["_upCode", {}], ["_holdKey", true], ["_holdDelay", 0]];
    private _keep = _keybinds select {!(_x in _ours) || _x isNotEqualTo _default};
    if ((count _keep) isEqualTo (count _keybinds)) then {continue};

    // as CBA's own CONFIGURE ADDONS > OK does it: the kept binds' handlers
    // re-added in order, the ones past them removed, the profile written
    _info set [2, _keep];
    {
        if (_downCode isNotEqualTo {}) then {
            [_x select 0, _x select 1, _downCode, "keyDown", format ["%1_down_%2", _action, _forEachIndex], _holdKey, _holdDelay] call CBA_fnc_addKeyHandler;
        };
        if (_upCode isNotEqualTo {}) then {
            [_x select 0, _x select 1, _upCode, "keyUp", format ["%1_up_%2", _action, _forEachIndex]] call CBA_fnc_addKeyHandler;
        };
    } forEach _keep;
    for "_i" from (count _keep) to (count _keybinds - 1) do {
        [format ["%1_down_%2", _action, _i], "keydown"] call CBA_fnc_removeKeyHandler;
        [format ["%1_up_%2", _action, _i], "keyup"] call CBA_fnc_removeKeyHandler;
    };
    if ([_registry] call CBA_fnc_isHash) then {[_registry, _action, _keep] call CBA_fnc_hashSet};
    if (_name isEqualType "" && {isLocalized _name}) then {_name = localize _name};
    _freed pushBack format ["%1 (%2)", _name, _action splitString "$" param [0, ""]];
} forEach (allVariables _actions);

if (_freed isNotEqualTo []) then {
    profileNamespace setVariable [CBA_KEYBIND_REGISTRY, _registry];
    saveProfileNamespace;
    INFO_1("keybinds taken off the device arrow keys: %1",_freed);
};
count _freed
