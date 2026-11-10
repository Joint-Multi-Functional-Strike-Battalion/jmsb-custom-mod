#include "script_component.hpp"

ADDON = false;

// PREP'd AGAIN AT preInit, AND THIS IS NOT REDUNDANT.
//
// CBA's preStart dispatch runs inside `with uiNamespace do` - the mission
// namespace does not exist that early - and CBA_fnc_compileFunction stores each
// function in uiNamespace, then copies it into missionNamespace. That copy is
// thrown away when a mission loads. An addon that PREPs ONLY at preStart
// therefore has NO functions once a mission is running.
//
// That was the whole reason every function in these eleven addons came back
// "Undefined variable" in game while the config, the packing and the handlers
// were all provably correct. 73 of jmfsb's other 79 addons already do this;
// these were the exception because they were written from scratch in one go.
#include "XEH_PREP.hpp"

// Call Endex: the Zeus asks the server, which sends every machine its share
// by remoteExec (FUNC(endexRequest), FUNC(endexLocal)) - no CBA event, which
// any client could raise (review S7).
GVAR(endexFiredAdded) = false;

// THE ENDEX FLAG IS THE SERVER'S (review S7). FUNC(endexRequest) keeps it in
// localNamespace and publishes a copy for the hold-fire handlers; a client
// that publishes over the copy gets the server's value back at once.
if (isServer) then {
    QEGVAR(Mission,Endex) addPublicVariableEventHandler {
        WARNING("ENDEX","flag overwritten by a client - publishing the server's own");
        missionNamespace setVariable [QEGVAR(Mission,Endex), localNamespace getVariable [QEGVAR(Mission,Endex), false], true];
    };
};

ADDON = true;
