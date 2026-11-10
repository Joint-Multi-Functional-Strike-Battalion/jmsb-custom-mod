#include "script_component.hpp"

// The server waits for CBA_settingsInitialized: the system that carries the
// voice is the setting's choice (FUNC(selectSystem), whose handler was
// registered first, in XEH_preInit). A client waits for the SERVER'S choice
// (jmfsb_voice_systemReady, FUNC(followServer)). Under "none" (the server's
// system cannot run here) nothing is started: no nets, voice unavailable.

// --- Server: nets, the call front door, the tick --------------------------------
if (isServer) then {
    ["CBA_settingsInitialized", {
        if (!GVAR(active)) exitWith {};

        // The default plan's fixed nets (the PAC plan's own are pac's to make).
        {
            _x params ["_net", "_band"];
            [_net, [["name", _net], ["band", _band], ["source", NET_SOURCE]]] call EFUNC(rf,netSet);
        } forEach FIXED_NETS;

        // The call and RTO-net requests (srvCall, srvAdd, srvAnswer, srvLeave,
        // srvCallback, srvNetAdd, srvNetMembers, srvNetRemove) come by
        // remoteExec and check their sender (jmfsb_common_fnc_senderIs): no
        // CBA handler, a CBA event carries no sender.
        [FUNC(serverTick), SERVER_TICK_S] call CBA_fnc_addPerFrameHandler;
        INFO("voice server tick started");
    }] call CBA_fnc_addEventHandler;
};

// --- Clients: what the server publishes, the ticks, the frame --------------------
if (hasInterface) then {
    [QGVAR(systemReady), {
        if (!GVAR(active)) exitWith {};

        QGVAR(roster) addPublicVariableEventHandler {_this call FUNC(receiveRoster)};
        QGVAR(callPub) addPublicVariableEventHandler {_this call FUNC(receiveCalls)};
        // the server's answers come by remoteExec (FUNC(callFailed),
        // FUNC(netFailed), FUNC(note)); this machine's own notes are a plain
        // EFUNC(notify,notify) call - review R1: the old jmfsb_voice_note
        // CBA event let any client put text on every screen
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

        // a JIP value that arrived before the handlers above
        [QGVAR(roster), GVAR(roster)] call FUNC(receiveRoster);
        [QGVAR(callPub), GVAR(callPub)] call FUNC(receiveCalls);
        // a slot that starts in a pilot seat fires no GetInMan
        [] call FUNC(airSeat);
        [FUNC(clientTick), CLIENT_TICK_S] call CBA_fnc_addPerFrameHandler;
        [FUNC(frame), 0] call CBA_fnc_addPerFrameHandler;
        [FUNC(ringTick), RING_PERIOD_S] call CBA_fnc_addPerFrameHandler;
    }] call CBA_fnc_addEventHandler;
};
