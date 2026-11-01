#include "script_component.hpp"

// The server's point list lives in localNamespace, which is not networked; a
// copy is published in missionNamespace, so a JIP client gets it with the rest
// of the mission state. Server code reads only its own (review S7). A client
// that publishes over the copy gets the server's list back at once.
if (isServer) then {
    if (isNil {localNamespace getVariable QTP_LIST}) then {
        localNamespace setVariable [QTP_LIST, []];
    };
    [] call FUNC(listPublish);
    QTP_LIST addPublicVariableEventHandler {
        WARNING("teleport list overwritten by a client - publishing the server's own");
        [] call FUNC(listPublish);
    };
};

[] call FUNC(zenModules);

// NO Rev_tp_fnc_* ALIASES HERE, DELIBERATELY. They existed while the Roomba
// mission.sqm was binarised and its Eden init fields could not be edited; the
// sqm is text now and calls the jmfsb names directly.
//
// AND THEY WERE ACTIVELY DANGEROUS. Nine other missions in this collection
// still ship Reeveli's original scripts\Rev_teleport and define their own
// Rev_tp_fnc_* through their own CfgFunctions - a mod-side assignment at init
// would have overwritten a mission's own copy with jmfsb's.
