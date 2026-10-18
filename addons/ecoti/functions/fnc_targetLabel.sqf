#include "script_component.hpp"
/*
 * Author: JMSB
 * The aided-target-recognition label under a target's box (user, 2026-10-17:
 * "i'd be ok with aitr"), the way an AiTR display reads in two stages - what
 * it is, then one thing about it:
 *
 *   PERSON   | ARMED, UNARMED, SURRENDER
 *   VEHICLE  | TANK, APC, TRUCK, CAR, STATIC
 *   VESSEL
 *   UAS      | MULTICOPTER, FIXED-WING
 *   AIRCRAFT | HELICOPTER, FIXED-WING
 *   ANIMAL
 *
 * Settled with the colour twice a second (FUNC(updateCandidates)), not per frame.
 *
 * Arguments:
 * 0: Man, vehicle or animal <OBJECT>
 *
 * Return Value:
 * Label <STRING>
 *
 * Example:
 * [cursorTarget] call jmfsb_ecoti_fnc_targetLabel
 *
 * Public: No
 */

params [["_target", objNull, [objNull]]];

private _fnc_label = {
    params ["_class", ["_detail", ""]];
    [_class, format ["%1%2%3", _class, LABEL_SEPARATOR, _detail]] select (_detail isNotEqualTo "")
};

if (_target isKindOf "CAManBase") exitWith {
    ["PERSON", call {
        if (captive _target) exitWith {"SURRENDER"};
        if (primaryWeapon _target != "" || {handgunWeapon _target != ""} || {secondaryWeapon _target != ""}) exitWith {"ARMED"};
        "UNARMED"
    }] call _fnc_label
};
if (_target isKindOf "Animal") exitWith {["ANIMAL"] call _fnc_label};
if (_target isKindOf "Ship") exitWith {["VESSEL"] call _fnc_label};
if (_target isKindOf "Air") exitWith {
    private _rotary = _target isKindOf "Helicopter";
    if (unitIsUAV _target) exitWith {["UAS", ["FIXED-WING", "MULTICOPTER"] select _rotary] call _fnc_label};
    ["AIRCRAFT", ["FIXED-WING", "HELICOPTER"] select _rotary] call _fnc_label
};

["VEHICLE", call {
    if (_target isKindOf "Tank") exitWith {"TANK"};
    if (_target isKindOf "Wheeled_APC_F") exitWith {"APC"};
    if (_target isKindOf "Truck_F") exitWith {"TRUCK"};
    if (_target isKindOf "StaticWeapon") exitWith {"STATIC"};
    if (_target isKindOf "Car") exitWith {"CAR"};
    ""
}] call _fnc_label
