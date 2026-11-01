#include "script_component.hpp"
/*
 * Author: JMSB
 * SWAP BATTERY (the RADIO app, user 2026-10-30): one spare out of the
 * player's kit (FUNC(batterySpares)) and a full battery into his handheld
 * (jmfsb_rf_fnc_batterySwap on his radio-slot node). No spare, nothing
 * happens and he is told.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Swapped <BOOL>
 *
 * Example:
 * [] call jmfsb_voice_fnc_batterySwap
 *
 * Public: Yes
 */

if (isNull player) exitWith {false};

private _spares = [] call FUNC(batterySpares);
if (_spares isEqualTo []) exitWith {
    [BLOCK_TITLE, "No spare battery in your kit."] call EFUNC(notify,notify);
    false
};

player removeItem (_spares select 0);
[format [NODE_FORMAT, getPlayerUID player, BATTERY_KIND]] call EFUNC(rf,batterySwap);
GVAR(batteryWarned) = -1;
[BLOCK_TITLE, format ["Battery swapped. %1 spare left.", count _spares - 1]] call EFUNC(notify,notify);

true
