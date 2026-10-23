#include "script_component.hpp"

// TFAR or ACRE loaded (preInit): nothing of VON, the calls or the sounds is
// started. A client only mirrors that radio's nets and talkers for the UIs.
if (!GVAR(active)) exitWith {
    if (hasInterface) then {
        ["CBA_settingsInitialized", {
            [FUNC(externalTick), EXTERNAL_TICK_S] call CBA_fnc_addPerFrameHandler;
        }] call CBA_fnc_addEventHandler;
    };
};

// --- Server: nets, the call front door, the tick --------------------------------
if (isServer) then {
    // The default plan's fixed nets (the PAC plan's own are pac's to make).
    {
        _x params ["_net", "_band"];
        [_net, [["name", _net], ["band", _band], ["source", NET_SOURCE]]] call EFUNC(rf,netSet);
    } forEach FIXED_NETS;

    [QGVAR(srvCall), {_this call FUNC(srvCall)}] call CBA_fnc_addEventHandler;
    [QGVAR(srvAdd), {_this call FUNC(srvAdd)}] call CBA_fnc_addEventHandler;
    [QGVAR(srvAnswer), {_this call FUNC(srvAnswer)}] call CBA_fnc_addEventHandler;
    [QGVAR(srvLeave), {_this call FUNC(srvLeave)}] call CBA_fnc_addEventHandler;
    [QGVAR(srvCallback), {_this call FUNC(srvCallback)}] call CBA_fnc_addEventHandler;
    // the RTO's nets (FUNC(netAdd) / netMembers / netRemove on the clients)
    [QGVAR(srvNetAdd), {_this call FUNC(srvNetAdd)}] call CBA_fnc_addEventHandler;
    [QGVAR(srvNetMembers), {_this call FUNC(srvNetMembers)}] call CBA_fnc_addEventHandler;
    [QGVAR(srvNetRemove), {_this call FUNC(srvNetRemove)}] call CBA_fnc_addEventHandler;

    ["CBA_settingsInitialized", {
        [FUNC(serverTick), SERVER_TICK_S] call CBA_fnc_addPerFrameHandler;
        INFO("voice server tick started");
    }] call CBA_fnc_addEventHandler;
};

// --- Clients: what the server publishes, the ticks, the frame --------------------
if (hasInterface) then {
    QGVAR(roster) addPublicVariableEventHandler {_this call FUNC(receiveRoster)};
    QGVAR(callPub) addPublicVariableEventHandler {_this call FUNC(receiveCalls)};
    [QGVAR(callFailed), {_this call FUNC(callFailed)}] call CBA_fnc_addEventHandler;
    [QGVAR(netFailed), {_this call FUNC(netFailed)}] call CBA_fnc_addEventHandler;
    [QGVAR(note), {_this call EFUNC(notify,notify)}] call CBA_fnc_addEventHandler;
    // speaker-pushed keying (fnc_transmit -> fnc_keyed)
    [QGVAR(keyed), {_this call FUNC(keyed)}] call CBA_fnc_addEventHandler;
    // the cut-offs at once on his death and respawn (fnc_frame also polls)
    // ...and his A2G seat (fnc_airSeat): pilots join A2G by seat, so it is
    // read on these seat changes only, never per frame
    addMissionEventHandler ["EntityKilled", {
        params ["_unit"];
        if (_unit isEqualTo player) then {
            [] call FUNC(applyBlock);
            [] call FUNC(airSeat);
        };
    }];
    addMissionEventHandler ["EntityRespawned", {
        params ["_unit"];
        if (_unit isEqualTo player) then {
            [] call FUNC(applyBlock);
            [] call FUNC(airSeat);
            // back on squad comms after a respawn, off Global (FUNC(toTeam))
            [] call FUNC(toTeam);
        };
    }];
    {
        // GetInMan / GetOutMan [unit, role, ...]; SeatSwitchedMan [unit, the
        // man he swapped with, vehicle] - either of the two may be him. Read
        // the next frame, once the engine has him in (or out of) the seat.
        ["CAManBase", _x, {
            if (player in (_this select [0, 2])) then {[FUNC(airSeat), []] call CBA_fnc_execNextFrame};
        }] call CBA_fnc_addClassEventHandler;
    } forEach SEAT_EVENTS;

    ["CBA_settingsInitialized", {
        // a JIP value that arrived without its handler firing
        [QGVAR(roster), GVAR(roster)] call FUNC(receiveRoster);
        [QGVAR(callPub), GVAR(callPub)] call FUNC(receiveCalls);
        // a slot that starts in a pilot seat fires no GetInMan
        [] call FUNC(airSeat);
        [FUNC(clientTick), CLIENT_TICK_S] call CBA_fnc_addPerFrameHandler;
        [FUNC(frame), 0] call CBA_fnc_addPerFrameHandler;
        [FUNC(ringTick), RING_PERIOD_S] call CBA_fnc_addPerFrameHandler;
    }] call CBA_fnc_addEventHandler;
};
