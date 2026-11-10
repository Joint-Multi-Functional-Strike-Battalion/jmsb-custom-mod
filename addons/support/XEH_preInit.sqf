#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

#include "initSettings.inc.sqf"

// THE REGISTRY. kind -> the provider's declaration hashmap. Filled by every
// provider's own postInit on every machine, because TAC//SUPPORT is drawn on
// the client and reads its rows locally. See FUNC(registerProvider).
GVAR(providers) = createHashMap;

// Kinds whose rows have already been refused once, so a provider handing out
// malformed ids says so in the RPT once and not on every two-second poll.
GVAR(badRowSaid) = [];

// THE COOLDOWN LEDGER, asset id -> mission time it may be tasked again. The
// server owns it and broadcasts it (XEH_postInit); a JIP client may already
// hold the broadcast copy by now, so it is only created when absent.
if (isNil QGVAR(readyAt)) then {
    GVAR(readyAt) = createHashMap;
};

// THE CALL SIGNS ASSET MAILBOXES READ AS (2026-11-01), asset id -> call sign,
// learnt on this machine from the viewer's rows (FUNC(boxName),
// FUNC(mailboxes)). Only ever added to: an asset that has since gone still
// reads as the name its thread was filed under.
GVAR(boxNames) = createHashMap;
GVAR(boxNamesDue) = 0;

// THE SUPPORT THREADS' MAP PINS (2026-11-01, DESIGN_SUPPORT_MESSAGING 6.3),
// client: thread id -> [order, asset id] held for its pin (FUNC(pinRoot)),
// and thread id -> its markers' names -> the spec each was drawn from
// (FUNC(pinTick)).
GVAR(pinRoots) = createHashMap;
GVAR(pinDrawn) = createHashMap;

// THE SUPPORT CARDS THE MOD CARRIES (user, 2026-11-01): here, right after
// messaging's preInit registered the mission's deck and its own cards, so
// every machine has them in the same place. THE MOD'S OWN CARD ALWAYS WINS
// (user, 2026-11-02): a mission card of the same id is replaced, and the
// TAC//PAC deck, later, adds only the ids the mod does not have
// (EFUNC(messaging,registerBuiltins), pac templatesApply).
[[] call FUNC(builtinCards), QUOTE(COMPONENT)] call EFUNC(messaging,registerBuiltins);

ADDON = true;
