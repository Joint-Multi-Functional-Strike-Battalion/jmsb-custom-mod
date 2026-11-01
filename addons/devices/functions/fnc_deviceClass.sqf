#include "script_component.hpp"
/*
 * Author: JMSB
 * A device's class - full, landscape or portrait (notes, 2026-10-30: "one
 * shell, three device classes; rows switch on class, not device name"). Read
 * off CfgJmfsbDevices (deviceClass, written by tools/gen_devices.py); a
 * device that names none is full when it is a tablet, landscape otherwise.
 *
 * Arguments:
 * 0: Device id <STRING>
 *
 * Return Value:
 * Class, one of DEVICE_CLASS_FULL / _LANDSCAPE / _PORTRAIT <STRING>
 *
 * Example:
 * ["phone"] call jmfsb_devices_fnc_deviceClass
 *
 * Public: Yes
 */

params [["_device", "", [""]]];

private _cfg = configFile >> "CfgJmfsbDevices" >> _device >> "deviceClass";
if (isText _cfg) exitWith {getText _cfg};

[DEVICE_CLASS_LANDSCAPE, DEVICE_CLASS_FULL] select (_device in TABLET_DEVICES)
