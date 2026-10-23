#include "script_component.hpp"
/*
 * Author: JMSB
 * Asks the provider that owns an asset what it wants drawn on TAC//SUPPORT's
 * map while that asset is picked - an artillery battery's minimum and
 * maximum range rings, say. The provider's optional "overlay" code; a
 * provider without one draws nothing. Shapes of a kind the board does not
 * know, or of the wrong shape, are dropped here, so the board's Draw handler
 * never has to guard against a provider.
 *
 * A shape is one of (README, "overlay"):
 *   ["ring", centre <ARRAY>, radius m <NUMBER>, label <STRING>]
 *   ["line", from <ARRAY>, to <ARRAY>, label <STRING>]
 *   ["point", at <ARRAY>, label <STRING>]
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: The asset's row <ARRAY> (optional, default [])
 *
 * Return Value:
 * Shapes <ARRAY>
 *
 * Example:
 * ["fires:0", _row] call jmfsb_support_fnc_overlay
 *
 * Public: Yes
 */

params [["_assetId", "", [""]], ["_row", [], [[]]]];

if (_assetId isEqualTo "") exitWith {[]};

([_assetId] call FUNC(provider)) params ["_kind", "_decl"];
if (_kind isEqualTo "" || {!("overlay" in _decl)}) exitWith {[]};

private _res = [_assetId, _row] call (_decl get "overlay");
if (isNil "_res" || {!(_res isEqualType [])}) exitWith {[]};

private _isPos = {_this isEqualType [] && {count _this >= 2} && {(_this select 0) isEqualType 0} && {(_this select 1) isEqualType 0}};

_res select {
    _x isEqualType [] && {
        switch (_x param [0, ""]) do {
            case "ring": {((_x param [1, []]) call _isPos) && {(_x param [2, 0]) isEqualType 0} && {(_x param [3, ""]) isEqualType ""}};
            case "line": {((_x param [1, []]) call _isPos) && {(_x param [2, []]) call _isPos} && {(_x param [3, ""]) isEqualType ""}};
            case "point": {((_x param [1, []]) call _isPos) && {(_x param [2, ""]) isEqualType ""}};
            default {false};
        }
    }
}
