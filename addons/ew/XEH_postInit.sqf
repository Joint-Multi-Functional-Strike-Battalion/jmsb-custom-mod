#include "script_component.hpp"

// --- Server: EW on RF's two hooks, the EA front door, the DF tick ----------
if (isServer) then {
    // What RF hears (every emitting node, every RF tick) and what EW adds to
    // it (its jammers' noise in every link budget).
    [{_this call FUNC(listener)}] call EFUNC(rf,addListener);
    [{_this call FUNC(noise)}] call EFUNC(rf,addNoiseSource);

    // FUNC(jamSet) / FUNC(decoyPlace) on a client come by remoteExec and
    // check the sender (review R1: no CBA handler). The EP tab asks for a
    // fresh slice after an EMCON change.
    // The hacking addon's SPOOF is called on the server by its
    // srvHackComplete, after it has checked the hack - no CBA event: any
    // client could have spoofed any group's GPS with one (review S7).
    [QGVAR(refresh), {
        params [["_unit", objNull, [objNull]]];
        if (!isNull _unit) then {[[_unit], false] call FUNC(publish)};
    }] call CBA_fnc_addEventHandler;

    addMissionEventHandler ["PlayerDisconnected", {
        params ["", "", "", "", "_owner"];
        GVAR(sent) deleteAt _owner;
    }];

    ["CBA_settingsInitialized", {
        [LINKFUNC(tick), GVAR(dfTick), []] call CBA_fnc_addPerFrameHandler;
        INFO_1("DF tick started, %1 s",GVAR(dfTick));
    }] call CBA_fnc_addEventHandler;
};

// --- Wherever an AI group is local: told of a DF fix (FUNC(aiReact)) --------
// by remoteExec to FUNC(aiAlert), which takes it only from the server (R1).

// --- Clients: the slice, threat warnings, the map layer, the app ------------
if (hasInterface) then {
    QGVAR(slice) addPublicVariableEventHandler {_this call FUNC(receiveSlice)};
    // Threat warnings come by remoteExec to FUNC(onThreat) (review R1).

    // The layer on both hosts' maps - see FUNC(mapHook).
    [LINKFUNC(mapHook), CLIENT_TICK_S, []] call CBA_fnc_addPerFrameHandler;

    // His GPS denial, on the edge, for the BFT dots others draw of him.
    [LINKFUNC(gpsWatch), CLIENT_TICK_S, []] call CBA_fnc_addPerFrameHandler;

    // TAC//EW, opened from the EW tile (FUNC(tile)).
    [APP_ID, FUNC(app)] call EFUNC(tacpad,registerApp);
};
