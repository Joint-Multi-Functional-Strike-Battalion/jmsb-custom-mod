#include "script_component.hpp"
/*
 * Author: JMSB
 * The tasks TAC//SUPPORT offers for an asset type, or for one picked asset:
 *
 *   [token, label, meta, guidance, steppers, needsPoint, pointLabel]
 *
 * With an asset picked, its provider answers: its "tasks" code if it has one
 * (per-asset tasks), else the tasks its own "types" declaration lists for the
 * type. With none picked, or a provider that declares nothing for the type,
 * the union every provider declares for the type (FUNC(types)).
 *
 * Arguments:
 * 0: Asset type <STRING>
 * 1: Asset id, "" for none picked <STRING> (optional, default "")
 * 2: The asset's row, [] for none <ARRAY> (optional, default [])
 *
 * Return Value:
 * Task declarations <ARRAY>
 *
 * Example:
 * ["cas", "cas:0"] call jmfsb_support_fnc_tasks
 *
 * Public: Yes
 */

params [["_type", "", [""]], ["_assetId", "", [""]], ["_row", [], [[]]]];

private _union = {
    private _t = (call FUNC(types)) select {(_x select 0) isEqualTo _type};
    (_t param [0, []]) param [5, []]
};

if (_assetId isEqualTo "") exitWith {call _union};

([_assetId] call FUNC(provider)) params ["_kind", "_decl"];
if (_kind isEqualTo "") exitWith {call _union};

private _own = [];
if ("tasks" in _decl) then {
    private _answer = [_assetId, _row] call (_decl get "tasks");
    if (!isNil "_answer" && {_answer isEqualType []}) then {_own = _answer};
};
if (_own isNotEqualTo []) exitWith {_own};

{
    if (_x isEqualType [] && {(_x param [0, ""]) isEqualTo _type}) exitWith {
        _own = _x param [5, []];
    };
} forEach (_decl getOrDefault ["types", []]);
if (_own isEqualType [] && {_own isNotEqualTo []}) exitWith {_own};

call _union
