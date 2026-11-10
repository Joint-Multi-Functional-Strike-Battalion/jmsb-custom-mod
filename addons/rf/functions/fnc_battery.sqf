#include "script_component.hpp"
/*
 * Author: YonV
 * How full a set's battery is, as the server last told its holder
 * (FUNC(batteryPublish)): 0..1, or -1 for a set that has no battery, is not
 * the holder's, or has not been reported yet. Answers on any machine from
 * the holder's own variable; nothing is computed here.
 *
 * Arguments:
 * 0: Node id <STRING>
 * 1: Holder <OBJECT> (default: the player)
 *
 * Return Value:
 * Level 0..1, -1 unknown <NUMBER>
 *
 * Example:
 * ["voice_76561198000000000_sr"] call jmfsb_rf_fnc_battery
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_holder", player, [objNull]]];

if (isNull _holder) exitWith {-1};

private _list = _holder getVariable [QGVAR(batteries), []];
private _i = _list findIf {(_x select 0) isEqualTo _id};
if (_i < 0) exitWith {-1};

(_list select _i) select 1
