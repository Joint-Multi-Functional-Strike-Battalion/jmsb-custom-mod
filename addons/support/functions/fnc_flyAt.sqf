#include "script_component.hpp"
/*
 * Author: YonV
 * Sets a support aircraft's flying height: a phase's tactical height
 * (FUNC(flightHeight)) or a number the task needs. flyInHeight, never the ASL
 * form - it follows the terrain, which is what nap of the earth means. Run
 * where the aircraft is local (every provider's crew is the server's).
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Phase ("transit", "station", "attack") or height in m <STRING or NUMBER>
 *
 * Return Value:
 * The height set, m <NUMBER>
 *
 * Example:
 * [_veh, "transit"] call jmfsb_support_fnc_flyAt
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_how", PHASE_TRANSIT, ["", 0]]];

if (!alive _veh) exitWith {0};

private _height = if (_how isEqualType "") then {[_veh, _how] call FUNC(flightHeight)} else {_how};
_veh flyInHeight _height;
// The height it was told, kept - the engine gives no way to read it back -
// so a climb past it can be told from a climb asked for
// (jmfsb_support_air_fnc_heliNoRise, 2026-11-08).
_veh setVariable [QGVAR(flyHeight), _height];

_height
