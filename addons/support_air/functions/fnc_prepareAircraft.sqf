#include "script_component.hpp"
/*
 * Author: YonV
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
 * TACTICAL, FROM HERE UNTIL IT IS GONE (user, 2026-11-01): lights only over
 * the airfield it started from - its module, or the stand a synced aircraft
 * stands on - and dark everywhere else, the crew kept from switching them on
 * (EFUNC(support,tactical)). A CARELESS crew lights up at night on its own;
 * the watch is what keeps it dark.
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
// THE PILOT LEADS (2026-11-05): createVehicleCrew makes a gunner the leader
// as often as not, and a group's orders are its leader's. A helicopter is
// ordered itself now (FUNC(heliOrder)); a plane's waypoints are the pilot's.
_grp selectLeader (driver _veh);
_veh lockDriver true;
_veh setVariable [QGVAR(owner), _logic, true];
[_veh] call EFUNC(common,lambsOff);
[_veh, _veh getVariable [QGVAR(airfield), _logic getVariable [QGVAR(home), getPosATL _logic]]] call EFUNC(support,tactical);

// ALiVE virtualises what it is handed by deleting the object behind it. Asked
// through the adapter, which is the only addon allowed to name ALiVE, and
// only when the adapter is loaded at all.
if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
    [_veh] call EFUNC(adapter_alive,profileIgnore);
};

// THE LAST THING THAT HIT IT (2026-11-01), for the RPT line a transport's
// write-off prints and the killer it counts the loss to (FUNC(flightFault)) -
// a write-off said "lost to ''" and nothing else. Hit fires where the
// aircraft is local, which is the server for every crew made here.
if !(_veh getVariable [QGVAR(hitEH), false]) then {
    _veh setVariable [QGVAR(hitEH), true];
    _veh addEventHandler ["Hit", {
        params ["_veh", "_source", "", "_instigator"];
        _veh setVariable [QGVAR(lastHit), [_source, _instigator, CBA_missionTime]];
        // TAKING FIRE, said in its threads once per HIT_SAID_S (user,
        // 2026-11-05). The aircraft is local here - the server for a crew
        // made here; a player at the stick is not this addon's to report.
        if (isServer && {CBA_missionTime - (_veh getVariable [QGVAR(hitSaidAt), -HIT_SAID_S]) >= HIT_SAID_S}) then {
            _veh setVariable [QGVAR(hitSaidAt), CBA_missionTime];
            [QEGVAR(support,aircraftEvent), [_veh, format [EVENT_TAKING_FIRE, mapGridPosition _veh], true]] call CBA_fnc_localEvent;
        };
    }];
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
