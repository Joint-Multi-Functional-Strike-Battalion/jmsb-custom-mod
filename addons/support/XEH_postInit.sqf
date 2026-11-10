#include "script_component.hpp"

// THE LEDGER IS THE SERVER'S. A request is dispatched where it was made (the
// providers' own task code decides where the work runs), but a cooldown has
// to hold for every player on the side, so the client that got an accepted
// order books it on the server by remoteExec to FUNC(bookCooldown), which
// checks the sender and publishes the whole ledger. Not a CBA event: those
// do not tell the server who sent them (review S6).

// THE THREADS (2026-11-01). A thread filed to an asset's box,
// B:SUPPORT:<assetId>, is answered by the server as the asset - messaging
// runs this after it files a message and knows nothing about support.
if (isServer) then {
    [{_this call FUNC(srvFiled)}] call EFUNC(messaging,onFiled);
    // A card filed into an asset's thread (2026-11-02): its re-task or NEXT
    // LIFT is taken there; its ROGER, WILCO, ON TASK and CANTCO are its own.
    [{_this call FUNC(srvThreadCard)}] call EFUNC(messaging,onThreadCard);
};

// THE THREAD'S MAP PIN (2026-11-01, DESIGN_SUPPORT_MESSAGING 6.3, step 8). A
// support card pushed to this player is held for its pin as it arrives
// (messaging's onReceive - taken only from the server; not its CBA
// threadOpened event, which any client could raise with a made-up card), and
// the pins are worked out on a slow poll, never per frame (FUNC(pinTick)).
if (hasInterface) then {
    [{
        params ["_message", "_entry"];
        if (count _message isEqualTo 0) exitWith {};
        [_entry getOrDefault ["threadId", ""], _message, [_entry getOrDefault ["boxId", ""]]] call FUNC(pinRoot);
    }] call EFUNC(messaging,onReceive);
    [{[] call FUNC(pinTick)}, PIN_POLL] call CBA_fnc_addPerFrameHandler;
};
