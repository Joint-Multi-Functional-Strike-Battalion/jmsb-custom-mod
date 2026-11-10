#include "script_component.hpp"
/*
 * Author: YonV
 * Ends a mission: the asset reads idle again, its cooldown starts now, the
 * target marker comes off the map, and the token moves on so anything still
 * queued for this mission does nothing.
 *
 * THE COOLDOWN IS SIMPLEX'S: the module's cooldown plus its cooldown per round
 * for every round (or missile) the mission actually fired. When it runs out
 * the asset says it is ready again - if it has anything left to fire.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The mission's token <NUMBER>
 * 2: What the asset says, "" for nothing <STRING> (optional, default "")
 * 3: It fired - false for a battery laid AT MY COMMAND that stood down before
 *    its first round: no cooldown <BOOL> (optional, default true)
 *
 * A mission a call for fire tasked by message (FUNC(srvThread), 2026-11-01)
 * closes that thread with what was said, and the battery fires for no thread
 * after.
 *
 * Return Value: None
 *
 * Example:
 * [_logic, 3, "rounds complete"] call jmfsb_support_fires_fnc_finish
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_token", -1, [0]], ["_said", "", [""]], ["_spent", true, [true]]];

if (!isServer || {isNull _logic}) exitWith {};
if (_token isNotEqualTo (_logic getVariable [QGVAR(token), -1])) exitWith {};

private _cooldown = (_logic getVariable [QGVAR(cooldown), 0])
    + (_logic getVariable [QGVAR(fired), 0]) * (_logic getVariable [QGVAR(roundCooldown), 0]);
if (!_spent) then {_cooldown = 0};

_logic setVariable [QGVAR(token), _token + 1];
_logic setVariable [QGVAR(status), STATUS_IDLE, true];
_logic setVariable [QGVAR(abort), false, true];
_logic setVariable [QGVAR(claimed), []];
_logic setVariable [QGVAR(fired), 0];
_logic setVariable [QGVAR(readyAt), CBA_missionTime + _cooldown, true];
// An adjust mission's observer lets go; its rounds stay for his round log.
if ((_logic getVariable [QGVAR(holdBy), ""]) isNotEqualTo "") then {_logic setVariable [QGVAR(holdBy), "", true]};

[_logic] call FUNC(unmark);
// the JFO's impact area goes with the mission
[_token] call FUNC(impactSet);

if (_said isNotEqualTo "") then {
    [_logic, _said, "normal"] call FUNC(say);
};

if (_cooldown > 0 && {([_logic] call FUNC(ordnance)) isNotEqualTo []}) then {
    [_logic, _token + 1, "rearmed, ready for tasking", "normal", _cooldown] call FUNC(sayLater);
};

// Hoisted: a comma inside a macro argument reads as an argument separator.
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
INFO_3("%1 mission %2 finished, cooldown %3 s",_callsign,_token,round _cooldown);

// CLOSE in the asset's thread, with what it said - "rounds complete", "check
// fire" (2026-11-01). A battery that only joined a coordinated mission has
// no thread of its own and says nothing there. A call for fire's thread is
// named, and let go (step 6).
private _threadId = _logic getVariable [QGVAR(thread), ""];
if (_threadId isNotEqualTo "") then {
    _logic setVariable [QGVAR(thread), ""];
    _logic setVariable [QGVAR(threadOrder), createHashMap];
};
[format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], "CLOSED", _said, _callsign, false, _threadId] call EFUNC(support,state);
