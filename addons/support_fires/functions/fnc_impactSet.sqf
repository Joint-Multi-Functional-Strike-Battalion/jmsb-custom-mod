#include "script_component.hpp"
/*
 * Author: YonV
 * The live fire missions' impact areas, for the JFO's watch HUD (2026-11-07,
 * docs/DESIGN_WATCH_HUD.json jfo: "impact areas only for now"): one entry per
 * mission token, published to every client as GVAR(impacts) -
 * [token, target ATL, radius m, shell kind, impact at (mission time), side].
 * Server only. With no entry given, the token's area is cleared.
 *
 * Arguments:
 * 0: Mission token <NUMBER>
 * 1: [target, radius, kind, impact at, side], [] to clear <ARRAY> (optional, default [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_token, [_target, 100, "he", CBA_missionTime + 40, west]] call jmfsb_support_fires_fnc_impactSet
 *
 * Public: No
 */

params [["_token", -1, [0]], ["_entry", [], [[]]]];

if (!isServer) exitWith {};
GVAR(impacts) = GVAR(impacts) select {(_x # 0) isNotEqualTo _token};
if (_entry isNotEqualTo []) then {GVAR(impacts) pushBack ([_token] + _entry)};
publicVariable QGVAR(impacts);
