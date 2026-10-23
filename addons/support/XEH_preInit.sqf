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

ADDON = true;
