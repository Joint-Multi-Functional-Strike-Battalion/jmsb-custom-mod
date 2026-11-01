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
