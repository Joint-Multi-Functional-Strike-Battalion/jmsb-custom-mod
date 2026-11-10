#include "script_component.hpp"
/*
 * Author: YonV
 * Whose asset an id is - the "side" code this addon hands the support core,
 * which asks it on the server before a thread filed to the asset's box is the
 * asset's, and before a follow-up from anyone but the issuer is passed on
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING step 6 and D6). The module's side, as
 * FUNC(check) reads it.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 *
 * Return Value:
 * The side, sideUnknown when there is no such asset <SIDE>
 *
 * Example:
 * ["fires:0"] call jmfsb_support_fires_fnc_side
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {sideUnknown};

_logic getVariable [QGVAR(side), sideUnknown]
