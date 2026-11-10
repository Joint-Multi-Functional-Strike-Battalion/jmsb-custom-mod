#include "script_component.hpp"
/*
    File: fnc_adminDoc.sqf
    Author: YonV
    Description: Write one document to the database as it stands - the
        Mongo docs page's SAVE. Server only; admins only. The text must be
        JSON; the store document is allowed, because the page asked twice.

    Parameters:
        0: The admin <OBJECT>
        1: Document key <STRING>
        2: JSON <STRING>

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_key", "", [""]], ["_json", "", [""]]];

if (!isServer || isNull _caller || _key isEqualTo "") exitWith {};
if !([_caller] call FUNC(isAdminCaller)) exitWith {WARNING_1("adminDoc refused: %1 is not an admin",name _caller)};
private _fnc_tell = {
    params ["_msg", "_bad"];
    ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
if ((_key select [0, count _unit]) isNotEqualTo _unit) exitWith {[format ["%1 is not one of this unit's documents.", _key], true] call _fnc_tell};

([_json] call FUNC(fromJson)) params ["_doc", "_ok", "_where"];
if (!_ok || !(_doc isEqualType createHashMap)) exitWith {[format ["That is not a JSON document (error at %1).", _where], true] call _fnc_tell};

if !([_key, _json] call FUNC(svcSave)) exitWith {["The database did not take it - is the service up?", true] call _fnc_tell};
if (!isNil QGVAR(docCache)) then {GVAR(docCache) set [_key, _doc]};
[getPlayerUID _caller, name _caller, "document", "", format ["wrote %1 (%2 chars)", _key, count _json]] call FUNC(logAction);
INFO_2("%1 wrote %2 to the database",name _caller,_key);
[format ["%1 written. The next boot reads it.", _key], false] call _fnc_tell;
