#include "script_component.hpp"
ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

GVAR(curators) = [];

["ModuleCurator_F", "InitPost", {
    params ["_curator"];
    _curator addEventHandler ["CuratorObjectPlaced", {
        params ["", "_object"];
        // AN AUTONOMOUS VEHICLE KEEPS ITS AI. ALiVE profiles what Zeus places
        // (the mission's zeusSpawn option), deletes the original, and hands
        // back a bare hull - its profiler blacklists UAV-AI crew, so the seat
        // comes back empty. The adapter's profileIgnore is the opt-out.
        // isUav covers every autonomous turret and drone - it is what makes
        // them UAV-terminal connectable - never a crewed truck.
        //
        // GUARDED, unlike jmfsb's copy. curator does not list the adapter in
        // requiredAddons, so with ALiVE absent its PBO is skipped and these
        // would be calls on a nil variable.
        if (getNumber (configOf _object >> "isUav") > 0
            && {!isNil QEFUNC(adapter_alive,profileIgnore)}) then {
            [_object] call EFUNC(adapter_alive,profileIgnore);
            // The crew's GROUP, not the men one by one: the adapter's group
            // path marks the group, its members and their vehicle in one go,
            // which is what protects a modded drone whose crew class is not
            // on ALiVE's own UAV-crew blacklist.
            [group ((crew _object) param [0, objNull])] call EFUNC(adapter_alive,profileIgnore);
        };
        // By remoteExec, checked on the server (review S7).
        [[_object]] remoteExecCall [QFUNC(editableAdd), SERVER_OWNER];
    }];
    _curator addEventHandler ["CuratorGroupPlaced", {
        params ["", "_group"];
        [[_group]] remoteExecCall [QFUNC(editableAdd), SERVER_OWNER];
    }];
}] call CBA_fnc_addClassEventHandler;

if (isServer) then {
    ["ModuleCurator_F", "InitPost", {
        [allUnits + vehicles] call FUNC(editableAdd);
    }] call CBA_fnc_addClassEventHandler;

    // ZEUS IS ASKED FOR BY remoteExec (FUNC(zeusAssign), FUNC(zeusUnassign),
    // FUNC(zeusActivateAddons)), not by CBA events, which carry no sender
    // (review S7). The server's own list of who may have Zeus lives in
    // localNamespace, which is not networked.
    localNamespace setVariable [QGVAR(zeusAllowed), []];

    // A curator stays one after respawn: the new body takes the old one's
    // place on the server's list.
    addMissionEventHandler ["EntityRespawned", {
        params ["_new", "_old"];
        private _allowed = localNamespace getVariable [QGVAR(zeusAllowed), []];
        if (_old in _allowed) then {
            _allowed pushBackUnique _new;
            localNamespace setVariable [QGVAR(zeusAllowed), _allowed select {!isNull _x}];
        };
    }];
};

ADDON = true;
