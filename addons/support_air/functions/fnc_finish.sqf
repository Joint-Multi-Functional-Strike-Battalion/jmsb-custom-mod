#include "script_component.hpp"
/*
 * Author: YonV
 * A sortie is over - home, recalled, timed out or shot down. The module is
 * idle again after its cooldown, which starts NOW: an air asset is turned
 * round when the aircraft is back, not when the order went out.
 *
 * A SYNCED AIRCRAFT STAYS where the sortie left it - it is the asset, and the
 * next order flies it again. One made from a class has been swept by the
 * caller and the module is VIRTUAL again (user, 2026-11-02: "virtual till
 * tasked"): the next task makes a fresh airframe. Going home uses no respawn;
 * a loss was counted where it went down (FUNC(lost), FUNC(replace)).
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

// THE DRONE ESCORTS (2026-11-01) are recovered with a lead that is still
// there - a synced aircraft on its stand. One that was removed took them with
// it, and the escorts of one that was lost fly home by themselves (the
// support core's escort watch).
private _lead = _logic getVariable [QGVAR(vehicle), objNull];
if (alive _lead) then {[_lead] call EFUNC(support,escortEnd)};

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

// CLOSE in the asset's thread (2026-11-01). A loss already closed it
// (FUNC(lost)), and then this says nothing more. Then the sortie answers no
// thread any more. A thread held open for an answer the aircraft asked for -
// PACKAGE AWAY - CONFIRM RECEIPT, SQUAD DOWN - LINKED UP? (step 7,
// QGVAR(threadHold)) - is closed by the answer or by D9, not here; its job
// stays for that answer.
if ((_logic getVariable [QGVAR(threadHold), ""]) isEqualTo "") then {
    [_logic, "CLOSED"] call FUNC(threadState);
    _logic setVariable [QGVAR(liftJob), nil];
    _logic setVariable [QGVAR(qrfJob), nil];
};
_logic setVariable [QGVAR(sortieThread), nil];
_logic setVariable [QGVAR(job), nil];
_logic setVariable [QGVAR(onStation), false];
_logic setVariable [QGVAR(cleared), true];
