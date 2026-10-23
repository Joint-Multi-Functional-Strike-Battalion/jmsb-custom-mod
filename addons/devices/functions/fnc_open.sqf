#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens the tablet wearing the given frame.
 *
 * TABLET MODE ONLY. In native mode the suite is on the map screen and the shell
 * would answer the vanilla map as its host, so a device opened then would be an
 * empty map in a frame. The ACE action is hidden in native mode for the same
 * reason; the key reaches here and is refused.
 *
 * Arguments:
 * 0: Device class in CfgJmfsbDevices <STRING> (optional, default "large")
 * 1: The vehicle, for the vehicle tablet - the one the player sits in when null <OBJECT> (optional, default objNull)
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * ["large"] call jmfsb_devices_fnc_open
 * ["vehicle", vehicle player] call jmfsb_devices_fnc_open
 *
 * Public: Yes
 */

params [["_device", "large", [""]], ["_vehicle", objNull, [objNull]]];

// THE UAV OPERATOR'S TABLET. A player with the UAV trait gets the gripped
// large tablet instead of the plain one (user, 2026-10-19); everything inside
// it is the same suite. The player's Tablet frame setting can force either
// one (user, 2026-10-21: "a way to toggle between the large and uav tablet").
if (_device isEqualTo LARGE_DEVICE) then {
    _device = switch (GVAR(tabletFrame)) do {
        case LARGE_DEVICE: {LARGE_DEVICE};
        case UAV_DEVICE: {UAV_DEVICE};
        default {[LARGE_DEVICE, UAV_DEVICE] select ((call CBA_fnc_currentUnit) getUnitTrait UAV_TRAIT)};
    };
};

if (!hasInterface) exitWith {false};
if (HOST_NATIVE) exitWith {false};
if (!EGVAR(tacpad,enabled)) exitWith {false};
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {false};
// THE TABLETS ONLY. The phone and the side devices are the walking view, a
// title layer; they have no full-screen page (their settings are on the
// tablet, SETTINGS > DEVICES), and FUNC(onLoad) builds the tablet screen.
if !(_device in TABLET_DEVICES) exitWith {
    WARNING_1("open: '%1' is not a tablet",_device);
    false
};
if (!isClass (configFile >> "CfgJmfsbDevices" >> _device)) exitWith {
    WARNING_1("open: no device '%1'",_device);
    false
};

// THE VEHICLE TABLET BELONGS TO A VEHICLE. Its bar names it and its rail lists
// who is in it, so it is not opened without one - and only from a seat in it.
// A static weapon or a parachute is not one, whoever calls this (the ACE action
// hides itself on them too).
if (_device isEqualTo VEHICLE_DEVICE) then {
    if (isNull _vehicle) then {
        _vehicle = objectParent (call CBA_fnc_currentUnit);
    };
} else {
    _vehicle = objNull;
};
if (_device isEqualTo VEHICLE_DEVICE && {isNull _vehicle || {!((call CBA_fnc_currentUnit) in crew _vehicle)}}) exitWith {false};
if (_device isEqualTo VEHICLE_DEVICE && {(VEHICLE_TABLET_EXCLUDED findIf {_vehicle isKindOf _x}) >= 0}) exitWith {false};

// The dialog's onLoad reads these; it has no arguments of its own to be told
// which frame to wear or which vehicle it is in.
GVAR(device) = _device;
GVAR(vehicle) = _vehicle;

createDialog QGVAR(tablet)
