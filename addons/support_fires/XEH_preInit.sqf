#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// THE LEDGER OF PLACED MODULES, all four kinds in placement order. The index
// into it IS the asset id the support page sends back ("fires:<n>"), so an
// order is routed to the right asset without the page ever holding an object.
//
// Filled on the server by FUNC(register) and broadcast, because the page is
// drawn on the client and lists its rows from here. A JIP client may already
// hold the broadcast copy by now, so it is only created when absent. Never
// compacted: a deleted module leaves a null rather than shifting every id
// after it onto a different asset.
if (isNil QGVAR(entities)) then {
    GVAR(entities) = [];
};

// Shot ids handed to the air defence intercept (FUNC(threat)), server only.
GVAR(nextThreat) = 0;

ADDON = true;
