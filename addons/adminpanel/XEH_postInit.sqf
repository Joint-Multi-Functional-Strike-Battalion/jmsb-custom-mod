#include "script_component.hpp"

// THE PANEL'S OWN SETUP, VERBATIM FROM ITS fn_init - see the note at the top of
// the file. It is included rather than PREP'd because it is a block of variable
// assignments and not a function, and because keeping it recognisable as the
// mission's own init is what makes a fix upstream a re-copy.
#include "XEH_postInit_panel.inc.sqf"

// --- Admin surface ----------------------------------------------------------
// #jmfsb commands, which jmfsb_common already gates on the admin flag and
// swallows for everyone else. They exist because a console you cannot open is a
// console you cannot diagnose - and because the list this addon reads is the
// MISSION's, so "why am I not an admin" has an answer that is not "rebuild".

["admin.list", "who this mission lets into TAC//ADMIN", {
    private _ids = missionNamespace getVariable ["admp_authorisedIDs", []];
    if (_ids isEqualTo []) exitWith {"empty - admin is the database list (<unit>.admins) plus anything GRANT ADMIN handed out this mission"};
    format ["%1 uid(s): %2", count _ids, _ids joinString ", "]
}] call EFUNC(common,addDebugCommand);

["admin.reload", "re-read the mod's admin list", {
    private _ids = [] call FUNC(adminList);
    [ADMIN_SOURCE_MOD, _ids] call EFUNC(common,adminSource);
    format ["%1 uid(s) loaded", count _ids]
}] call EFUNC(common,addDebugCommand);

["admin.me", "whether this machine's player is an admin, and why", {
    params ["", "_caller"];

    private _uid = getPlayerUID _caller;
    private _listed = _uid in (localNamespace getVariable [QEGVAR(common,adminUids), createHashMap]);
    private _logged = (admin owner _caller) isEqualTo ADMIN_LOGGED;

    format [
        "uid %1 - server says admin: %2 (on the server's list: %3, #login: %4), flag: %5",
        _uid, [owner _caller, _uid] call EFUNC(common,adminCheck), _listed, _logged,
        _caller getVariable [QEGVAR(common,isAdmin), false]
    ]
}] call EFUNC(common,addDebugCommand);

// SECRETS (review R4): opens on the typer's machine; the server checks the
// logged-in admin on every read and write (jmfsb_common_fnc_secretSet/Status).
["secrets", "set the voice server's key and secret and the database string, kept on the server", {
    [{[QGVAR(secrets)] call FUNC(openDisplay)}] call CBA_fnc_execNextFrame;
    nil
}, true] call EFUNC(common,addDebugCommand);

// --- Who is an admin: the server's list (review S1/S2, 2026-10-31) ------------
// The server owns the list (jmfsb_common_fnc_adminSource, in localNamespace);
// this addon gives it the mod's list and the grants made here, and keeps the
// panel's own copy - admp_authorisedIDs, which only screens read - in step.
// The testing switch is read once, as the server loaded it: a client that
// publishes the variable later changes nothing.
if (isServer) then {
    [QEGVAR(common,adminsChanged), {
        admp_authorisedIDs = +(missionNamespace getVariable [QEGVAR(common,adminList), []]);
        {admp_authorisedIDs pushBackUnique _x} forEach ADMIN_SP_IDS;
        publicVariable "admp_authorisedIDs";
    }] call CBA_fnc_addEventHandler;

    [{
        localNamespace setVariable [QEGVAR(common,everyoneAdmin), GVAR(everyoneAdmin)];
        [ADMIN_SOURCE_MOD, [] call FUNC(adminList)] call EFUNC(common,adminSource);
    }] call EFUNC(common,runAfterSettingsInit);
};

// Time / weather and STABILIZE go to the server by remoteExec, which checks the
// sender is an admin (FUNC(envTime), FUNC(envWeather), FUNC(stabilizeLocal));
// they were CBA events, which any client could raise.
