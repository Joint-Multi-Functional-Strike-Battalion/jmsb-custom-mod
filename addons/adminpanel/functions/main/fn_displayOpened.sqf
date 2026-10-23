/*
    Author: TheTimidShade

    Description:
        Is executed when admin panel interface is opened. Starts update process for controls.

    Parameters:
        NONE
        
    Returns:
        NOTHING
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

disableSerialization;

// if they open the panel through debug but aren't in the admin list exit
if (!(player call admp_fnc_isAdmin)) exitWith {(uiNamespace getVariable ['admp_displayVar', displayNull]) closeDisplay 2;};

// update player list first so refresh can use selected unit
[] call admp_fnc_updatePlayerList;

// start refresh process
[] spawn admp_fnc_refresh;

[] call admp_fnc_populateEndingList;
[] call admp_fnc_labelSkills;
[] call admp_fnc_updateRankCombo;

[] spawn admp_fnc_refreshPIPcam; // start updating PIP cam (requires higher update rate than other UI for smooth first person cam)
