#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_tabletSelectDevice

Description:
    Picks the device on a card. Refuses while a hack is running - swapping target
    mid-intrusion would silently throw away the progress you have.

Parameters:
    _slot : NUMBER - card index.

Author:
    JMSB
---------------------------------------------------------------------------- */
params ["_slot"];

if (_slot < 0) exitWith {};
if (GVAR(session) get "running") exitWith {};

private _devices = GVAR(devices);
if (_slot >= count _devices) exitWith {};

(_devices select _slot) params ["_obj", "_kind", "", "", "_range"];

GVAR(session) set ["device", _obj];
GVAR(session) set ["kind", _kind];
// A new target starts on the kind's own action; SPOOF is picked per target.
GVAR(session) set ["action", HACK_ACTION_DEFAULT];
GVAR(session) set ["range", _range];
GVAR(session) set ["progress", _obj getVariable [QGVAR(progress), 0]];

