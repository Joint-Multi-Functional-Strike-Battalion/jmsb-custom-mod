#include "..\script_component.hpp"
/*
    File: fn_getActiveUAV.sqf
    Author: Dom
    Description: Attempts to return the UAV object if a player is actively controlling one

    JMSB: drones are flown without a UAV terminal (jmfsb_devices_fnc_uavControl,
    2026-10-20), so neither ACE's controlled-UAV record nor getConnectedUAV sees
    them - that seat is asked first. The terminal path below stays for a
    mission or loadout that still carries one.
*/

private _flying = if (isNil QEFUNC(devices,uavControl)) then {objNull} else {["flying"] call EFUNC(devices,uavControl)};
if (!isNull _flying) exitWith {_flying};

if (DT_viewDistance_isACEEnabled) exitWith {
    ACE_controlledUAV param [0,objNull];
};

private _activeUav = getConnectedUAV player;

if !(isNull _activeUav) then {
    private _positions = UAVControl _activeUav;
    private _connectedPosition = _positions find player;
    if (_connectedPosition isEqualTo -1) then {
        _activeUav = objNull;
    } else {
        if ((_positions select (_connectedPosition + 1)) isEqualTo "") then {
            _activeUav = objNull;
        };
    };
};

_activeUav;
