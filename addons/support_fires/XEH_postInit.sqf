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
    ["reach", FUNC(reach)],
    // The composer's preview of a call for fire before SEND (2026-11-02),
    // on the composing player's machine.
    ["cardPreview", FUNC(cardPreview)],
    // The battery's thread (2026-11-01, step 6): the core calls these on the
    // server for a call for fire filed to a battery's box and for the
    // observer's follow-ups.
    ["side", FUNC(side)],
    ["thread", FUNC(srvThread)],
    ["reply", FUNC(threadReply)],
    // 2026-11-09 (docs/DESIGN_MESSAGE_TEMPLATES.md): STATUS answered by the
    // core, and a second call for fire in the thread taken as a new mission.
    ["status", FUNC(status)],
    ["threadCards", THREAD_CARDS],
    ["types", call FUNC(typeList)]
]] call EFUNC(support,registerProvider);

// THE SERVER FIRES. An order accepted on a client, and a recall, reach it by
// remoteExec to FUNC(request) and FUNC(abort), never by a CBA event: the
// server has to know who sent them (review S6).

// WHAT THE OBSERVER HEARS and THE TARGET ON THE MAP come from the server by
// remoteExec (FUNC(sayLocal), FUNC(markLocal), FUNC(unmarkLocal), and a
// recorded target's FUNC(targetLocal) and the SHOT / SPLASH FUNC(cueLocal) -
// 2026-11-02), taken only
// from the server (review S7) - as CBA events any client could raise them.
