#include "script_component.hpp"

// THE JAM REGISTRY lives on every client - reference-counted burst sources
// with expiry times, the ACRE lever true while any is live (see
// fnc_jamRegister / fnc_jamTick). jmfsb_radio_mesh and jmfsb_jamming read
// GVAR(acreJam) in their signal functions, so a burst degrades the radio
// exactly the way a jamming zone does, and the two never fight over one
// boolean: a player standing in a zone stays jammed when the burst's timer
// runs out, because the zone is a different source.
if (hasInterface) then {
    GVAR(jamSources) = createHashMap;
    GVAR(acreJam) = 0;
    GVAR(jammed) = false;
    GVAR(lastEvent) = [];   // [what, bearing, when] - the HUD's APS tile reads it
    [LINKFUNC(jamTick), 0.5, []] call CBA_fnc_addPerFrameHandler;

    // THE MAP PANEL (user, 2026-08-29: "a live panel to control APS on the
    // map"). Registered with the tacpad shell as builder and refresher, under
    // the shell's own show-setting name; a soft dependency - postInit, so every
    // preInit has run, and nothing here if the shell is not loaded. The panel
    // exists only while the master switch is on AND the player is in a vehicle
    // (user, 2026-08-29: "completely hidden when you're not in a vehicle") -
    // the shell asks the condition on every map open, so it is there the next
    // time the map opens from a seat and gone the next time it opens on foot.
    if (!isNil "jmfsb_tacpad_fnc_register") then {
        ["aps", "APS", DEFAULT_APS, LINKFUNC(panelAps), LINKFUNC(panelAps), 2, true, {
            (missionNamespace getVariable [QGVAR(enabled), true]) && {!isNull objectParent player}
        }] call EFUNC(tacpad,register);
    };
};

if (!isServer) exitWith {};

GVAR(registered) = [];

// ARM ON OUR OWN. Deferred one frame so a JMSB - APS module placed in the
// mission gets first say: whichever runs first wins, the other no-ops, and the
// sweep starts exactly once. Before this, a mission with no module got nothing
// from the addon at all and the HUD tile read "NO APS" in every vehicle.
[{ [objNull] call FUNC(arm) }] call CBA_fnc_execNextFrame;
