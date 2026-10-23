#include "script_component.hpp"
/*
 * Author: JMSB
 * The key: opens the tablet, or closes it if it is open.
 *
 * Arguments:
 * 0: Device class in CfgJmfsbDevices <STRING> (optional, default "large")
 *
 * Return Value:
 * Now open <BOOL>
 *
 * Example:
 * ["large"] call jmfsb_devices_fnc_toggle
 *
 * Public: Yes
 */

params [["_device", "large", [""]]];

if ([] call FUNC(close)) exitWith {false};

[_device] call FUNC(open)
