#include "script_component.hpp"

#include "initKeybinds.inc.sqf"

// A crewmate's point comes from the server by remoteExec (FUNC(srvPoint) ->
// FUNC(pointed), which hands it to DUI's radar) - no CBA event (review R1).
