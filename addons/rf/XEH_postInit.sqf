#include "script_component.hpp"

// --- Server: the registry's front door and the tick -------------------------
if (isServer) then {
    // rf_register / rf_unregister / rf_setState / rf_netSet, raised by the
    // adapters on clients with CBA_fnc_serverEvent
    [QGVAR(register), {_this call FUNC(register)}] call CBA_fnc_addEventHandler;
    [QGVAR(unregister), {_this call FUNC(unregister)}] call CBA_fnc_addEventHandler;
    [QGVAR(setState), {_this call FUNC(setState)}] call CBA_fnc_addEventHandler;
    [QGVAR(netSet), {_this call FUNC(netSet)}] call CBA_fnc_addEventHandler;

    // DATA is RF's own net: it runs with no radio backend at all (rule 5).
    // Its per-side keys are made here, once.
    [NET_DATA, [["band", NET_DATA_BAND], ["source", QUOTE(ADDON)]]] call FUNC(netSet);

    // a client that leaves is forgotten; his nodes go when their holder does
    addMissionEventHandler ["PlayerDisconnected", {
        params ["", "", "", "", "_owner"];
        GVAR(sent) deleteAt _owner;
    }];

    // The tick rate is read once, when settings are in.
    ["CBA_settingsInitialized", {
        [] call FUNC(updateBands);
        [{_this call FUNC(tick)}, GVAR(tickPlayers)] call CBA_fnc_addPerFrameHandler;
        INFO_1("tick started, %1 s",GVAR(tickPlayers));
    }] call CBA_fnc_addEventHandler;
};

// --- Clients: read the slice, draw the debug overlay ------------------------
if (hasInterface) then {
    QGVAR(slice) addPublicVariableEventHandler {_this call FUNC(receiveSlice)};

    addMissionEventHandler ["Map", {
        params ["_opened"];
        if (!_opened) exitWith {};
        private _map = findDisplay MAP_DISPLAY displayCtrl MAP_CONTROL;
        if (isNull _map || {_map getVariable [QGVAR(debugDraw), false]}) exitWith {};
        _map setVariable [QGVAR(debugDraw), true];
        _map ctrlAddEventHandler ["Draw", {_this call FUNC(drawDebug)}];
    }];
};
