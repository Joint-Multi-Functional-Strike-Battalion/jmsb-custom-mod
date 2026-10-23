#include "script_component.hpp"
/*
 * Author: JMSB
 * Asks the provider that owns an asset for its one-line state - TAC//SUPPORT's
 * SITREP button. A provider with no "sitrep" code answers "no report".
 *
 * Arguments:
 * 0: Asset id <STRING>
 *
 * Return Value:
 * 0: Answered <BOOL>
 * 1: The line, or why not <STRING>
 *
 * Example:
 * ["cas:0"] call jmfsb_support_fnc_sitrep
 *
 * Public: Yes
 */

params [["_assetId", "", [""]]];

([_assetId] call FUNC(provider)) params ["_kind", "_decl"];
if (_kind isEqualTo "") exitWith {[false, "no provider answers for that asset"]};
if !("sitrep" in _decl) exitWith {[false, "no report"]};

private _res = [_assetId] call (_decl get "sitrep");
if (isNil "_res" || {!(_res isEqualType [])}) exitWith {[false, "no report"]};
_res params [["_ok", false, [false]], ["_said", "", [""]]];

[_ok, _said]
