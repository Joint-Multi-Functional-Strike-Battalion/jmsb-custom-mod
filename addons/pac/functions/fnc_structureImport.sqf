#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_structureImport

Description:
    STRUCTURE IN: a whole config, pasted by an admin, becomes THE structure
    - adopted, put into effect, kept in the profile so it outlives a
    restart, pushed to the service when one is up, and sent to every
    client. It is how the unit's database reaches a server that has no
    service (tools/pacdb/pac_sync.py `pull` assembles the documents into
    one JSON on the admin's clipboard) and how one server's STRUCTURE OUT
    goes straight into another.

        { "structure": { ranks, skills, awards, statuses, admins, roles,
                         nets, radio, orbat, templates, schemes, opords },
          "settings":  { ... } }     - settings optional; unitId, serverId
                                       and sync in it are ignored

    Server only, admin-checked, logged. A document that does not parse or
    lacks the six sections every structure has is refused with the reason.

Parameters:
    0: Caller <OBJECT>
    1: JSON text <STRING>

Returns:
    Whether the structure changed <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_text", "", [""]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {false};

private _red = [0.831, 0.267, 0.267, 1];
private _green = [0.4, 0.702, 0.4, 1];
private _fnc_tell = {
    params ["_msg", "_colour"];
    ["TAC//PAC", _msg, _colour] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

if (GVAR(readOnly)) exitWith {["Store is read-only: it was written by a newer PAC.", _red] call _fnc_tell; false};
if (_text isEqualTo "") exitWith {["Nothing to import - the clipboard is empty.", _red] call _fnc_tell; false};

([_text] call FUNC(fromJson)) params ["_doc", "_ok", "_where"];
if (!_ok) exitWith {[format ["Structure refused: not valid JSON (at character %1).", _where], _red] call _fnc_tell; false};
if !(_doc isEqualType createHashMap && {(_doc getOrDefault ["structure", createHashMap]) isEqualType createHashMap}) exitWith {
    ["Structure refused: the document has no ""structure"".", _red] call _fnc_tell;
    false
};
if !([_doc] call FUNC(structureAdopt)) exitWith {
    ["Structure refused: it must carry ranks, skills, awards, statuses, roles and opords - pac_sync.py pull and STRUCTURE OUT write all of them.", _red] call _fnc_tell;
    false
};

// EVERY SECTION IS NOW AN EDIT the profile keeps, and the settings with them.
{GVAR(structureEdited) set [_x, _y]} forEach GVAR(structure);
private _s = +GVAR(settings);
{_s deleteAt _x} forEach ["unitId", "serverId", "sync"];
GVAR(structureEdited) set ["_settings", _s];

// And the service's documents, when there is a service.
private _sent = 0;
if (GVAR(svcUp)) then {_sent = [] call FUNC(svcPushStructure)};

[false] call FUNC(structureApply);
GVAR(structureHash) = [] call FUNC(structureHash);

private _summary = format ["%1 rank(s), %2 skill(s), %3 role(s), %4 squad(s), %5 net(s), %6 OPORD(s), hash %7%8",
    count (GVAR(structure) getOrDefault ["ranks", createHashMap]),
    count (GVAR(structure) getOrDefault ["skills", createHashMap]),
    count (GVAR(structure) getOrDefault ["roles", createHashMap]),
    count ((GVAR(structure) getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []]),
    count (GVAR(structure) getOrDefault ["nets", createHashMap]),
    count (GVAR(structure) getOrDefault ["opords", createHashMap]),
    GVAR(structureHash),
    ["", format [", %1 document(s) to the service", _sent]] select (_sent > 0)];
[getPlayerUID _caller, name _caller, "structure", "", "imported a whole structure: " + _summary] call FUNC(logAction);

[true] call FUNC(storeSave);
[] call FUNC(publish);
GVAR(structureSvc) = GVAR(structure);
GVAR(settingsSvc) = GVAR(settings);
publicVariable QGVAR(structureSvc);
publicVariable QGVAR(settingsSvc);
["structure"] call FUNC(hostRefresh);     // the host does not hear its own publicVariable

INFO_2("%1 imported a structure: %2",name _caller,_summary);
[format ["Structure imported and kept: %1.", _summary], _green] call _fnc_tell;
true
