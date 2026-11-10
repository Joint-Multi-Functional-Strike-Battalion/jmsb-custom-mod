#include "script_component.hpp"
/*
 * Author: YonV
 * Server: an airframe of this module is LOST - destroyed, its crew dead, or
 * disabled and written off - and the respawn count decides what comes next
 * (user, 2026-11-02: "make sure there is a respawn count for each support,
 * default no respawns"). A virtual airframe going home is not lost and never
 * comes here (user, 2026-11-02: virtual until tasked).
 *
 *   respawns left   one is used; the replacement is ready the Respawn Delay
 *                   from now (QGVAR(respawnAt) - the row reads REPLACING): a
 *                   class module's next tasking then makes a new airframe
 *                   over the module; a synced aircraft's is rebuilt on its
 *                   stand by FUNC(lost)'s caller
 *   none left       the asset is gone (QGVAR(dead)): off the SUPPORT list
 *                   (FUNC(assets)), and a card to its box answers
 *                   WHY_NO_AIRFRAME (FUNC(srvThread))
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * A replacement is coming <BOOL>
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_replace
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {false};
if (_logic getVariable [QGVAR(dead), false]) exitWith {false};

private _left = _logic getVariable [QGVAR(respawnsLeft), 0];
if (_left <= 0) exitWith {
    _logic setVariable [QGVAR(dead), true, true];
    INFO_1("%1 has no airframe left - off the board",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")]);
    false
};

private _delay = _logic getVariable [QGVAR(respawnDelay), MODULE_RESPAWN_DELAY];
_logic setVariable [QGVAR(respawnsLeft), _left - 1, true];
_logic setVariable [QGVAR(respawnAt), CBA_missionTime + _delay, true];
INFO_3("%1 replacement airframe in %2 s - %3 left after it",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],round _delay,_left - 1);
true
