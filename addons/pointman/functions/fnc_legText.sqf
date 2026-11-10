#include "script_component.hpp"
/*
 * Author: YonV
 * The leg to the next waypoint in a few letters, for the phone's PM cell and
 * the tablet bar: "420M 045°", "1.2KM 0800 MIL" for a player who reads mils
 * (jmfsb_maptools_angleUnit), NO FIX without a GPS fix.
 *
 * SHORT ON PURPOSE (user, 2026-11-01: "no line no direction no distance"):
 * the full readout - the page's, "420 M 045° / 0800 MIL" with Bearing units
 * on Both, the default - made PM the longest cell on the walking view by
 * twice, and the strip sets every cell at the one size the longest fits
 * (jmfsb_devices_fnc_overlayDraw): on a side device's grid of three that left
 * the whole strip a few pixels high. The page keeps the full readout.
 *
 * Arguments:
 * 0: Distance in metres, -1 with no fix <NUMBER>
 * 1: Bearing in degrees <NUMBER>
 *
 * Return Value:
 * The leg <STRING>
 *
 * Example:
 * [420, 45] call jmfsb_pointman_fnc_legText
 *
 * Public: No
 */

params [["_dist", -1, [0]], ["_brg", 0, [0]]];

if (_dist < 0) exitWith {LEG_NO_FIX};

// "420 M" and "1.2 KM" with the space out: the cell's words are space-split.
private _range = (([_dist] call EFUNC(maptools,distanceText)) splitString " ") joinString "";

private _mil = (missionNamespace getVariable [QEGVAR(maptools,angleUnit), ""]) isEqualTo LEG_UNIT_MIL;
private _turn = [LEG_DEG_TURN, LEG_MIL_TURN] select _mil;
private _value = (round ((_brg mod LEG_DEG_TURN) * _turn / LEG_DEG_TURN)) mod _turn;
private _digits = [_value, [LEG_DEG_DIGITS, LEG_MIL_DIGITS] select _mil] call CBA_fnc_formatNumber;

format [LEG_FORMAT, _range, format [[LEG_DEG_FORMAT, LEG_MIL_FORMAT] select _mil, _digits]]
