#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminAddOperator

Description:
    Puts somebody on the roster who has never joined the server.

    WHY THIS EXISTS. A record is created the first time a player connects
    (FUNC(record), from the connect handler). That is right for a unit that
    recruits from the people already playing, and wrong for one that enlists
    somebody on Discord on Tuesday and wants them on the roster before
    Saturday's operation. Until now the only way in was the CSV import, which
    means editing a file in the mission and a restart.

    IT IS FUNC(record) THAT CREATES IT, NOT THIS. FUNC(record) is documented as
    the only place a record is made, so the shape is defined once. This
    function checks the caller and the id, then asks for the record - the same
    call the connect handler makes, so a player added here and a player who
    walked in are the same kind of thing afterwards.

    NOTHING IS GRANTED. The record arrives empty but for an operator id and
    today's enlistment date, exactly as a first connect would leave it. Rank,
    role and skills are an admin's decision, made on the player page.

    KEYED ON THE STEAM ID, which is what getPlayerUID returns and what the
    whole store is keyed on. A typo here creates a record nobody will ever
    match, so the id is checked for digits and its length is reported back
    rather than silently accepted.

Parameters:
    0: Caller <OBJECT>
    1: Steam id <STRING> - digits, 17 of them for a real account
    2: Name <STRING> (optional, default "")

Returns:
    Whether a record was created <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_uid", "", [""]], ["_name", "", [""]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {false};

private _red = [0.831, 0.267, 0.267, 1];
private _green = [0.4, 0.702, 0.4, 1];
private _fnc_tell = {
    params ["_msg", "_colour"];
    ["TAC//PAC", _msg, _colour] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

_uid = _uid regexReplace ["\s", ""];
_name = [_name] call CBA_fnc_trim;

if (_uid isEqualTo "") exitWith {
    ["A Steam id is needed - it is the number on their Steam profile.", _red] call _fnc_tell;
    false
};

if ((toArray _uid) findIf {!(_x >= 48 && _x <= 57)} >= 0) exitWith {
    [format ["'%1' is not a Steam id - digits only.", _uid], _red] call _fnc_tell;
    false
};

private _existing = GVAR(players) getOrDefault [_uid, createHashMap];
if (count _existing > 0) exitWith {
    private _have = _existing getOrDefault ["name", _uid];
    [format ["%1 is already on the roster (%2).", _uid, _have], _red] call _fnc_tell;
    false
};

// A real Steam id is 17 digits. A shorter one is accepted - test servers and
// hand-made ids exist - but said out loud, because a mistyped id is a record
// that will never match the person it was meant for.
private _odd = count _uid != 17;

private _rec = [_uid, _name] call FUNC(record);
if (count _rec isEqualTo 0) exitWith {
    ["The record could not be created.", _red] call _fnc_tell;
    false
};

private _op = _rec getOrDefault ["operatorId", ""];

[getPlayerUID _caller, name _caller, "operator", _uid, format ["added %1 (%2) to the roster as %3", _name, _uid, _op]] call FUNC(logAction);

[] call FUNC(storeSave);
[] call FUNC(publish);

[format [
    "%1 added as %2.%3 Set their rank and role on the player page.",
    [_name, _uid] select (_name isEqualTo ""),
    _op,
    if (_odd) then {format [" NOTE: %1 digits, not the usual 17 - check the id.", count _uid]} else {""}
], _green] call _fnc_tell;

INFO_3("admin %1 added %2 to the roster as %3",name _caller,_uid,_op);

true
