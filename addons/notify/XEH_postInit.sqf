#include "script_component.hpp"

if (!hasInterface) exitWith {};

GVAR(slots) = [];      // [slotIndex, expireTime] for every slot in use
GVAR(queue) = [];      // [title, text, colour] waiting for a free slot
GVAR(pfh) = -1;

// No jmfsb_notify_post CBA event any more (review R1): any client could raise
// it to put any text on every screen. Posts to other players go through
// FUNC(broadcast) on the server, which remoteExecs FUNC(notify).
