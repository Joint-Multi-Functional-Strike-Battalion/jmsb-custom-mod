/*
    Author: TheTimidShade

    Description:
        Handles the CBA key press for the admin panel actions

    Parameters:
        0: ARRAY - Keypress info passed by key press event
        
    Returns:
        NOTHING
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

private _shift = _this#2;

if (player call admp_fnc_isAdmin) then {
    [_shift] call jmfsb_adminpanel_fnc_open;
} else {
    [true] call jmfsb_adminpanel_fnc_open;
};
