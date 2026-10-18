#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Mutes or un-mutes one air defence vehicle's alarm (FUNC(alarm)), public, so
 * the server hears it. Loudspeakers nearby still sound.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Muted <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [cursorObject, true] call jmfsb_adsite_fnc_setMute
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_muted", true, [true]]];

if (isNull _veh) exitWith {};
_veh setVariable [QGVAR(muted), _muted, true];

if (hasInterface) then {
    [format ["Air defence - %1: alarm %2", getText (configOf _veh >> "displayName"), ["on", "muted"] select _muted]] call CBA_fnc_notify;
};
