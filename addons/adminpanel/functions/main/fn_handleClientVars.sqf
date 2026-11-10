/*
    Author: TheTimidShade

    Description:
        Executed on all clients to report various states/stats to admin panel

    Parameters:
        NONE
        
    Returns:
        NOTHING
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

// THE FPS GOES OUT EVERY ADMIN_FPS_PERIOD, AND ONLY WHEN IT CHANGED (review P8,
// 2026-10-31). Every client published it four times a second to every machine
// for a readout one admin looks at now and then.
private _sentAt = -ADMIN_FPS_PERIOD;
while {true} do { // scary infinite loop of doom
    if (alive player && {diag_tickTime - _sentAt >= ADMIN_FPS_PERIOD}) then {
        private _fps = round diag_fps;
        if ((player getVariable ["admp_clientFPS", -1]) isNotEqualTo _fps) then {
            player setVariable ["admp_clientFPS", _fps, true]; // report fps
        };
        _sentAt = diag_tickTime;
    };
    if (!alive player && !isNull(getAssignedCuratorLogic player)) then {  // if the player is dead and has an assigned curator module, delete it
        deleteVehicle (getAssignedCuratorLogic player);
    };
    sleep 0.25;
};
