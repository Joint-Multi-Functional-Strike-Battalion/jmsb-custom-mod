#include "script_component.hpp"
/*
 * Author: JMSB
 * What the vehicle tablet calls its vehicle (docs/DESIGN_TABLET.md: "Device
 * bar says VEHICLE . <vehicle callsign>"): this vehicle, not its model.
 *
 * The mission's own name for it when it has one (the editor's variable name),
 * else the callsign of the group commanding it when that is not the player's
 * own - a crew the player rides with - and only then the class's display name.
 * One function, so the bar and the ON BOARD header can never disagree.
 *
 * Arguments:
 * 0: The vehicle <OBJECT>
 *
 * Return Value:
 * Name, upper case, "" for no vehicle <STRING>
 *
 * Example:
 * [vehicle player] call jmfsb_devices_fnc_vehicleName
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle) exitWith {""};

private _name = vehicleVarName _vehicle;
if (_name isEqualTo "") then {
    private _crewGroup = group effectiveCommander _vehicle;
    if (!isNull _crewGroup && {_crewGroup isNotEqualTo group (call CBA_fnc_currentUnit)}) then {
        _name = groupId _crewGroup;
    };
};
if (_name isEqualTo "") then {
    _name = getText (configOf _vehicle >> "displayName");
};

toUpper _name
