#include "script_component.hpp"

// ON TAC//SUPPORT AS A PROVIDER OF THE SUPPORT CORE, kind "logi": airdrops
// and sling loads from a catalog, one row per placed module. Registered on
// EVERY machine: the page is drawn on the client and reads its rows there.
// See addons/support/README.md for the contract.
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["sitrep", FUNC(sitrep)],
    ["available", FUNC(assetAvailable)],
    ["tasks", FUNC(tasks)],
    ["preview", FUNC(preview)],
    ["overlay", FUNC(overlay)],
    ["reach", FUNC(reach)],
    // The asset's thread (step 7, 2026-11-01): the core calls these on the
    // server for a card filed to a module's box and for the issuer's answers.
    ["side", FUNC(side)],
    ["thread", FUNC(srvThread)],
    ["reply", FUNC(threadReply)],
    // 2026-11-09 (docs/DESIGN_MESSAGE_TEMPLATES.md): STATUS answered by the
    // core, another RESUPPLY REQUEST in the thread taken as the next run.
    ["status", FUNC(status)],
    ["threadCards", THREAD_CARDS],
    ["types", SUPPORT_TYPES]
]] call EFUNC(support,registerProvider);

// THE SERVER FLIES EVERYTHING. An order accepted on a client reaches it by
// remoteExecCall to FUNC(order), never by a CBA event: the server has to know
// who sent it (review S6). What the side hears comes back the same way,
// FUNC(say) to FUNC(sayLocal), taken only from the server (review S7).

// WHAT HAPPENS TO A DELIVERY AIRCRAFT IS SAID IN ITS THREAD (user, 2026-11-05:
// "needs messaging to notify of events like that"): the aircraft's own hit
// watch (FUNC(spawnAircraft)) raises the support core's aircraft event; its
// owner module's job thread gets the line as a MESSAGE from the asset.
if (isServer) then {
    [QEGVAR(support,aircraftEvent), {
        params [["_veh", objNull, [objNull]], ["_line", "", [""]], ["_flash", false, [false]]];
        private _logic = _veh getVariable [QGVAR(owner), objNull];
        if (isNull _logic || _line isEqualTo "") exitWith {};
        private _threadId = (_logic getVariable [QGVAR(threadJob), createHashMap]) getOrDefault ["thread", ""];
        if (_threadId isEqualTo "") exitWith {};
        [format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _threadId, _line, _flash, _logic getVariable [QGVAR(callsign), DEF_CALLSIGN]] call EFUNC(support,threadEvent);
    }] call CBA_fnc_addEventHandler;
};
