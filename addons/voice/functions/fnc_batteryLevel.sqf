#include "script_component.hpp"
/*
 * Author: JMSB
 * The player's handheld's battery, 0..1, as RF last reported it
 * (jmfsb_rf_fnc_battery on his radio-slot node); -1 when he carries no set
 * with a battery, or RF has not said yet.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Level 0..1, -1 unknown <NUMBER>
 *
 * Example:
 * [] call jmfsb_voice_fnc_batteryLevel
 *
 * Public: Yes
 */

if (isNull player) exitWith {-1};

[format [NODE_FORMAT, getPlayerUID player, BATTERY_KIND], player] call EFUNC(rf,battery)
