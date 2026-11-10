#include "script_component.hpp"

// ON THE SUPPORT PAGE, AS A PROVIDER OF THE SUPPORT CORE. The core merges every
// registered provider's rows and routes an order back by the id's prefix -
// "cas" is ours, and the ids FUNC(entityRow) hands out carry it, so neither
// the page nor any other provider ever holds this addon's name.
//
// Registered on EVERY machine, not only the server: the page is drawn on the
// client and reads its rows locally.
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["sitrep", FUNC(sitrep)],
    ["available", FUNC(assetAvailable)],
    ["preview", FUNC(preview)],
    ["overlay", FUNC(overlay)],
    ["reach", FUNC(reach)],
    // The asset's thread (2026-11-01): the core calls these on the server for
    // a card filed to a drone's box and for the issuer's follow-ups.
    ["side", FUNC(side)],
    ["thread", FUNC(srvThread)],
    ["reply", FUNC(threadReply)],
    // STATUS answered by the core (2026-11-09): the drone and its run.
    ["status", FUNC(status)],
    // The root cards it takes inside a thread already open (2026-11-02).
    ["threadCards", THREAD_CARDS],
    ["types", SUPPORT_TYPES]
]] call EFUNC(support,registerProvider);

// THE SERVER FLIES THE RUNS. An order or a recall accepted on a client comes
// by remoteExec to FUNC(request) / FUNC(abort), which check the real sender
// (review S6) - no CBA event: those carry no sender.

// WHAT THE MAN ON THE RADIO HEARS. The run is flown on the server and every
// word of it is said on the side's machines - it is called inbound
// (FUNC(inbound)), and its terminal guidance is read back (FUNC(release)) so
// the JTAC knows whether his smoke was seen.
//
// THE HANDOVER. A loitering drone is an ISR asset, not a strike, and the thing
// that makes it one is a man in the gunner's seat: the aircraft holds its own
// orbit and the drone controller gets the optics, the sensors and whatever the
// airframe is hung with (FUNC(onStation)). The man who asked for it gets it,
// and only if he is ISR; everyone else on the side is told it is up there.
// The link and the seat are the devices' own (jmfsb_devices_fnc_uavControl):
// no UAV terminal (user, 2026-10-20: out of the arsenal).
//
// THE SEAT IS GIVEN BACK BEFORE THE AIRFRAME GOES (FUNC(offStation)), when the
// run ends and again before the airframe is deleted off the map edge.
//
// All four go from the server by remoteExec and are taken only from the server
// (review S7). They were CBA events: any client could put a false "inbound" or
// "in hot" on a side's screens, name any drone and himself as the caller, or
// drop another player's drone link.

// WHAT HAPPENS TO A DRONE IS SAID IN ITS THREAD (user, 2026-11-05: "needs
// messaging to notify of events like that"): the drone's own hit watch
// (FUNC(spawnDrone)) raises the support core's aircraft event; its owner
// module's thread gets the line as a MESSAGE from the asset.
if (isServer) then {
    [QEGVAR(support,aircraftEvent), {
        params [["_veh", objNull, [objNull]], ["_line", "", [""]], ["_flash", false, [false]]];
        private _logic = _veh getVariable [QGVAR(owner), objNull];
        if (isNull _logic || _line isEqualTo "") exitWith {};
        private _threadId = _logic getVariable [QGVAR(thread), ""];
        if (_threadId isEqualTo "") exitWith {};
        [format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _threadId, _line, _flash, _logic getVariable [QGVAR(callsign), "CAS"]] call EFUNC(support,threadEvent);
    }] call CBA_fnc_addEventHandler;
};
