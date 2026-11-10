#include "script_component.hpp"

// THE JUMP AIRCRAFT IS A SUPPORT ASSET (user, 2026-11-02: "also want to
// change the halo/haho/static app in to a message based one"). The leader
// files a JUMP REQUEST to its box in TAC//MSG - B:SUPPORT:jump:<n> for the
// aircraft of a JMSB - Jump Aircraft module (2026-11-02), B:SUPPORT:jump:<side>
// for a side with none; the support core hands the card to FUNC(srvThread)
// on the server and his
// replies to FUNC(srvReply). Registered on EVERY machine: the TO picker and
// the thread's pin read the row (FUNC(assets)) on the client, and the row is
// a squad leader's or an admin's alone.
//
// THE SERVER FLIES THE RUN, as it always did. EACH MAN IS BOARDED, LIT, PUT
// OUT AND TOLD WHERE HE IS LOCAL - a player on his own machine, an AI on his
// leader's or a headless client's: the server sends FUNC(board), FUNC(light)
// and FUNC(jump) there by remoteExec, and each takes it only from the server
// (review S7).
[JUMP_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["reach", FUNC(reach)],
    ["side", FUNC(side)],
    ["thread", FUNC(srvThread)],
    ["reply", FUNC(srvReply)],
    // STATUS answered by the core (2026-11-09).
    ["status", FUNC(status)],
    ["types", SUPPORT_TYPES]
]] call EFUNC(support,registerProvider);
