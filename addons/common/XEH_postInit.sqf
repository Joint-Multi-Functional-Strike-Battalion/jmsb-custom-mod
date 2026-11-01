#include "script_component.hpp"

// --- BI's Civilian Presence FSM, without BI's Civilian Presence module -------
// THIRTY RPT ERRORS A SECOND, FOR THE WHOLE MISSION. The log filled with
//
//   Error in expression <time > _t>   Error Undefined variable in expression: _t
//
// preceded once by the line that causes it:
//
//   _threat = [_this,_threatsNew] call bis_fnc_cp_main;  _t = time + ...
//   Error Undefined variable in expression: bis_fnc_cp_main
//
// Those five bis_fnc_cp_* functions are NOT in CfgFunctions. BI's Civilian
// Presence MODULE registers them at runtime when it initialises
// (A3\Modules_F_Tacops\Ambient\CivilianPresence\init.sqf). But the danger FSM
// that calls them is baked into the UNIT CLASSES as fsmDanger, so any civilian
// carrying it runs the FSM whether that module is in the mission or not - and
// ALiVE's ambient civilian placement puts hundreds of them down. With the
// function missing the FSM's first state throws before it can set _t, so its
// transition condition `time > _t` then throws every frame, for every civilian,
// for the rest of the mission.
//
// So the functions are registered here if nothing else has registered them.
// This is BI's own call, on BI's own files, with BI's own names - not a
// reimplementation. main.sqf keeps all its state on the unit and needs nothing
// from the module, so the FSM behaves exactly as intended once it can find it.
//
// EVERY MACHINE, because a danger FSM runs wherever its unit is local.
if (isNil "bis_fnc_cp_main") then {
    [
        "\A3\Modules_F_Tacops\Ambient\CivilianPresence\Functions\",
        "bis_fnc_cp_",
        ["debug", "getQueueDelay", "main", "addThreat", "getSafespot"]
    ] call BIS_fnc_loadFunctions;
};

// THE ADMIN FLAG IS THE SERVER'S (review S1, 2026-10-31). Each client used to
// set QGVAR(isAdmin) on itself after #login, and server checks trusted it, so
// any client could make itself admin. Now the client only asks - at start,
// after #login and #logout, on a change of unit - and the server sets the flag
// from its own records (FUNC(adminClaim), FUNC(adminCheck)). The host is the
// server's own machine, so it is an admin without logging in, as before.

// The tick timings' minute (FUNC(perfAdd), FUNC(perfReport); review R9).
[{[] call FUNC(perfReport)}, PERF_REPORT_S] call CBA_fnc_addPerFrameHandler;

if (hasInterface) then {
    private _fnc_claim = {[] remoteExecCall [QFUNC(adminClaim), SERVER_OWNER]};
    [{!isNull player}, _fnc_claim] call CBA_fnc_waitUntilAndExecute;

    ["login", {
        [{IS_ADMIN}, {
            [] remoteExecCall [QFUNC(adminClaim), SERVER_OWNER];
        }, nil, ADMIN_LOGIN_WAIT] call CBA_fnc_waitUntilAndExecute;
    }, "all"] call CBA_fnc_registerChatCommand;

    ["logout", {
        [{!IS_ADMIN}, {
            [] remoteExecCall [QFUNC(adminClaim), SERVER_OWNER];
        }, nil, ADMIN_LOGIN_WAIT] call CBA_fnc_waitUntilAndExecute;
    }, "all"] call CBA_fnc_registerChatCommand;

    ["unit", _fnc_claim] call CBA_fnc_addPlayerEventHandler;
};

// Always-available commands. Everything else is registered by the addon that
// owns it, so this list stays the baseline the harness is proven with.
["state", "list placed jmfsb modules and their armed state", {
    private _out = [];
    {
        private _cls = typeOf _x;
        if (_cls select [0, 12] isEqualTo "jmfsb_module") then {
            _out pushBack format ["%1 @ %2", _cls, mapGridPosition _x];
        };
    } forEach (entities "Logic");
    if (_out isEqualTo []) then { "no jmfsb modules placed" } else { _out joinString " | " }
}] call FUNC(addDebugCommand);

["markers", "delete every intel marker on my machine", {
    private _n = 0;
    {
        if (_x select [0, 6] isEqualTo "jmfsb_") then { deleteMarkerLocal _x; _n = _n + 1 };
    } forEach allMapMarkers;
    format ["%1 markers cleared locally", _n]
}, true] call FUNC(addDebugCommand);

// The alert bus: every jmfsb system that does something TO the players posts
// here, and the devices draw from one place. See FUNC(alert). The server
// reaches FUNC(onAlert) by remoteExec, not the "alert" CBA event any client
// could raise (review S7).
GVAR(alerts) = [];

// --- the threat board -------------------------------------------------------
// What each side KNOWS: side -> [[id, side, target, pos, error, seen, first,
// sources, object], ...]. Server only - one authoritative picture, read
// through FUNC(contactGet) and never touched directly.
GVAR(playerSide) = west;

if (isServer) then {
    GVAR(boards) = createHashMap;
    GVAR(contactSeq) = 0;

    // Sensors post here; the board files it. One raise feeds every
    // commanders - a sensor never needs to know who is listening.
    [QGVAR(contact), {
        params ["_detectorSide", "_victimSide", "_pos", "_error", "_source"];
        [_detectorSide, _victimSide, _pos, _error, _source] call FUNC(contactReport);
    }] call CBA_fnc_addEventHandler;
};
