#include "script_component.hpp"
/*
 * Author: YonV
 * What a module's row reads with no run up (user, 2026-11-02: virtual until
 * tasked, and the respawn count): LOST and off the list once the last drone is
 * gone, REARMING while a replacement is on its way, else READY ("idle") - no
 * drone is up between runs. A cooldown on top is FUNC(available)'s.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The status word <STRING>
 *
 * Example:
 * [_logic] call jmfsb_cas_fnc_idleStatus
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {STATUS_IDLE};
if (_logic getVariable [QGVAR(gone), false]) exitWith {STATUS_EXPENDED};
[STATUS_IDLE, STATUS_REPLACING] select (CBA_missionTime < (_logic getVariable [QGVAR(respawnAt), 0]))
