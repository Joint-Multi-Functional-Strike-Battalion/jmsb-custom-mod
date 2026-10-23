#include "script_component.hpp"
/*
 * Author: JMSB
 * Makes an aircraft this addon's to fly: a crew in a group of the players'
 * side, the owner link, ALiVE told to leave it alone, and - for one built
 * from a class - the loss counted when it goes down. A synced aircraft got
 * its Killed handler when the module was read (FUNC(register)).
 *
 * THE AI DOES NOT DECIDE WHERE IT GOES. Driver locked, no fleeing, and a
 * behaviour set by the caller: CARELESS for everything that is only flying
 * somewhere (an aircraft that breaks off to dodge small arms never makes the
 * drop), something sharper for the tasks that are about shooting.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 *
 * Return Value:
 * The crew's group, grpNull when no crew could be made <GROUP>
 *
 * Example:
 * [_logic, _veh] call jmfsb_support_air_fnc_prepareAircraft
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]]];

if (isNull _logic || {!alive _veh}) exitWith {grpNull};

// A PLAYER AT THE CONTROLS IS NOT CREW. His aircraft is local to his client,
// so nothing the server orders would take, and his group's waypoints and
// behaviour are not this addon's to rewrite.
if (!isNull driver _veh && {(units group driver _veh) findIf {isPlayer _x} > -1}) exitWith {
    WARNING_1("'%1' is flown by a player - not tasked",typeOf _veh);
    grpNull
};

if (isNull driver _veh) then {
    private _grp = createGroup [_logic getVariable [QGVAR(side), west], true];
    _grp createVehicleCrew _veh;
    // A UAV that comes out crewless flies nowhere - the CAS drones' fix.
    if (isNull driver _veh) then {createVehicleCrew _veh};
};

private _grp = group driver _veh;
if (isNull _grp) exitWith {
    WARNING_1("'%1' could not be crewed",typeOf _veh);
    grpNull
};

_grp allowFleeing 0;
_veh lockDriver true;
_veh setVariable [QGVAR(owner), _logic, true];
[_veh] call EFUNC(common,lambsOff);

// ALiVE virtualises what it is handed by deleting the object behind it. Asked
// through the adapter, which is the only addon allowed to name ALiVE, and
// only when the adapter is loaded at all.
if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
    [_veh] call EFUNC(adapter_alive,profileIgnore);
};

if (isNull (_logic getVariable [QGVAR(synced), objNull]) && {!(_veh getVariable [QGVAR(killedEH), false])}) then {
    _veh setVariable [QGVAR(killedEH), true];
    // MPKilled, not Killed: Killed fires only where the aircraft is local,
    // and a player copilot taking the controls moves it to his client.
    _veh addMPEventHandler ["MPKilled", {
        params ["_veh", "_killer"];
        if (!isServer) exitWith {};
        [_veh getVariable [QGVAR(owner), objNull], _veh, _killer] call FUNC(lost);
    }];
};

_grp
