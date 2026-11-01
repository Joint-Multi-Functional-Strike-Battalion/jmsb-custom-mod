#include "script_component.hpp"

// ON TAC//SUPPORT AS A PROVIDER OF THE SUPPORT CORE, kind "air": CAS,
// transport, logistics drops and QRF insertion, one row per placed module.
// Registered on EVERY machine: the page is drawn on the client and reads its
// rows there. See addons/support/README.md for the contract.
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["sitrep", FUNC(sitrep)],
    ["available", FUNC(assetAvailable)],
    ["tasks", FUNC(tasks)],
    ["preview", FUNC(preview)],
    ["overlay", FUNC(overlay)],
    ["types", SUPPORT_TYPES]
]] call EFUNC(support,registerProvider);

// THE SERVER FLIES EVERYTHING. An order accepted on a client reaches it by
// remoteExec to FUNC(order), never by a CBA event: the server has to know
// who sent it (review S6).

// AI OUT OF A HELICOPTER AND A JUMP, WHERE THE MAN LIVES: the server sends
// FUNC(putOut) and FUNC(jump) to the unit by remoteExec, and they take only
// the server's word (review S7). They were CBA events any client could raise.
//
// WHAT THE SIDE HEARS goes the same way: FUNC(say) on the server sends
// FUNC(sayLocal) to the module's side by remoteExec, taken only from the
// server - the "say" CBA event is gone (review S7).
