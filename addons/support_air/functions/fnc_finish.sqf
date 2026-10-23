#include "script_component.hpp"
/*
 * Author: JMSB
 * A sortie is over - home, recalled, timed out or shot down. The module is
 * idle again after its cooldown, which starts NOW: an air asset is turned
 * round when the aircraft is back, not when the order went out.
 *
 * A SYNCED AIRCRAFT STAYS where the sortie left it - it is the asset, and the
 * next order flies it again. One made from a class has been swept by the
 * caller; the row stops pointing at it.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_finish
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {};

private _synced = _logic getVariable [QGVAR(synced), objNull];

_logic setVariable [QGVAR(status), STATUS_IDLE, true];
_logic setVariable [QGVAR(vehicle), [objNull, _synced] select (alive _synced), true];
// COOLDOWN STARTS: at the end of the sortie, or it has been running since
// the request (the module's Cooldown Starts) and is left alone.
if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_END) then {
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 0]), true];
};
_logic setVariable [QGVAR(plan), [], true];
_logic setVariable [QGVAR(reposition), nil];
_logic setVariable [QGVAR(abort), false, true];
_logic setVariable [QGVAR(ticking), false];

INFO_1("%1 sortie over",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")]);
