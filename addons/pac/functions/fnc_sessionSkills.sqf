#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_sessionSkills

Description:
    Gives a player skills for THIS mission only - what the admin panel's
    Player Skills box applies.

    THE OP, NOT THE RECORD (user, 2026-10-07: "whats done in admin is for that
    op/game only ... for it to be permanent it needs to be in pac"). The list
    is kept on the server by Steam id in GVAR(session) and published, so a
    respawn or a rejoin keeps it until the mission ends. It is never written
    to the database: a permanent skill is set on the PAC record.

    The effects are FUNC(applySkills)'s strings plus "skill:<id>", which
    applies that skill whole - its effects, its arsenal list and its tag - as
    if the man held it. An empty list ends his session skills.

    SERVER ONLY, admins only - the caller is checked here, not trusted.

Parameters:
    0: Caller <OBJECT> - the admin
    1: Target <OBJECT> - the player
    2: Effects <ARRAY of STRING>

Returns:
    Whether it was applied <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_target", objNull, [objNull]], ["_effects", [], [[]]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {
    WARNING_1("sessionSkills refused: %1 is not an admin",name _caller);
    false
};
private _uid = getPlayerUID _target;
if (isNull _target || _uid isEqualTo "") exitWith {false};

_effects = _effects select {_x isEqualType "" && _x isNotEqualTo ""};
private _session = missionNamespace getVariable [QGVAR(session), createHashMap];
if (_effects isEqualTo []) then {
    _session deleteAt _uid;
} else {
    _session set [_uid, _effects];
};
GVAR(session) = _session;
publicVariable QGVAR(session);

[_target] remoteExecCall [QFUNC(applyTemp), _target];
[getPlayerUID _caller, name _caller, "session", _uid, _effects joinString ", "] call FUNC(logAction);
INFO_3("%1 gave %2 session skills: %3",name _caller,name _target,_effects);

true
