#include "script_component.hpp"
/*
 * Author: YonV
 * Server: whose asset a logistics id is - the support core's "side" hook
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING step 7): a card is taken only from a
 * man of the module's side, and a follow-up from anyone but the issuer only
 * from that side.
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 *
 * Return Value:
 * The module's side, sideUnknown for none <SIDE>
 *
 * Example:
 * ["logi:0"] call jmfsb_support_logistics_fnc_side
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {sideUnknown};

_logic getVariable [QGVAR(side), sideUnknown]
