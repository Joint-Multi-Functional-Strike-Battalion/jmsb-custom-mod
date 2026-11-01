#include "script_component.hpp"
/*
 * Author: JMSB
 * The side a radio belongs to - the side of the man carrying it, or of the
 * vehicle it is racked in. A relay only ever carries its own side's traffic.
 *
 * Arguments:
 * 0: ACRE radio id <STRING>
 *
 * Return Value:
 * Side, or sideUnknown when the radio has no owner in the world <SIDE>
 *
 * Example:
 * ["ACRE_PRC152_ID_3"] call jmfsb_radio_mesh_fnc_radioSide
 *
 * Public: No
 */
params [["_radio", "", [""]]];

if (_radio isEqualTo "" || {isNil "acre_sys_radio_fnc_getRadioObject"}) exitWith {sideUnknown};

private _obj = [_radio] call acre_sys_radio_fnc_getRadioObject;
if (isNull _obj) exitWith {sideUnknown};

if (_obj isKindOf "CAManBase") exitWith {side group _obj};

// A vehicle: whoever commands it, else the vehicle's own side
private _cmd = effectiveCommander _obj;
if (!isNull _cmd) exitWith {side group _cmd};
side _obj
