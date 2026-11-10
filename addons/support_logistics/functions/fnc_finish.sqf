#include "script_component.hpp"
/*
 * Author: YonV
 * A delivery is over - its last aircraft is gone. The module is idle again
 * after its cooldown, which starts NOW when the module says so: the Cooldown
 * plus the Item Cooldown for every item delivered (Simplex's item cooldown).
 * Its aircraft were removed over the module, back to virtual - that uses no
 * respawn and sets no Respawn Delay (user, 2026-11-02: virtual until
 * tasked). Only an aircraft lost with no respawn left (FUNC(lost)) takes the
 * asset off the list here.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic] call jmfsb_support_logistics_fnc_finish
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {};

private _sortie = _logic getVariable [QGVAR(sortie), createHashMap];
private _delivered = count (_sortie getOrDefault ["delivered", []]);

_logic setVariable [QGVAR(status), STATUS_IDLE, true];
_logic setVariable [QGVAR(vehicle), objNull, true];
_logic setVariable [QGVAR(plan), [], true];
_logic setVariable [QGVAR(abort), false, true];
_logic setVariable [QGVAR(sortie), nil];
// COOLDOWN STARTS: at the end of the delivery, or it has been running since
// the request (the module's Cooldown Starts) and is left alone.
if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_END) then {
    private _wait = (_logic getVariable [QGVAR(cooldown), 0]) + _delivered * (_logic getVariable [QGVAR(itemCooldown), 0]);
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + _wait, true];
};

INFO_2("%1 delivery over - %2 delivered",_logic getVariable [ARR_2(QGVAR(callsign),DEF_CALLSIGN)],_delivered);

// AN AIRCRAFT LOST WITH NO RESPAWN LEFT (user, 2026-11-02: "make sure there
// is a respawn count for each support, default no respawns"; FUNC(lost)): the
// asset leaves the SUPPORT list and answers UNABLE - NO AIRFRAME. Home
// normally, nothing is used.
if (_logic getVariable [QGVAR(noAirframe), false]) then {
    _logic setVariable [QGVAR(gone), true, true];
    [_logic, "has no airframe left - off the support list", "normal"] call FUNC(say);
    INFO_1("%1 - no respawn left, asset gone",_logic getVariable [ARR_2(QGVAR(callsign),DEF_CALLSIGN)]);
};

// CLOSE in the asset's thread. The last item already closed it with what
// was delivered (FUNC(account)), and then this says nothing more. One waiting
// for its receipt (step 7) is closed by the answer or by D9, not here.
if (((_logic getVariable [QGVAR(threadJob), createHashMap]) getOrDefault ["step", ""]) isNotEqualTo JOB_RECEIPT) then {
    [_logic, "CLOSED"] call FUNC(threadState);
    _logic setVariable [QGVAR(threadJob), nil];
};
