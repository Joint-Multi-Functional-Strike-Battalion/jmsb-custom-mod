#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// THE RUNS, server: one hashmap each (FUNC(srvThread)), one per squad.
GVAR(runs) = [];

// THE PLACED JUMP AIRCRAFT MODULES (user, 2026-11-02), in placement order; the
// index IS the asset id ("jump:<n>"). The server fills it and publishes it:
// the TO picker is drawn on the client and resolves ids there. Never
// compacted - a module deleted mid-mission leaves a null. A JIP client may
// already hold the broadcast copy, so it is only created when absent.
if (isNil QGVAR(entities)) then {
    GVAR(entities) = [];
};

// THE FREEFALL READOUT, offered to the phone's status row; FUNC(altWatch)
// puts it first for a jump and takes it out on the ground.
if (!isNil QEGVAR(devices,overlayProviders)) then {
    EGVAR(devices,overlayProviders) set [ALT_ICON, FUNC(altCell)];
};

ADDON = true;
