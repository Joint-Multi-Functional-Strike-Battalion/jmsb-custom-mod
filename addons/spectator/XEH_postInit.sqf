#include "script_component.hpp"

if (hasInterface) then {
    // No start / stop / reloadLocal CBA events (review R1): any client could
    // raise them to force every player in or out of spectator. This machine
    // calls the functions itself; the server sends them by remoteExec.

    // State change event handlers to detect dying, respawning  and unconscious state change
    player addEventHandler ["Killed", {
        if (!GVAR(enabled)) exitWith {};
        WARNING("Player killed!");

        if (SPECTATOR_KILLED_DELAY > (missionNamespace getVariable [QEGVAR(respawn,time), 1e10])) exitWith {};

        [{
            [] call FUNC(start);
        }, [], SPECTATOR_KILLED_DELAY] call CBA_fnc_waitAndExecute;
    }];

    player addEventHandler ["Respawn", {
        if (!GVAR(enabled)) exitWith {};
        WARNING("Player respawned!");
        [] call FUNC(stop);
    }];

    if (EGVAR(common,aceMedical)) then {
        ["ace_unconscious", {
            params ["_unit", "_active"];
            if (!GVAR(enabled) || {_unit isNotEqualTo player}) exitWith {};
            if (_active) then {
                [{!([player] call FUNC(canSpectate))}, {
                    // Do nothing as player can no longer be spectator, probably he's not unconscious anymore
                    LOG("Unconscious canSpectate 'false'");
                }, [], GVAR(unconsciousDelay), {
                    WARNING("Player unconscious!");
                    [] call FUNC(start);
                }] call CBA_fnc_waitUntilAndExecute;

                GVAR(unconsciousKilledEH) = player addEventHandler ["Killed", {
                    LOG("Unconscious killed EH");
                    player removeEventHandler ["Killed", _thisEventHandler];
                    [] call FUNC(reloadLocal);
                }];
            } else {
                WARNING("Player no longer unconscious!");

                player removeEventHandler ["Killed", GVAR(unconsciousKilledEH)];

                // Wait for display init to prevent race condition (BI uses spawn to show the display :| )
                [{
                    !isNull (uiNamespace getVariable "RscEGSpectator_display");
                }, {
                    [] call FUNC(stop);
                }, [], 3] call CBA_fnc_waitUntilAndExecute;
            };
        }] call CBA_fnc_addEventHandler;
    } else {
        // TODO: Handle vanilla unconscious state change
    };
};
