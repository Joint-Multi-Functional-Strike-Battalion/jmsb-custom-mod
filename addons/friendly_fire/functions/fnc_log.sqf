#include "script_component.hpp"
/*
 * Author: veteran29
 * Writes a friendly fire line to this machine's RPT. Called on the victim's
 * machine by his Hit handler, which also sends it to the server by
 * remoteExec; there the victim is the sender himself and the shot is checked
 * again (a player, his own side, not himself). Review R1: it was a global
 * CBA event, so any client could forge FF lines naming anyone in every RPT.
 *
 * Arguments:
 * 0: Victim <OBJECT>
 * 1: Shooter <OBJECT>
 * 2: Shooter's vehicle <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _shooter, vehicle _shooter] call jmfsb_friendly_fire_fnc_log
 *
 * Public: No
 */

params [["_victim", objNull, [objNull]], ["_origin", objNull, [objNull]], ["_originVehicle", objNull, [objNull]]];

if (isRemoteExecuted) then {
    _victim = ([] call EFUNC(common,sender)) select 1;
};
if (isRemoteExecuted && {!isServer}) exitWith {};
if (isNull _victim || !isPlayer _origin || _victim isEqualTo _origin) exitWith {};
if (side group _victim isNotEqualTo side group _origin) exitWith {};
if (isNull _originVehicle || {_originVehicle isNotEqualTo vehicle _origin}) then {_originVehicle = vehicle _origin};

private _nl = toString [13, 10] + "    ";

private _msg = if (_originVehicle isKindOf "CAManBase") then {
    [
        _nl,
        name _origin, " shot at ", name _victim, _nl,
        "Victim-Origin distance: ", _victim distance _origin
    ] joinString ""
} else {
    // The VEHICLE's name - configOf _origin named the man's class in
    // the line meant to name the offending vehicle.
    private _displayName = getText (configOf _originVehicle >> "displayName");
    [
        _nl,
        _displayName, " shot at ", name _victim, _nl,
        "Gunner:                 ", name gunner _originVehicle, _nl,
        "Commander:              ", name commander _originVehicle, _nl,
        "Driver:                 ", name driver _originVehicle, _nl,
        "Shooter:                ", name _origin, _nl,
        "Victim-Origin distance: ", _victim distance _originVehicle
    ] joinString ""
};

WARNING(_msg);
