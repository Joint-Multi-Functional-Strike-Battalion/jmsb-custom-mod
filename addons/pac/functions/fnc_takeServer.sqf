#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_takeServer

Description:
    On a client, takes the server's structure and settings over what this
    machine compiled from its own mission config - which, on a mission whose
    config lives in the database, is nothing but three settings. Called
    once in postInit (a JIP client already holds the variables) and again
    whenever the server publishes them.

    WHAT FOLLOWS A NEW STRUCTURE. The report deck it carries is registered
    (FUNC(templatesApply)); the radio plan goes into the jmfsbFR_radio_*
    globals and the presets are re-programmed if it changed
    (FUNC(radioApply)); and every cache built off the old structure is
    dropped - the tacpad's scheme list, messaging's platoon tags - so the
    next ask reads the new one. Roles and nets are read live through
    jmfsb_groups_fnc_role / jmfsb_messaging_fnc_netNames and need nothing.

    The three bootstrap settings - unitId, serverId, sync - stay this
    machine's own.

Parameters:
    None

Returns:
    Whether anything from the server was taken <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

private _took = false;

if (!isNil QGVAR(structureSvc)) then {
    GVAR(structure) = GVAR(structureSvc);
    [] call FUNC(adminsPublish);
    GVAR(structureHash) = [] call FUNC(structureHash);
    [] call FUNC(templatesApply);     // the deck, if the structure carries one
    [GVAR(structure) getOrDefault ["radio", createHashMap]] call FUNC(radioApply);
    missionNamespace setVariable ["jmfsb_tacpad_apps_missionSchemes", nil];   // schemes: rebuilt on next ask
    missionNamespace setVariable ["jmfsb_messaging_platoonTagCache", nil];    // platoon tags: rebuilt on next ask
    _took = true;
};

if (!isNil QGVAR(settingsSvc)) then {
    private _mine = GVAR(settings);
    GVAR(settings) = +GVAR(settingsSvc);
    {GVAR(settings) set [_x, _mine getOrDefault [_x, ""]]} forEach ["unitId", "serverId", "sync"];
    _took = true;
};

_took
