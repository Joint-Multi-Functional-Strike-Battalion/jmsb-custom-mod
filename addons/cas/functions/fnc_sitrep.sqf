#include "script_component.hpp"
/*
 * Author: JMSB
 * The one-line state of a CAS asset, for the support page's detail pane.
 *
 * IT SAYS WHAT IS LEFT, because that is the number the man on the radio is
 * actually deciding on. A cooldown runs out; airframes do not come back, and
 * an asset one loss from expended should be able to say so before it is asked
 * to fly into the same triple-A that took the last one.
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

private _max = _logic getVariable [QGVAR(airframes), 3];
private _lost = _logic getVariable [QGVAR(lost), 0];
private _left = if (_max <= 0) then {"unlimited"} else {format ["%1 of %2", _max - _lost, _max]};

[true, format [
    "%1 - %2. Airframes %3. Ingress %4 m at %5 m.",
    _logic getVariable [QGVAR(callsign), "CAS"],
    [toUpper _status, _why] select (_why isNotEqualTo ""),
    _left,
    _logic getVariable [QGVAR(spawnDistance), 4000],
    _logic getVariable [QGVAR(altitude), 700]
]]
