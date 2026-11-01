#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_svcSave

Description:
    Pushes the store to the pacdb service: the export JSON, in chunks the
    extension reassembles and PUTs. Fire and forget - the extension does
    the network on its own thread and reports put.end / put.error through
    the callback, which XEH_postInit logs. Server only.

Parameters:
    0: Document key <STRING> (optional, default settings.unitId - the store)
    1: JSON to push <STRING> (optional, default the store document)

Returns:
    Whether the extension took every chunk <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

#define PAC_SVC_CHUNK 7000

if (!isServer) exitWith {false};
if ((GVAR(settings) getOrDefault ["sync", "off"]) isNotEqualTo "service") exitWith {false};

params [["_key", "", [""]], ["_json", "", [""]]];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
if (_unit isEqualTo "") exitWith {false};
if (_key isEqualTo "") then {_key = _unit};
if (GVAR(svcMissing)) exitWith {false};       // no extension on this server - see FUNC(svcLoad)
if (_json isEqualTo "") then {_json = [false] call FUNC(storeJson)};
private _total = count _json;
private _n = ceil (_total / PAC_SVC_CHUNK);

private _fnc_call = {
    params ["_fn", "_args"];
    ("ghostd_pacdb" callExtension [_fn, _args]) params [["_text", "", [""]], "", ["_err", 0, [0]]];
    _err isEqualTo 0 && _text isEqualTo "queued"
};

// THE WHOLE PUT IN ONE STEP (isNil). The extension holds one put at a time, so
// a scheduled save suspended between chunks, then a second save from an event
// handler, would mix two documents. Unscheduled, nothing can run in between.
private _ok = false;
isNil {
    if !(["put.begin", [_key, str _n]] call _fnc_call) exitWith {
        WARNING("pacdb extension refused put.begin - store not pushed to the service");
    };
    _ok = true;
    for "_i" from 0 to (_n - 1) do {
        if !(["put.chunk", [str _i, _json select [_i * PAC_SVC_CHUNK, PAC_SVC_CHUNK]]] call _fnc_call) then {_ok = false};
    };
    if !(["put.end", []] call _fnc_call) then {_ok = false};
};

TRACE_3("pushed to service",_key,_n,_ok);
_ok
