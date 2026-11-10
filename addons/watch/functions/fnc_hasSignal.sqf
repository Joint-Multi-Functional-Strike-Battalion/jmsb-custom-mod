#include "script_component.hpp"
/*
 * Author: YonV
 * Whether the squad view can hear from a man (design: NO SIGNAL when his
 * device is off or jammed): he is alive and carries one of the mod's devices
 * (a jmfsb_devices_* item). Jamming is each player's own reading and is not
 * known for another man here.
 *
 * Arguments:
 * 0: The man <OBJECT>
 *
 * Return Value:
 * Has a signal <BOOL>
 *
 * Example:
 * [_unit] call jmfsb_watch_fnc_hasSignal
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

alive _unit && {((assignedItems _unit + items _unit) findIf {(toLower _x find DEVICE_PREFIX) isEqualTo 0}) >= 0}
