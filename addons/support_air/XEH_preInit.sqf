#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// THE LEDGER OF PLACED AIR MODULES, in placement order; the index IS the asset
// id ("air:<n>"). The server fills it and publishes it, because TAC//SUPPORT
// is drawn on the client and resolves ids there. Never compacted: a module
// deleted mid-mission leaves a null rather than moving every id after it
// onto a different aircraft. A JIP client may already hold the broadcast
// copy by now, so it is only created when absent.
if (isNil QGVAR(entities)) then {
    GVAR(entities) = [];
};

ADDON = true;
