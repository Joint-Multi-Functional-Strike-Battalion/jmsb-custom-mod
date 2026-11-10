#include "script_component.hpp"
/*
 * Author: YonV
 * The one-line state of a CAS asset, for the support page's detail pane.
 *
 * IT SAYS WHAT IS LEFT, because that is the number the man on the radio is
 * actually deciding on. A cooldown runs out; replacements do not come back
 * (the Respawns count, user 2026-11-02), and an asset on its last airframe
 * should be able to say so before it is asked to fly into the same triple-A
 * that took the last one.
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 *
 * Return Value:
 * 0: Readable <BOOL>
 * 1: The line <STRING>
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {[false, "that asset is gone"]};

([_logic] call FUNC(available)) params ["", "_status", "_why"];

// The respawn count (user, 2026-11-02): the replacements left.
private _left = _logic getVariable [QGVAR(respawnsLeft), MODULE_RESPAWNS];

[true, format [
    "%1 - %2. Respawns left %3. Ingress %4 m at %5 m.",
    _logic getVariable [QGVAR(callsign), "CAS"],
    [toUpper _status, _why] select (_why isNotEqualTo ""),
    _left,
    _logic getVariable [QGVAR(spawnDistance), 4000],
    // The support core's attack altitude (2026-11-01), not a module value.
    [_logic getVariable [QGVAR(cls), ""], FLY_ATTACK] call EFUNC(support,flightHeight)
]]
