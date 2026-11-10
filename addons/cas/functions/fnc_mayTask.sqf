#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the door check of every CAS order and recall (review S6). The
 * client's FUNC(task) already refused what it could, but it runs on the
 * client, so the server asks again of the machine that really sent the call:
 * - the man is that machine's own player (EFUNC(common,sender)), never a unit
 *   named in the arguments;
 * - the module is one of this addon's registered CAS modules;
 * - it belongs to his side (side of his group, as FUNC(assets) lists rows);
 * - the support tasking gate lets him task (EFUNC(support,canTask)).
 * Called at the top of the remote-executed function, never inside spawned or
 * delayed code, where the sender is no longer known.
 *
 * Arguments:
 * 0: The module logic the call names <OBJECT>
 *
 * Return Value:
 * 0: The order may be served <BOOL>
 * 1: The sender's unit, objNull when there is none <OBJECT>
 * 2: Why not, "" when it may <STRING>
 *
 * Example:
 * ([_logic] call jmfsb_cas_fnc_mayTask) params ["_ok", "_caller", "_why"]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

([] call EFUNC(common,sender)) params ["_owner", "_caller"];

if (isNull _caller || {!alive _caller}) exitWith {[false, objNull, format ["no living player on machine %1", _owner]]};
if (isNull _logic || {!(_logic in GVAR(entities))} || {(typeOf _logic) isNotEqualTo CAS_MODULE}) exitWith {
    [false, _caller, format ["%1 is not a CAS module", _logic]]
};
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group _caller)) exitWith {
    [false, _caller, format ["%1 is not %2's side's asset", _logic getVariable [QGVAR(callsign), "CAS"], name _caller]]
};

([_caller] call EFUNC(support,canTask)) params ["_may", "_why"];
if (!_may) exitWith {[false, _caller, _why]};

[true, _caller, ""]
