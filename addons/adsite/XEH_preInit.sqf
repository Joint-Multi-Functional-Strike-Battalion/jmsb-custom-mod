#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

#include "initSettings.inc.sqf"

// DECLARED HERE, NOT IN postInit: the Site module's function and the vehicles'
// InitPost run before postInit does, and both register into these.
//
// SERVER: hashValue of a vehicle -> unit record (U_* in script_component.hpp)
GVAR(units) = createHashMap;
// SERVER: alarm area key -> [unit keys, loudspeakers, last alarm time]
GVAR(areas) = createHashMap;
// SERVER: threats in the air (T_* in script_component.hpp), at most ADS_THREAT_CAP
GVAR(threats) = [];
// SERVER: the engagement PFH's handle; -1 while no threat is in the air
GVAR(pfh) = -1;
GVAR(pass) = 0;
GVAR(lastMs) = 0;
GVAR(maxMs) = 0;
GVAR(lastWarn) = -1e9;
GVAR(stats) = createHashMapFromArray [["intercepts", 0], ["misses", 0], ["leaks", 0], ["dropped", 0], ["threats", 0]];

// EVERY MACHINE: vehicle class -> [gun entry, missile entry] (FUNC(profile))
GVAR(classes) = createHashMap;
// EVERY MACHINE: ammo class -> [family, speed] (FUNC(family))
GVAR(families) = createHashMap;
// EVERY MACHINE: rounds this machine fired that the server may ask it to kill
GVAR(owned) = createHashMap;
GVAR(nextShot) = 0;
// CLIENTS: vehicle classes that already carry the ACE actions
GVAR(aceClasses) = createHashMap;

// Every vehicle placed - in Eden, by Zeus, by a script or by ALiVE - is asked
// ONCE, on creation, whether it is air defence (StaticWeapon is a LandVehicle).
// A class already known not to be costs one hashmap lookup. No vehicle is
// ever scanned for again.
{
    [_x, "InitPost", LINKFUNC(vehicleInit), true, [], true] call CBA_fnc_addClassEventHandler;
} forEach ["LandVehicle", "Ship"];

ADDON = true;
