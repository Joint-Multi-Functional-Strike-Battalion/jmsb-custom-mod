#include "script_component.hpp"
/*
 * Author: JMSB
 * One airframe lost. Counts it against the module's stock and, when that runs
 * out, retires the asset.
 *
 * THIS IS THE WHOLE REASON THE DRONE IS A REAL AIRCRAFT. A scripted explosion
 * over the target cannot be shot down, so nothing the enemy does about it
 * matters. An airframe that is flown, seen, engaged and struck off a ledger
 * makes the air defence on the ridge worth putting there - and makes the
 * player spend the third strike more carefully than the first.
 *
 * A LOSS IS NOT A COOLDOWN. The cooldown is set by the run finishing either
 * way; this only moves the counter, so an asset shot down on its last airframe
 * reads EXPENDED rather than "rearming" for a rearm that will never come.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: What killed it <OBJECT> (optional, for the log)
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_killer", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};

private _lost = (_logic getVariable [QGVAR(lost), 0]) + 1;
private _max = _logic getVariable [QGVAR(airframes), 3];
private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];

_logic setVariable [QGVAR(lost), _lost, true];
_logic setVariable [QGVAR(plan), [], true];

if (_max > 0 && _lost >= _max) then {
    _logic setVariable [QGVAR(status), "expended", true];
    WARNING_2("%1 lost its last airframe to '%2' - asset expended",_callsign,typeOf _killer);
} else {
    private _left = if (_max <= 0) then {"unlimited"} else {str (_max - _lost)};
    WARNING_3("%1 shot down by '%2' - %3 airframe(s) left",_callsign,typeOf _killer,_left);
};
