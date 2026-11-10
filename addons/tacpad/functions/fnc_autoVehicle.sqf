#include "script_component.hpp"
/*
 * Author: YonV
 * Autofill source "vehicle" (report-card review, user 2026-11-02, D16): the
 * vehicle the sender is in, as its crew's call sign and its type - the
 * VEHICLE line of a DEFREP, which he had to type on every report.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * "<call sign> - <type>", "" on foot <STRING>
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_autoVehicle
 *
 * Public: No
 */

private _veh = vehicle player;
if (_veh isEqualTo player) exitWith {""};

private _type = getText (configOf _veh >> "displayName");
private _crew = group (effectiveCommander _veh);
if (isNull _crew) exitWith {_type};

format ["%1 - %2", groupId _crew, _type]
