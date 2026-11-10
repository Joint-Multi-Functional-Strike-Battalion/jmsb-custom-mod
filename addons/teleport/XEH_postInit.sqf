#include "script_component.hpp"

// The server's point list lives in localNamespace, which is not networked; a
// copy is published in missionNamespace, so a JIP client gets it with the rest
// of the mission state. Server code reads only its own (review S7). A client
// that publishes over the copy gets the server's list back at once.
//
// ONLY A DIFFERENT LIST IS PUT BACK (2026-11-06, a dedicated server's RPT:
// this warning about twenty times a second, at the server's frame rate). The
// guard answered every arrival with a publish, its own copy included when it
// came back, so one arrival became an endless loop. A copy equal to the
// server's is its own echo: nothing to say, nothing to send.
//
// AND NEVER A PUBLISH PER ARRIVAL (user, 2026-11-06: "fix the log spamming
// for the tp"). A client that keeps sending a different list - one on an
// older build of the mod, say - would still meet a publish and an RPT line
// each time, and its next send would start it again. Arrivals are counted;
// one republish runs TP_REPUBLISH_S later for all of them, and the RPT gets
// one line per TP_WARN_S with the count.
if (isServer) then {
    if (isNil {localNamespace getVariable QTP_LIST}) then {
        localNamespace setVariable [QTP_LIST, []];
    };
    [] call FUNC(listPublish);
    GVAR(overwrites) = 0;
    GVAR(republishQueued) = false;
    GVAR(warnNext) = 0;
    QTP_LIST addPublicVariableEventHandler {
        params ["", ["_value", []]];
        if (_value isEqualTo (localNamespace getVariable [QTP_LIST, []])) exitWith {};
        GVAR(overwrites) = GVAR(overwrites) + 1;
        if (GVAR(republishQueued)) exitWith {};
        GVAR(republishQueued) = true;
        [{
            GVAR(republishQueued) = false;
            [] call FUNC(listPublish);
            if (CBA_missionTime < GVAR(warnNext)) exitWith {};
            WARNING_1("teleport list overwritten by a client %1 time(s) - publishing the server's own",GVAR(overwrites));
            GVAR(overwrites) = 0;
            GVAR(warnNext) = CBA_missionTime + TP_WARN_S;
        }, [], TP_REPUBLISH_S] call CBA_fnc_waitAndExecute;
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
