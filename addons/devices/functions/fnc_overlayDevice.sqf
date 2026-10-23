#include "script_component.hpp"
/*
 * Author: JMSB
 * Which walking-view device the player has in the GPS slot, if any.
 *
 * THE ITEM IS THE SWITCH. The walking view is up while one of the three
 * devices is ASSIGNED - in the slot, not in a pocket - and comes down the
 * moment it is not, so a man who drops his phone loses his map. A player
 * carries one of the three; when he somehow has two the phone wins, then
 * side, then side 2, in the order they are declared.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Device class in CfgJmfsbDevices - "phone", "side" or "side2" - or "" <STRING>
 *
 * Example:
 * private _device = [] call jmfsb_devices_fnc_overlayDevice
 *
 * Public: Yes
 */

if (!hasInterface || {isNull player}) exitWith {""};

private _items = assignedItems player;
private _carried = [QGVAR(phone), QGVAR(side), QGVAR(side2)] findIf {_x in _items};
if (_carried < 0) exitWith {""};

["phone", "side", "side2"] select _carried
