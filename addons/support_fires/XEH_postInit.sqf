#include "script_component.hpp"

// ON THE SUPPORT PAGE, AS A PROVIDER OF THE SUPPORT CORE. Registered on EVERY
// machine: the page is drawn on the client and reads its rows locally.
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["tasks", FUNC(tasks)],
    ["sitrep", FUNC(sitrep)],
    ["available", FUNC(assetAvailable)],
    ["preview", FUNC(preview)],
    ["overlay", FUNC(overlay)],
    ["types", call FUNC(typeList)]
]] call EFUNC(support,registerProvider);

// THE SERVER FIRES. An order accepted on a client, and a recall, reach it by
// remoteExec to FUNC(request) and FUNC(abort), never by a CBA event: the
// server has to know who sent them (review S6).

// WHAT THE OBSERVER HEARS and THE TARGET ON THE MAP come from the server by
// remoteExec (FUNC(sayLocal), FUNC(markLocal), FUNC(unmarkLocal)), taken only
// from the server (review S7) - as CBA events any client could raise them.
