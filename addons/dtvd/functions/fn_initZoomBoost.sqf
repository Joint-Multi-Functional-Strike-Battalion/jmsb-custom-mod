/*
    File: fn_initZoomBoost.sqf
    Author: Dom
    Description: Starts or stops the zoom boost handler
*/
params [
    ["_enable",true,[false]]
];

// No player on a server or headless client (review L3).
if (!hasInterface) exitWith {};

if (_enable) then {
    DT_viewDistance_opticsSwitch = player addEventHandler ["OpticsSwitch",DT_fnc_opticsSwitch];
} else {
    if (isNil "DT_viewDistance_opticsSwitch") exitWith {};
    player removeEventHandler ["OpticsSwitch",DT_viewDistance_opticsSwitch];
    DT_viewDistance_opticsSwitch = nil;
};
