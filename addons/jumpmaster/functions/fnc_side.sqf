#include "script_component.hpp"
/*
 * Author: YonV
 * Whose jump aircraft an asset id is - the "side" code this addon hands the
 * support core, which asks it on the server before a thread filed to the
 * aircraft's box is the aircraft's (2026-11-02). A JMSB - Jump Aircraft
 * module's "jump:<n>": the side the module read (FUNC(moduleJump)); a side's
 * own "jump:west": WEST - while no module of that side is placed
 * (FUNC(asset)).
 *
 * Arguments:
 * 0: Asset id, "jump:<n>" or "jump:<side>" <STRING>
 *
 * Return Value:
 * The side, sideUnknown when the id names no jump aircraft <SIDE>
 *
 * Example:
 * ["jump:0"] call jmfsb_jumpmaster_fnc_side
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

([_assetId] call FUNC(asset)) getOrDefault ["side", sideUnknown]
