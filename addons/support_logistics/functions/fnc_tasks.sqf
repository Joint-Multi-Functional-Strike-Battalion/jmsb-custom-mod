#include "script_component.hpp"
/*
 * Author: YonV
 * The tasks ONE asset offers - the provider's "tasks" code. The methods the
 * module resolved (FUNC(moduleLogistics)), each with this asset's catalog in
 * front of its own steppers:
 *
 *   ITEM   slot 50 - a list stepper over the catalog's names; the value is
 *          the catalog index. For SLING LOAD it walks only what this hook
 *          can lift (the stepper's value list), and a hook that can lift
 *          nothing in the catalog is no SLING LOAD at all
 *   COUNT  slot 51 - 1 to the module's Capacity; a SLING LOAD flown by one
 *          helicopter (Sling Fulfillment) is one item
 *
 * Together they are a one-item cart; the v2 board's cart (slot 49) replaces
 * them (FUNC(readCart)).
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: The asset's row <ARRAY>
 *
 * Return Value:
 * Task declarations <ARRAY>
 *
 * Example:
 * ["logi:0", _row] call jmfsb_support_logistics_fnc_tasks
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_row", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[]};

private _catalog = _logic getVariable [QGVAR(catalog), []];
if (_catalog isEqualTo []) exitWith {[]};

private _names = _catalog apply {_x select ITEM_NAME};
private _cap = _logic getVariable [QGVAR(capacity), DEF_CAPACITY];
private _hookMass = _logic getVariable [QGVAR(hookMass), 0];
private _methods = _logic getVariable [QGVAR(methods), []];

// What this hook lifts: sling points, and no heavier than its rating. An
// unknown mass (-1) is tried at the hook.
private _liftable = [];
{
    if ((_x select ITEM_HOOK) && (_x select ITEM_MASS) <= _hookMass) then {_liftable pushBack _forEachIndex};
} forEach _catalog;
private _noLift = _liftable isEqualTo [];
private _oneHook = !(_logic getVariable [QGVAR(slingEach), true]);

private _decls = [];
{
    private _decl = +_x;
    private _sling = (_decl select 0) isEqualTo TASK_SLING;
    if (!((_decl select 0) in _methods) || (_sling && _noLift)) then {continue};

    private _walk = [[], _liftable] select (_sling && count _liftable < count _catalog);
    private _max = [_cap, 1] select (_sling && _oneHook);
    _decl set [4, [
        ["ITEM", SLOT_ITEM, 1, 0, count _names - 1, _names, _walk, false],
        ["COUNT", SLOT_COUNT, 1, COUNT_MIN, _max max COUNT_MIN, "%1", [], true]
    ] + (_decl select 4)];
    _decls pushBack _decl;
} forEach [DECL_AIRDROP, DECL_SLING];

_decls
