#include "script_component.hpp"
/*
 * Author: JMSB
 * The soldier classes a QRF module inserts, leader first.
 *
 *   UNIT CLASSES set: those, in order, and nothing else
 *   else SQUAD (CfgGroups): the group's members, read off the config the way
 *       the editor would place it - "West/BLU_F/Infantry/BIS_InfSquad", with
 *       "/" or ">>" between the parts
 *   else the players' side's vanilla rifle squad
 *
 * Only men: a group config that brings its own vehicle brings it without the
 * vehicle - the aircraft is the vehicle.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * Soldier classes, [] when none exist <ARRAY>
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_qrfSquad
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[]};

private _isMan = {isClass (configFile >> "CfgVehicles" >> _this) && {_this isKindOf "CAManBase"}};

private _units = ((_logic getVariable [QGVAR(unitClasses), ""]) splitString ", ") select {_x call _isMan};
if (_units isNotEqualTo []) exitWith {_units};

private _path = _logic getVariable [QGVAR(groupClass), ""];
if (_path isEqualTo "") then {
    _path = switch (_logic getVariable [QGVAR(side), west]) do {
        case east: {"East/OPF_F/Infantry/OIA_InfSquad"};
        case independent: {"Indep/IND_F/Infantry/HAF_InfSquad"};
        default {"West/BLU_F/Infantry/BIS_InfSquad"};
    };
};

private _cfg = configFile >> "CfgGroups";
{
    _cfg = _cfg >> _x;
} forEach (((_path splitString "/>") apply {trim _x}) select {_x isNotEqualTo ""});

if !(isClass _cfg) exitWith {
    WARNING_1("QRF squad '%1' is not a CfgGroups class",_path);
    []
};

(("isClass _x" configClasses _cfg) apply {getText (_x >> "vehicle")}) select {_x call _isMan}
